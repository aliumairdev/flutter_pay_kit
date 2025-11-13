import Flutter
import UIKit
import PassKit

public class SwiftFlutterUniversalPaymentsPlugin: NSObject, FlutterPlugin {
    private var paymentController: PKPaymentAuthorizationController?
    private var pendingResult: FlutterResult?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "flutter_universal_payments/apple_pay",
            binaryMessenger: registrar.messenger()
        )
        let instance = SwiftFlutterUniversalPaymentsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isAvailable":
            handleIsAvailable(result: result)
        case "canMakePayments":
            handleCanMakePayments(call: call, result: result)
        case "requestPayment":
            handleRequestPayment(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Check if Apple Pay is available

    private func handleIsAvailable(result: @escaping FlutterResult) {
        let isAvailable = PKPaymentAuthorizationController.canMakePayments()
        result(isAvailable)
    }

    // MARK: - Check if Apple Pay can make payments with specific networks

    private func handleCanMakePayments(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any],
              let networksRaw = arguments["networks"] as? [String] else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Networks parameter is required",
                details: nil
            ))
            return
        }

        let networks = networksRaw.compactMap { networkString -> PKPaymentNetwork? in
            return mapToPaymentNetwork(networkString)
        }

        let canMakePayments = PKPaymentAuthorizationController.canMakePayments(
            usingNetworks: networks
        )
        result(canMakePayments)
    }

    // MARK: - Request Apple Pay payment

    private func handleRequestPayment(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any] else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Arguments are required",
                details: nil
            ))
            return
        }

        // Validate required parameters
        guard let merchantId = arguments["merchantId"] as? String,
              let currency = arguments["currency"] as? String,
              let countryCode = arguments["countryCode"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "merchantId, currency, and countryCode are required",
                details: nil
            ))
            return
        }

        // Get amount (can be Int or Double)
        let amount: NSDecimalNumber
        if let amountInt = arguments["amount"] as? Int {
            amount = NSDecimalNumber(value: amountInt)
        } else if let amountDouble = arguments["amount"] as? Double {
            amount = NSDecimalNumber(value: amountDouble)
        } else if let amountString = arguments["amount"] as? String {
            amount = NSDecimalNumber(string: amountString)
        } else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Invalid amount format",
                details: nil
            ))
            return
        }

        // Convert amount from cents/smallest unit to decimal
        let decimalAmount = amount.dividing(by: NSDecimalNumber(value: 100))

        // Optional parameters
        let label = arguments["label"] as? String ?? "Payment"
        let networksRaw = arguments["networks"] as? [String] ?? ["visa", "mastercard", "amex"]
        let merchantCapabilities = arguments["merchantCapabilities"] as? [String] ?? ["3DS"]
        let shippingType = arguments["shippingType"] as? String
        let billingRequired = arguments["billingRequired"] as? Bool ?? false
        let shippingRequired = arguments["shippingRequired"] as? Bool ?? false
        let shippingMethods = arguments["shippingMethods"] as? [[String: Any]]

        // Create payment networks
        let networks = networksRaw.compactMap { networkString -> PKPaymentNetwork? in
            return mapToPaymentNetwork(networkString)
        }

        // Create merchant capabilities
        var capabilities: PKMerchantCapability = []
        for capability in merchantCapabilities {
            switch capability.lowercased() {
            case "3ds":
                capabilities.insert(.capability3DS)
            case "emv":
                capabilities.insert(.capabilityEMV)
            case "credit":
                capabilities.insert(.capabilityCredit)
            case "debit":
                capabilities.insert(.capabilityDebit)
            default:
                break
            }
        }

        if capabilities.isEmpty {
            capabilities = .capability3DS
        }

        // Create payment request
        let request = PKPaymentRequest()
        request.merchantIdentifier = merchantId
        request.supportedNetworks = networks
        request.merchantCapabilities = capabilities
        request.countryCode = countryCode
        request.currencyCode = currency

        // Create payment summary items
        let paymentItem = PKPaymentSummaryItem(
            label: label,
            amount: decimalAmount
        )
        request.paymentSummaryItems = [paymentItem]

        // Configure shipping type
        if let shippingTypeString = shippingType {
            request.shippingType = mapToShippingType(shippingTypeString)
        }

        // Configure required fields
        var contactFields: Set<PKContactField> = []
        if billingRequired {
            contactFields.insert(.postalAddress)
            contactFields.insert(.name)
        }
        if shippingRequired {
            contactFields.insert(.postalAddress)
            contactFields.insert(.name)
            contactFields.insert(.phoneNumber)
            contactFields.insert(.emailAddress)
        }
        if !contactFields.isEmpty {
            request.requiredBillingContactFields = contactFields
            if shippingRequired {
                request.requiredShippingContactFields = contactFields
            }
        }

        // Configure shipping methods
        if let shippingMethodsData = shippingMethods {
            request.shippingMethods = shippingMethodsData.compactMap { methodData -> PKShippingMethod? in
                guard let identifier = methodData["identifier"] as? String,
                      let label = methodData["label"] as? String,
                      let amountString = methodData["amount"] as? String,
                      let amount = Decimal(string: amountString) else {
                    return nil
                }

                let method = PKShippingMethod(
                    label: label,
                    amount: NSDecimalNumber(decimal: amount)
                )
                method.identifier = identifier
                method.detail = methodData["detail"] as? String
                return method
            }
        }

        // Store the result callback
        pendingResult = result

        // Present Apple Pay sheet
        paymentController = PKPaymentAuthorizationController(paymentRequest: request)
        paymentController?.delegate = self

        paymentController?.present { presented in
            if !presented {
                self.pendingResult?(FlutterError(
                    code: "PRESENTATION_FAILED",
                    message: "Failed to present Apple Pay sheet",
                    details: nil
                ))
                self.pendingResult = nil
                self.paymentController = nil
            }
        }
    }

    // MARK: - Helper Methods

    private func mapToPaymentNetwork(_ network: String) -> PKPaymentNetwork? {
        switch network.lowercased() {
        case "visa":
            return .visa
        case "mastercard", "masterCard":
            return .masterCard
        case "amex", "americanexpress":
            return .amex
        case "discover":
            return .discover
        case "chinaUnionPay", "chinaunionpay":
            return .chinaUnionPay
        case "interac":
            return .interac
        case "privateLabel", "privatelabel":
            return .privateLabel
        case "jcb":
            return .JCB
        case "maestro":
            if #available(iOS 12.0, *) {
                return .maestro
            }
            return nil
        case "eftpos":
            if #available(iOS 12.0, *) {
                return .eftpos
            }
            return nil
        case "electron":
            if #available(iOS 12.0, *) {
                return .electron
            }
            return nil
        case "elo":
            if #available(iOS 12.1.1, *) {
                return .elo
            }
            return nil
        case "mada":
            if #available(iOS 12.1.1, *) {
                return .mada
            }
            return nil
        case "vpay":
            if #available(iOS 12.0, *) {
                return .vPay
            }
            return nil
        case "barcode":
            if #available(iOS 14.0, *) {
                return .barcode
            }
            return nil
        case "girocard":
            if #available(iOS 14.0, *) {
                return .girocard
            }
            return nil
        default:
            return nil
        }
    }

    private func mapToShippingType(_ type: String) -> PKShippingType {
        switch type.lowercased() {
        case "shipping":
            return .shipping
        case "delivery":
            return .delivery
        case "storepickup", "store_pickup":
            return .storePickup
        case "servicepickup", "service_pickup":
            return .servicePickup
        default:
            return .shipping
        }
    }

    private func serializePaymentToken(_ payment: PKPayment) -> [String: Any] {
        var result: [String: Any] = [:]

        // Payment token data
        let tokenData = payment.token.paymentData
        result["paymentData"] = tokenData.base64EncodedString()

        // Transaction identifier
        result["transactionIdentifier"] = payment.token.transactionIdentifier

        // Payment method
        if let paymentMethod = payment.token.paymentMethod as PKPaymentMethod? {
            var methodData: [String: Any] = [:]
            methodData["displayName"] = paymentMethod.displayName
            methodData["network"] = paymentMethod.network?.rawValue
            methodData["type"] = paymentMethod.type.rawValue
            result["paymentMethod"] = methodData
        }

        // Billing contact
        if let billingContact = payment.billingContact {
            result["billingContact"] = serializeContact(billingContact)
        }

        // Shipping contact
        if let shippingContact = payment.shippingContact {
            result["shippingContact"] = serializeContact(shippingContact)
        }

        // Shipping method
        if let shippingMethod = payment.shippingMethod {
            var shippingData: [String: Any] = [:]
            shippingData["identifier"] = shippingMethod.identifier
            shippingData["label"] = shippingMethod.label
            shippingData["amount"] = shippingMethod.amount.stringValue
            shippingData["detail"] = shippingMethod.detail
            result["shippingMethod"] = shippingData
        }

        return result
    }

    private func serializeContact(_ contact: PKContact) -> [String: Any] {
        var contactData: [String: Any] = [:]

        if let name = contact.name {
            var nameData: [String: Any] = [:]
            nameData["givenName"] = name.givenName
            nameData["familyName"] = name.familyName
            nameData["middleName"] = name.middleName
            nameData["namePrefix"] = name.namePrefix
            nameData["nameSuffix"] = name.nameSuffix
            nameData["nickname"] = name.nickname
            contactData["name"] = nameData
        }

        if let postalAddress = contact.postalAddress {
            var addressData: [String: Any] = [:]
            addressData["street"] = postalAddress.street
            addressData["city"] = postalAddress.city
            addressData["state"] = postalAddress.state
            addressData["postalCode"] = postalAddress.postalCode
            addressData["country"] = postalAddress.country
            addressData["isoCountryCode"] = postalAddress.isoCountryCode
            if #available(iOS 10.3, *) {
                addressData["subAdministrativeArea"] = postalAddress.subAdministrativeArea
                addressData["subLocality"] = postalAddress.subLocality
            }
            contactData["postalAddress"] = addressData
        }

        if let emailAddress = contact.emailAddress {
            contactData["emailAddress"] = emailAddress
        }

        if let phoneNumber = contact.phoneNumber {
            contactData["phoneNumber"] = phoneNumber.stringValue
        }

        return contactData
    }
}

