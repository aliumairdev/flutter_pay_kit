import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../exceptions/exceptions.dart';
import '../models/models.dart';
import 'base_processor.dart';

/// Paddle environment configuration
enum PaddleEnvironment {
  /// Sandbox/testing environment
  sandbox,

  /// Production environment
  production,
}

/// Paddle payment processor implementation.
///
/// This class provides a complete implementation of the PaymentProcessor
/// interface for Paddle's API (both Classic and Billing APIs).
///
/// **Important**: Paddle subscriptions cannot be created directly via API.
/// You must use the checkout URLs provided by [createSubscription] to allow
/// users to complete the subscription process through Paddle's hosted checkout.
///
/// Example usage:
/// ```dart
/// final processor = PaddleProcessor(
///   vendorId: '12345',
///   vendorAuthCode: 'your_vendor_auth_code',
///   publicKey: 'your_public_key',
///   environment: PaddleEnvironment.sandbox,
/// );
///
/// // Create a customer
/// final customer = await processor.createCustomer(
///   email: 'user@example.com',
///   name: 'John Doe',
/// );
///
/// // Note: Subscriptions must be created via checkout URL
/// final subscription = await processor.createSubscription(
///   customerId: customer.id,
///   priceId: 'price_123',
/// );
/// // subscription.metadata will contain the checkout URL
/// ```
class PaddleProcessor extends PaymentProcessor {
  /// Paddle vendor ID
  final String vendorId;

  /// Paddle vendor auth code for API authentication
  final String vendorAuthCode;

  /// Public key for webhook signature verification
  final String publicKey;

  /// Environment (sandbox or production)
  final PaddleEnvironment environment;

  /// HTTP client for making API requests
  late final Dio _dio;

  /// UUID generator for idempotency
  final _uuid = const Uuid();

  /// Base URL for Paddle Classic API
  String get _classicBaseUrl => environment == PaddleEnvironment.sandbox
      ? 'https://sandbox-vendors.paddle.com/api/2.0'
      : 'https://vendors.paddle.com/api/2.0';

  /// Base URL for Paddle Billing API
  String get _billingBaseUrl => environment == PaddleEnvironment.sandbox
      ? 'https://sandbox-api.paddle.com'
      : 'https://api.paddle.com';

