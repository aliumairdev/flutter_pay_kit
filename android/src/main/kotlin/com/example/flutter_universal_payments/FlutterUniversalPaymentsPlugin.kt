package com.example.flutter_universal_payments

import android.app.Activity
import android.content.Intent
import androidx.annotation.NonNull
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.tasks.Task
import com.google.android.gms.wallet.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import org.json.JSONArray
import org.json.JSONObject

/** FlutterUniversalPaymentsPlugin */
class FlutterUniversalPaymentsPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.ActivityResultListener {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var paymentsClient: PaymentsClient? = null
    private var pendingResult: Result? = null

    // Google Pay constants
    private val LOAD_PAYMENT_DATA_REQUEST_CODE = 991

    companion object {
        private const val CHANNEL_NAME = "flutter_universal_payments/google_pay"

        // Google Pay API version
        private const val API_VERSION = 2
        private const val API_VERSION_MINOR = 0
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "isAvailable" -> {
                isGooglePayAvailable(result)
            }
            "requestPayment" -> {
                val amount = call.argument<Int>("amount")
                val currency = call.argument<String>("currency")
                val merchantId = call.argument<String>("merchantId")
                val countryCode = call.argument<String>("countryCode") ?: "US"
                val environment = call.argument<String>("environment") ?: "TEST"

                if (amount == null || currency == null || merchantId == null) {
                    result.error("INVALID_ARGUMENTS", "Missing required arguments", null)
                    return
                }

                requestPayment(amount, currency, merchantId, countryCode, environment, result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
        initializePaymentsClient()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    private fun initializePaymentsClient() {
        val currentActivity = activity ?: return

        // Default to TEST environment for safety
        val walletOptions = Wallet.WalletOptions.Builder()
            .setEnvironment(WalletConstants.ENVIRONMENT_TEST)
            .build()

        paymentsClient = Wallet.getPaymentsClient(currentActivity, walletOptions)
    }

    private fun initializePaymentsClientWithEnvironment(environment: String) {
        val currentActivity = activity ?: return

        val walletEnvironment = when (environment.uppercase()) {
            "PRODUCTION" -> WalletConstants.ENVIRONMENT_PRODUCTION
            else -> WalletConstants.ENVIRONMENT_TEST
        }

        val walletOptions = Wallet.WalletOptions.Builder()
            .setEnvironment(walletEnvironment)
            .build()

        paymentsClient = Wallet.getPaymentsClient(currentActivity, walletOptions)
    }

    /**
     * Check if Google Pay is available on this device
     */
    private fun isGooglePayAvailable(result: Result) {
        val client = paymentsClient
        if (client == null) {
            result.success(false)
            return
        }

        val request = IsReadyToPayRequest.fromJson(getIsReadyToPayRequest().toString())
        val task: Task<Boolean> = client.isReadyToPay(request)

        task.addOnCompleteListener { completedTask ->
            try {
                val isReady = completedTask.getResult(ApiException::class.java)
                result.success(isReady == true)
            } catch (exception: ApiException) {
                result.success(false)
            }
        }
    }

    /**
     * Request a payment from Google Pay
     */
    private fun requestPayment(
        amount: Int,
        currency: String,
        merchantId: String,
        countryCode: String,
        environment: String,
        result: Result
    ) {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error("NO_ACTIVITY", "No activity available", null)
            return
        }

        // Reinitialize client with the correct environment
        initializePaymentsClientWithEnvironment(environment)

        val client = paymentsClient
        if (client == null) {
            result.error("INITIALIZATION_ERROR", "Failed to initialize payments client", null)
            return
        }

        pendingResult = result

        try {
            val paymentDataRequestJson = getPaymentDataRequest(
                amount,
                currency,
                merchantId,
                countryCode
            )
            val request = PaymentDataRequest.fromJson(paymentDataRequestJson.toString())

            AutoResolveHelper.resolveTask(
                client.loadPaymentData(request),
                currentActivity,
                LOAD_PAYMENT_DATA_REQUEST_CODE
            )
        } catch (e: Exception) {
            pendingResult = null
            result.error("REQUEST_FAILED", "Failed to request payment: ${e.message}", null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == LOAD_PAYMENT_DATA_REQUEST_CODE) {
            when (resultCode) {
                Activity.RESULT_OK -> {
                    data?.let {
                        val paymentData = PaymentData.getFromIntent(it)
                        handlePaymentSuccess(paymentData)
                    }
                }
                Activity.RESULT_CANCELED -> {
                    pendingResult?.error("PAYMENT_CANCELLED", "User cancelled the payment", null)
                    pendingResult = null
                }
                AutoResolveHelper.RESULT_ERROR -> {
                    val status = AutoResolveHelper.getStatusFromIntent(data)
                    pendingResult?.error(
                        "PAYMENT_ERROR",
                        "Payment error: ${status?.statusMessage}",
                        null
                    )
                    pendingResult = null
                }
            }
            return true
        }
        return false
    }

    private fun handlePaymentSuccess(paymentData: PaymentData?) {
        if (paymentData == null) {
            pendingResult?.error("NO_PAYMENT_DATA", "No payment data received", null)
            pendingResult = null
            return
        }

        try {
            val paymentInfo = paymentData.toJson()
            val paymentMethodData = JSONObject(paymentInfo)
                .getJSONObject("paymentMethodData")

            // Extract the payment token
            val token = paymentMethodData
                .getJSONObject("tokenizationData")
                .getString("token")

            // Return the payment token
            pendingResult?.success(token)
        } catch (e: Exception) {
            pendingResult?.error(
                "PARSING_ERROR",
                "Failed to parse payment data: ${e.message}",
                null
            )
        } finally {
            pendingResult = null
        }
    }

    /**
     * Build the JSON request for checking if Google Pay is available
     */
    private fun getIsReadyToPayRequest(): JSONObject {
        return JSONObject().apply {
            put("apiVersion", API_VERSION)
            put("apiVersionMinor", API_VERSION_MINOR)
            put("allowedPaymentMethods", JSONArray().put(getBaseCardPaymentMethod()))
        }
    }

    /**
     * Build the base card payment method configuration
     */
    private fun getBaseCardPaymentMethod(): JSONObject {
        return JSONObject().apply {
            put("type", "CARD")
            put("parameters", JSONObject().apply {
                put("allowedAuthMethods", JSONArray().apply {
                    put("PAN_ONLY")
                    put("CRYPTOGRAM_3DS")
                })
                put("allowedCardNetworks", JSONArray().apply {
                    put("AMEX")
                    put("DISCOVER")
                    put("INTERAC")
                    put("JCB")
                    put("MASTERCARD")
                    put("VISA")
                })
            })
        }
    }

    /**
     * Build the card payment method with tokenization
     */
    private fun getCardPaymentMethod(merchantId: String): JSONObject {
        val baseCardPaymentMethod = getBaseCardPaymentMethod()
        baseCardPaymentMethod.put("tokenizationSpecification", getTokenizationSpecification(merchantId))
        return baseCardPaymentMethod
    }

    /**
     * Build the tokenization specification
     */
    private fun getTokenizationSpecification(merchantId: String): JSONObject {
        return JSONObject().apply {
            put("type", "PAYMENT_GATEWAY")
            put("parameters", JSONObject().apply {
                put("gateway", "example")
                put("gatewayMerchantId", merchantId)
            })
        }
    }

    /**
     * Build the merchant info configuration
     */
    private fun getMerchantInfo(merchantId: String): JSONObject {
        return JSONObject().apply {
            put("merchantId", merchantId)
            put("merchantName", "Example Merchant")
        }
    }

    /**
     * Build the transaction info
     */
    private fun getTransactionInfo(amount: Int, currency: String, countryCode: String): JSONObject {
        return JSONObject().apply {
            put("totalPrice", (amount / 100.0).toString())
            put("totalPriceStatus", "FINAL")
            put("currencyCode", currency.uppercase())
            put("countryCode", countryCode.uppercase())
        }
    }

    /**
     * Build the complete payment data request
     */
    private fun getPaymentDataRequest(
        amount: Int,
        currency: String,
        merchantId: String,
        countryCode: String
    ): JSONObject {
        return JSONObject().apply {
            put("apiVersion", API_VERSION)
            put("apiVersionMinor", API_VERSION_MINOR)
            put("allowedPaymentMethods", JSONArray().put(getCardPaymentMethod(merchantId)))
            put("transactionInfo", getTransactionInfo(amount, currency, countryCode))
            put("merchantInfo", getMerchantInfo(merchantId))
        }
    }
}