// MARK: - PKPaymentAuthorizationControllerDelegate

extension SwiftFlutterUniversalPaymentsPlugin: PKPaymentAuthorizationControllerDelegate {
    public func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss {
            // Clean up
            self.paymentController = nil
        }
    }

    public func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        // Serialize payment data
        let paymentData = serializePaymentToken(payment)

        // Return success with payment token data
        pendingResult?(paymentData)
        pendingResult = nil

        // Complete the payment
        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
    }

    public func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didSelectShippingMethod shippingMethod: PKShippingMethod,
        handler completion: @escaping (PKPaymentRequestShippingMethodUpdate) -> Void
    ) {
        // In a real implementation, you would calculate new totals based on shipping method
        // For now, we'll just return the current summary items
        let update = PKPaymentRequestShippingMethodUpdate(paymentSummaryItems: controller.paymentRequest.paymentSummaryItems)
        completion(update)
    }

    public func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didSelectShippingContact contact: PKContact,
        handler completion: @escaping (PKPaymentRequestShippingContactUpdate) -> Void
    ) {
        // In a real implementation, you would validate the shipping address
        // and potentially update shipping methods and costs
        let update = PKPaymentRequestShippingContactUpdate(
            errors: nil,
            paymentSummaryItems: controller.paymentRequest.paymentSummaryItems,
            shippingMethods: controller.paymentRequest.shippingMethods ?? []
        )
        completion(update)
    }
}