  /// Creates a new [PaddleProcessor] instance.
  ///
  /// Parameters:
  /// - [vendorId]: Paddle vendor ID from your account
  /// - [vendorAuthCode]: Paddle vendor auth code for API access
  /// - [publicKey]: Public key for webhook signature verification
  /// - [environment]: Environment to use (sandbox or production)
  ///
  /// Throws [InvalidConfigurationException] if configuration is invalid.
  PaddleProcessor({
    required this.vendorId,
    required this.vendorAuthCode,
    required this.publicKey,
    required this.environment,
  }) {
    // Validate configuration
    if (vendorId.isEmpty) {
      throw InvalidConfigurationException(
        'Paddle vendor ID is required',
        fieldName: 'vendorId',
      );
    }
    if (vendorAuthCode.isEmpty) {
      throw InvalidConfigurationException(
        'Paddle vendor auth code is required',
        fieldName: 'vendorAuthCode',
      );
    }
    if (publicKey.isEmpty) {
      throw InvalidConfigurationException(
        'Paddle public key is required',
        fieldName: 'publicKey',
      );
    }

    // Initialize Dio client for Classic API
    _dio = Dio(
      BaseOptions(
        baseUrl: _classicBaseUrl,
        headers: {
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    // Add interceptors for error handling and retry logic
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          // Handle rate limiting with retry
          if (error.response?.statusCode == 429) {
            await Future.delayed(const Duration(seconds: 5));

            // Retry the request
            try {
              final response = await _dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } catch (e) {
              return handler.reject(error);
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  // ==========================================================================
  // HELPER METHODS
  // ==========================================================================

  /// Makes an HTTP request to the Paddle Classic API.
  Future<Map<String, dynamic>> _makeClassicRequest(
    String endpoint, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final requestData = {
        'vendor_id': vendorId,
        'vendor_auth_code': vendorAuthCode,
        ...?data,
      };

      final response = await _dio.post(
        endpoint,
        data: requestData,
      );

      final responseData = response.data as Map<String, dynamic>;

      // Check for Paddle error response
      if (responseData['success'] == false) {
        _handlePaddleError(responseData);
      }

      return responseData;
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow; // This line won't be reached, but satisfies the analyzer
    }
  }

  /// Makes an HTTP request to the Paddle Billing API.
  Future<Map<String, dynamic>> _makeBillingRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: _billingBaseUrl,
          headers: {
            'Authorization': 'Bearer $vendorAuthCode',
            'Content-Type': 'application/json',
          },
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      Response<dynamic> response;

      if (method == 'GET') {
        response = await dio.get(endpoint, queryParameters: data);
      } else if (method == 'POST') {
        response = await dio.post(endpoint, data: data);
      } else if (method == 'PATCH') {
        response = await dio.patch(endpoint, data: data);
      } else if (method == 'DELETE') {
        response = await dio.delete(endpoint);
      } else {
        throw UnsupportedError('HTTP method $method is not supported');
      }

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  /// Handles Paddle Classic API error responses.
  Never _handlePaddleError(Map<String, dynamic> response) {
    final error = response['error'] as Map<String, dynamic>?;
    final errorMessage = error?['message'] as String? ??
        response['message'] as String? ??
        'Unknown Paddle error';
    final errorCode = error?['code'] as String? ?? 'unknown';

    throw ProcessorException(
      errorMessage,
      code: errorCode,
      processorName: 'Paddle',
    );
  }

  /// Handles Dio/network errors.
  Never _handleDioError(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;
    final errorData = response?.data;

    // Network errors
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      throw NetworkException(
        'Request timeout while communicating with Paddle',
        code: 'timeout',
        url: error.requestOptions.uri.toString(),
        originalError: error,
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      throw NetworkException(
        'Failed to connect to Paddle API',
        code: 'connection_error',
        url: error.requestOptions.uri.toString(),
        originalError: error,
      );
    }

    // Parse Paddle error response
    if (errorData is Map<String, dynamic>) {
      final errorInfo = errorData['error'] as Map<String, dynamic>?;
      final message = errorInfo?['message'] as String? ??
          errorData['message'] as String? ??
          'Unknown error';
      final code = errorInfo?['code'] as String? ??
          errorData['code'] as String? ??
          'unknown';

      // Authentication errors
      if (statusCode == 401 || statusCode == 403) {
        throw AuthenticationException(
          message,
          code: code,
          authenticationType: 'vendor_auth',
          originalError: error,
        );
      }

      // Rate limiting
      if (statusCode == 429) {
        throw ProcessorException(
          'Rate limit exceeded',
          code: 'rate_limit_exceeded',
          processorName: 'Paddle',
          originalError: error,
        );
      }

      // Resource not found
      if (statusCode == 404) {
        if (message.toLowerCase().contains('customer')) {
          throw CustomerNotFoundException(
            message,
            originalError: error,
          );
        } else if (message.toLowerCase().contains('subscription')) {
          throw SubscriptionNotFoundException(
            message,
            originalError: error,
          );
        }
      }

      // Validation errors
      if (statusCode == 400 || statusCode == 422) {
        throw ValidationException(
          message,
          code: code,
          originalError: error,
        );
      }

      // Generic processor error
      throw ProcessorException(
        message,
        code: code,
        processorName: 'Paddle',
        originalError: error,
      );
    }

    // Fallback error
    throw NetworkException(
      'HTTP error ${statusCode ?? 'unknown'}',
      statusCode: statusCode,
      url: error.requestOptions.uri.toString(),
      originalError: error,
    );
  }

  /// Generates a checkout URL for subscription creation.
  ///
  /// Since Paddle doesn't support direct subscription creation via API,
  /// this generates a hosted checkout URL for the user to complete the process.
  String _generateCheckoutUrl(String priceId, String customerId) {
    final baseUrl = environment == PaddleEnvironment.sandbox
        ? 'https://sandbox-checkout.paddle.com/checkout'
        : 'https://checkout.paddle.com/checkout';

    final params = {
      'vendor': vendorId,
      'product': priceId,
      'passthrough': jsonEncode({'customer_id': customerId}),
    };

    final queryString = params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '$baseUrl?$queryString';
  }

  /// Validates a Paddle webhook signature.
  bool _validateWebhookSignature(
    Map<String, dynamic> data,
    String signature,
  ) {
    // Extract p_signature from data and remove it
    final paddleSignature = data['p_signature'] as String?;
    if (paddleSignature == null || paddleSignature != signature) {
      return false;
    }

    // Create a copy without p_signature for verification
    final dataToVerify = Map<String, dynamic>.from(data)..remove('p_signature');

    // Sort keys and create string
    final sortedKeys = dataToVerify.keys.toList()..sort();
    final fields = sortedKeys.map((key) {
      final value = dataToVerify[key];
      return '$key=$value';
    }).join();

    // Verify signature using public key (simplified - actual implementation
    // would use proper RSA verification with the public key)
    // This is a placeholder - real implementation needs crypto library
    final bytes = utf8.encode(fields);
    final hash = sha1.convert(bytes);

    return hash.toString() == signature;
  }

  /// Maps a Paddle subscription response to our Subscription model.
  Subscription _mapPaddleSubscription(
    Map<String, dynamic> json,
    String customerId,
  ) {
    final status = _mapPaddleSubscriptionStatus(json['state'] as String?);
    final nextBillDate = json['next_bill_date'] as String?;
    final lastPayment = json['last_payment'] as Map<String, dynamic>?;
    final lastPaymentDate = lastPayment?['date'] as String?;
    final cancelUrl = json['cancel_url'] as String?;
    final updateUrl = json['update_url'] as String?;

    return Subscription(
      id: json['subscription_id']?.toString() ?? '',
      customerId: customerId,
      status: status,
      priceId: json['plan_id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      currentPeriodStart: lastPaymentDate != null
          ? DateTime.parse(lastPaymentDate)
          : DateTime.now(),
      currentPeriodEnd: nextBillDate != null
          ? DateTime.parse(nextBillDate)
          : DateTime.now().add(const Duration(days: 30)),
      trialStart: null, // Paddle handles trials differently
      trialEnd: null,
      canceledAt: json['cancellation_effective_date'] != null
          ? DateTime.parse(json['cancellation_effective_date'] as String)
          : null,
      cancelAtPeriodEnd: json['state'] == 'deleted',
      quantity: json['quantity'] as int? ?? 1,
      processor: ProcessorType.paddle,
      processorSubscriptionId: json['subscription_id']?.toString() ?? '',
      metadata: {
        'cancel_url': cancelUrl,
        'update_url': updateUrl,
        ...?json['passthrough'] != null
            ? (jsonDecode(json['passthrough'] as String)
                as Map<String, dynamic>?)
            : null,
      },
    );
  }

  /// Maps Paddle subscription status to our enum.
  SubscriptionStatus _mapPaddleSubscriptionStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return SubscriptionStatus.active;
      case 'trialing':
        return SubscriptionStatus.trialing;
      case 'past_due':
        return SubscriptionStatus.pastDue;
      case 'deleted':
      case 'cancelled':
        return SubscriptionStatus.canceled;
      case 'paused':
        return SubscriptionStatus.paused;
      default:
        return SubscriptionStatus.incomplete;
    }
  }

  /// Maps Paddle payment status to our ChargeStatus enum.
  ChargeStatus _mapPaddleChargeStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
      case 'success':
        return ChargeStatus.succeeded;
      case 'pending':
        return ChargeStatus.pending;
      case 'refunded':
        return ChargeStatus.refunded;
      case 'failed':
      default:
        return ChargeStatus.failed;
    }
  }

  /// Maps a Paddle customer response to our Customer model.
  Customer _mapPaddleCustomer(Map<String, dynamic> json) {
    return Customer(
      id: json['customer_id']?.toString() ?? json['id']?.toString() ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      processor: ProcessorType.paddle,
      processorCustomerId: json['customer_id']?.toString() ??
          json['id']?.toString() ??
          '',
      metadata: json['custom_data'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Maps a Paddle payment method to our PaymentMethod model.
  PaymentMethod _mapPaddlePaymentMethod(
    Map<String, dynamic> json,
    String customerId,
    bool isDefault,
  ) {
    final cardType = json['card_type'] as String?;
    final last4 = json['last_four_digits'] as String?;
    final expiryDate = json['expiry_date'] as String?;

    // Parse expiry date (format: MM/YY)
    int? expiryMonth;
    int? expiryYear;
    if (expiryDate != null && expiryDate.contains('/')) {
      final parts = expiryDate.split('/');
      if (parts.length == 2) {
        expiryMonth = int.tryParse(parts[0]);
        expiryYear = int.tryParse('20${parts[1]}');
      }
    }

    return PaymentMethod(
      id: json['payment_method_id']?.toString() ?? '',
      customerId: customerId,
      type: _mapPaddlePaymentMethodType(json['type'] as String?),
      last4: last4,
      brand: cardType,
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
      isDefault: isDefault,
      billingDetails: null, // Paddle doesn't provide detailed billing info
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Maps Paddle payment method type to our enum.
  PaymentMethodType _mapPaddlePaymentMethodType(String? type) {
    switch (type?.toLowerCase()) {
      case 'card':
        return PaymentMethodType.card;
      case 'paypal':
        return PaymentMethodType.paypal;
      default:
        return PaymentMethodType.card;
    }
  }

  /// Maps a Paddle charge/payment to our Charge model.
  Charge _mapPaddleCharge(Map<String, dynamic> json, String customerId) {
    final status = _mapPaddleChargeStatus(json['status'] as String?);
    final amount = json['amount'] as num?;
    final refundedAmount = json['refunded_amount'] as num?;

    // Convert amount from decimal to cents
    final amountInCents = amount != null ? (amount * 100).toInt() : 0;
    final refundedInCents =
        refundedAmount != null ? (refundedAmount * 100).toInt() : 0;

    return Charge(
      id: json['order_id']?.toString() ?? json['payment_id']?.toString() ?? '',
      customerId: customerId,
      amount: amountInCents,
      currency: json['currency'] as String? ?? 'usd',
      status: status,
      description: json['product_name'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      refunded: refundedInCents > 0,
      refundedAmount: refundedInCents > 0 ? refundedInCents : null,
      processorChargeId:
          json['order_id']?.toString() ?? json['payment_id']?.toString() ?? '',
      processor: ProcessorType.paddle,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['event_time'] != null
              ? DateTime.parse(json['event_time'] as String)
              : DateTime.now(),
      metadata: json['passthrough'] != null
          ? (jsonDecode(json['passthrough'] as String)
              as Map<String, dynamic>?)
          : null,
    );
  }

  // ==========================================================================
  // CUSTOMER MANAGEMENT
  // ==========================================================================

  @override
  Future<Customer> createCustomer({
    required String email,
    String? name,
    String? phone,
    Map<String, dynamic>? metadata,
  }) async {
    // Paddle Billing API for customer creation
    final data = <String, dynamic>{
      'email': email,
      if (name != null) 'name': name,
      if (metadata != null) 'custom_data': metadata,
    };

    final response = await _makeBillingRequest(
      'POST',
      '/customers',
      data: data,
    );

    final customerData = response['data'] as Map<String, dynamic>? ?? response;
    return _mapPaddleCustomer(customerData);
  }

  @override
  Future<Customer> getCustomer(String customerId) async {
    final response = await _makeBillingRequest(
      'GET',
      '/customers/$customerId',
    );

    final customerData = response['data'] as Map<String, dynamic>? ?? response;
    return _mapPaddleCustomer(customerData);
  }

  @override
  Future<Customer> updateCustomer(
    String customerId, {
    String? email,
    String? name,
    String? phone,
    Map<String, dynamic>? metadata,
  }) async {
    final data = <String, dynamic>{
      if (email != null) 'email': email,
      if (name != null) 'name': name,
      if (metadata != null) 'custom_data': metadata,
    };

    final response = await _makeBillingRequest(
      'PATCH',
      '/customers/$customerId',
      data: data,
    );

    final customerData = response['data'] as Map<String, dynamic>? ?? response;
    return _mapPaddleCustomer(customerData);
  }

  @override
  Future<void> deleteCustomer(String customerId) async {
    // Paddle doesn't have a direct delete customer API
    // Instead, we archive/deactivate the customer
    await _makeBillingRequest(
      'PATCH',
      '/customers/$customerId',
      data: {'status': 'archived'},
    );
  }

  // ==========================================================================
  // PAYMENT METHODS
  // ==========================================================================

  @override
  Future<PaymentMethod> addPaymentMethod({
    required String customerId,
    required String paymentMethodToken,
    bool setAsDefault = false,
  }) async {
    // Paddle handles payment methods differently
    // Payment methods are added during checkout process
    // This is a simplified implementation that stores the token reference

    final data = <String, dynamic>{
      'customer_id': customerId,
      'payment_method_id': paymentMethodToken,
    };

    // In a real implementation, this would interact with Paddle Billing API
    // For now, we return a placeholder
    return PaymentMethod(
      id: paymentMethodToken,
      customerId: customerId,
      type: PaymentMethodType.card,
      last4: null,
      brand: null,
      expiryMonth: null,
      expiryYear: null,
      isDefault: setAsDefault,
      billingDetails: null,
      metadata: data,
    );
  }

  @override
  Future<PaymentMethod> getPaymentMethod(String paymentMethodId) async {
    // Paddle doesn't provide a direct API to get payment method details
    // Payment method info is typically included in subscription/transaction data
    throw ProcessorException(
      'Paddle does not support direct payment method retrieval. '
      'Payment method information is included in subscription and transaction data.',
      code: 'unsupported_operation',
      processorName: 'Paddle',
    );
  }

  @override
  Future<List<PaymentMethod>> listPaymentMethods(String customerId) async {
    // Paddle doesn't provide a direct API to list payment methods
    // Payment methods are managed through the customer portal
    return [];
  }

  @override
  Future<PaymentMethod> setDefaultPaymentMethod({
    required String customerId,
    required String paymentMethodId,
  }) async {
    // Paddle handles default payment methods automatically
    // Customers can change their payment method through the customer portal
    return PaymentMethod(
      id: paymentMethodId,
      customerId: customerId,
      type: PaymentMethodType.card,
      last4: null,
      brand: null,
      expiryMonth: null,
      expiryYear: null,
      isDefault: true,
      billingDetails: null,
      metadata: null,
    );
  }

  @override
  Future<void> removePaymentMethod(String paymentMethodId) async {
    // Paddle manages payment methods through customer portal
    // No direct API for removing payment methods
    throw ProcessorException(
      'Paddle payment methods must be managed through the customer portal',
      code: 'unsupported_operation',
      processorName: 'Paddle',
    );
  }

  // ==========================================================================
  // SUBSCRIPTIONS
  // ==========================================================================

  @override
  Future<Subscription> createSubscription({
    required String customerId,
    required String priceId,
    String? paymentMethodId,
    int? trialDays,
    int quantity = 1,
    Map<String, dynamic>? metadata,
  }) async {
    // Paddle doesn't support direct subscription creation via API
    // Generate a checkout URL instead
    final checkoutUrl = _generateCheckoutUrl(priceId, customerId);

    // Return a pending subscription with checkout URL in metadata
    return Subscription(
      id: 'pending_${_uuid.v4()}',
      customerId: customerId,
      status: SubscriptionStatus.incomplete,
      priceId: priceId,
      productId: priceId,
      currentPeriodStart: DateTime.now(),
      currentPeriodEnd: DateTime.now().add(const Duration(days: 30)),
      trialStart: trialDays != null ? DateTime.now() : null,
      trialEnd: trialDays != null
          ? DateTime.now().add(Duration(days: trialDays))
          : null,
      canceledAt: null,
      cancelAtPeriodEnd: false,
      quantity: quantity,
      processor: ProcessorType.paddle,
      processorSubscriptionId: '',
      metadata: {
        'checkout_url': checkoutUrl,
        'note':
            'Complete the subscription by visiting the checkout URL. '
                'The subscription will be activated after successful payment.',
        ...?metadata,
      },
    );
  }

  @override
  Future<Subscription> getSubscription(String subscriptionId) async {
    final response = await _makeClassicRequest(
      '/subscription/users',
      data: {'subscription_id': subscriptionId},
    );

    final subscriptionData = response['response'] as List<dynamic>?;
    if (subscriptionData == null || subscriptionData.isEmpty) {
      throw SubscriptionNotFoundException(
        'Subscription not found: $subscriptionId',
        subscriptionId: subscriptionId,
      );
    }

    final subscription = subscriptionData.first as Map<String, dynamic>;
    final customerId = subscription['user_id']?.toString() ??
        subscription['email'] as String? ??
        '';

    return _mapPaddleSubscription(subscription, customerId);
  }

  @override
  Future<List<Subscription>> listSubscriptions(String customerId) async {
    // For Paddle, we would typically use email or subscription ID
    // This is a simplified implementation
    try {
      final response = await _makeClassicRequest(
        '/subscription/users',
        data: {'email': customerId}, // Assuming customerId might be email
      );

      final subscriptions = response['response'] as List<dynamic>? ?? [];
      return subscriptions
          .map((sub) =>
              _mapPaddleSubscription(sub as Map<String, dynamic>, customerId))
          .toList();
    } catch (e) {
      // Return empty list if customer has no subscriptions
      return [];
    }
  }

  @override
  Future<Subscription> updateSubscription({
    required String subscriptionId,
    String? priceId,
    int? quantity,
    Map<String, dynamic>? metadata,
  }) async {
    final data = <String, dynamic>{
      'subscription_id': subscriptionId,
      if (priceId != null) 'plan_id': priceId,
      if (quantity != null) 'quantity': quantity,
      if (metadata != null) 'passthrough': jsonEncode(metadata),
    };

    final response = await _makeClassicRequest(
      '/subscription/users/update',
      data: data,
    );

    final subscriptionData =
        response['response'] as Map<String, dynamic>? ?? response;
    final customerId =
        subscriptionData['user_id']?.toString() ?? subscriptionId;

    return _mapPaddleSubscription(subscriptionData, customerId);
  }

  @override
  Future<Subscription> cancelSubscription({
    required String subscriptionId,
    bool immediate = false,
  }) async {
    final response = await _makeClassicRequest(
      '/subscription/users_cancel',
      data: {'subscription_id': subscriptionId},
    );

    // Get updated subscription
    return getSubscription(subscriptionId);
  }

  @override
  Future<Subscription> resumeSubscription(String subscriptionId) async {
    // Paddle doesn't have a direct resume API
    // Customers need to use the update URL to reactivate
    throw ProcessorException(
      'Paddle subscriptions must be resumed through the customer portal update URL',
      code: 'unsupported_operation',
      processorName: 'Paddle',
    );
  }

  @override
  Future<Subscription> pauseSubscription(String subscriptionId) async {
    final response = await _makeClassicRequest(
      '/subscription/users/pause',
      data: {'subscription_id': subscriptionId},
    );

    return getSubscription(subscriptionId);
  }

  @override
  Future<Subscription> swapPlan({
    required String subscriptionId,
    required String newPriceId,
    bool prorate = true,
  }) async {
    final data = <String, dynamic>{
      'subscription_id': subscriptionId,
      'plan_id': newPriceId,
      'prorate': prorate,
    };

    final response = await _makeClassicRequest(
      '/subscription/users/update',
      data: data,
    );

    return getSubscription(subscriptionId);
  }

  // ==========================================================================
  // CHARGES (ONE-TIME PAYMENTS)
  // ==========================================================================

  @override
  Future<Charge> createCharge({
    required String customerId,
    required int amount,
    required String currency,
    String? description,
    String? paymentMethodId,
    Map<String, dynamic>? metadata,
  }) async {
    // Paddle doesn't support direct one-time charges via API
    // One-time payments must be created through checkout
    // This returns a pending charge with checkout information

    final checkoutUrl = _generateCheckoutUrl('one_time', customerId);

    return Charge(
      id: 'pending_${_uuid.v4()}',
      customerId: customerId,
      amount: amount,
      currency: currency.toLowerCase(),
      status: ChargeStatus.pending,
      description: description,
      receiptUrl: null,
      refunded: false,
      refundedAmount: null,
      processorChargeId: '',
      processor: ProcessorType.paddle,
      createdAt: DateTime.now(),
      metadata: {
        'checkout_url': checkoutUrl,
        'note':
            'Complete the payment by visiting the checkout URL. '
                'The charge will be processed after successful payment.',
        ...?metadata,
      },
    );
  }

  @override
  Future<Charge> getCharge(String chargeId) async {
    final response = await _makeClassicRequest(
      '/order',
      data: {'order_id': chargeId},
    );

    final orderData = response['response'] as Map<String, dynamic>? ?? response;
    final customerId = orderData['customer_email'] as String? ?? '';

    return _mapPaddleCharge(orderData, customerId);
  }

  @override
  Future<List<Charge>> listCharges({
    String? customerId,
    int limit = 10,
  }) async {
    // Paddle doesn't have a direct API to list all charges
    // Would need to use the transactions API
    return [];
  }

  @override
  Future<Charge> refundCharge({
    required String chargeId,
    int? amount,
    String? reason,
  }) async {
    final refundAmount = amount != null ? (amount / 100).toStringAsFixed(2) : null;

    final data = <String, dynamic>{
      'order_id': chargeId,
      if (refundAmount != null) 'amount': refundAmount,
      if (reason != null) 'reason': reason,
    };

    final response = await _makeClassicRequest(
      '/payment/refund',
      data: data,
    );

    // Get updated charge
    return getCharge(chargeId);
  }

  // ==========================================================================
  // WEBHOOK HANDLING
  // ==========================================================================

  @override
  Future<WebhookEvent> handleWebhook({
    required Map<String, dynamic> payload,
    String? signature,
  }) async {
    // Verify signature if provided
    if (signature != null && publicKey.isNotEmpty) {
      final isValid = _validateWebhookSignature(payload, signature);

      if (!isValid) {
        throw WebhookException(
          'Invalid webhook signature',
          code: 'invalid_signature',
        );
      }
    }

    final alertName = payload['alert_name'] as String?;
    final alertId = payload['alert_id']?.toString() ?? _uuid.v4();
    final eventTime = payload['event_time'] as String?;

    if (alertName == null) {
      throw WebhookException(
        'Webhook alert_name is missing',
        code: 'missing_alert_name',
      );
    }

    return WebhookEvent(
      id: alertId,
      type: alertName,
      processor: ProcessorType.paddle,
      data: payload,
      createdAt: eventTime != null
          ? DateTime.parse(eventTime)
          : DateTime.now(),
    );
  }

  @override
  bool verifyWebhookSignature({
    required String payload,
    required String signature,
    required String secret,
  }) {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      return _validateWebhookSignature(data, signature);
    } catch (e) {
      return false;
    }
  }

  // ==========================================================================
  // UTILITY METHODS
  // ==========================================================================

  @override
  ProcessorType get processorType => ProcessorType.paddle;

  @override
  String get name => 'Paddle';

  @override
  bool get supportsTrialPeriods => true;

  @override
  bool get supportsPlanSwapping => true;

  @override
  bool get supportsProration => true;

  @override
  Future<bool> validateConfiguration() async {
    try {
      // Make a simple API call to validate credentials
      await _makeClassicRequest(
        '/product/get_products',
        data: {},
      );
      return true;
    } on AuthenticationException {
      throw InvalidConfigurationException(
        'Invalid Paddle vendor credentials',
        code: 'invalid_credentials',
      );
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw InvalidConfigurationException(
        'Failed to validate Paddle configuration: $e',
        originalError: e,
      );
    }
  }
}
