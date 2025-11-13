import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../exceptions/exceptions.dart';
import '../models/models.dart';
import 'base_processor.dart';

/// Totalpay Global payment processor implementation.
///
/// This class provides an implementation of the PaymentProcessor interface
/// for Totalpay Global's payment gateway API.
///
/// **API Documentation**: https://docs.totalpay.global/
/// **Note**: Full API documentation requires merchant account access.
///
/// Example usage:
/// ```dart
/// final processor = TotalpayProcessor(
///   merchantId: 'merchant_12345',
///   apiKey: 'your_api_key',
///   secretKey: 'your_secret_key',
///   environment: TotalpayEnvironment.sandbox,
/// );
///
/// final customer = await processor.createCustomer(
///   email: 'user@example.com',
///   name: 'John Doe',
/// );
/// ```
///
/// **Implementation Status**:
/// - Authentication and basic structure: Implemented
/// - Customer management: Partially implemented (requires API documentation)
/// - Payment methods: Partially implemented (requires API documentation)
/// - One-time payments: Partially implemented
/// - Recurring payments/subscriptions: Partially implemented
/// - Webhook handling: Implemented (signature verification pending)
///
/// **TODO**: Complete implementation once full API documentation is available.
/// Contact Totalpay Global support at https://totalpay.global for API access.
class TotalpayProcessor extends PaymentProcessor {
  /// Totalpay merchant ID
  final String merchantId;

  /// Totalpay API key for authentication
  final String apiKey;

  /// Totalpay secret key for signing requests
  final String secretKey;

  /// Environment (sandbox or production)
  final TotalpayEnvironment environment;

  /// HTTP client for making API requests
  late final Dio _dio;

  /// UUID generator for idempotency keys
  final _uuid = const Uuid();

  /// Base URL for Totalpay API (sandbox)
  static const String _sandboxUrl = 'https://sandbox.totalpay.global/api';

  /// Base URL for Totalpay API (production)
  static const String _productionUrl = 'https://api.totalpay.global';

  /// Creates a new [TotalpayProcessor] instance.
  ///
  /// Parameters:
  /// - [merchantId]: Totalpay merchant identifier
  /// - [apiKey]: Totalpay API key (also called merchant key)
  /// - [secretKey]: Totalpay secret key for request signing
  /// - [environment]: Sandbox or production environment
  ///
  /// Throws [InvalidConfigurationException] if credentials are invalid.
  TotalpayProcessor({
    required this.merchantId,
    required this.apiKey,
    required this.secretKey,
    this.environment = TotalpayEnvironment.sandbox,
  }) {
    // Validate configuration
    if (merchantId.isEmpty) {
      throw InvalidConfigurationException(
        'Totalpay merchant ID is required',
        fieldName: 'merchantId',
      );
    }
    if (apiKey.isEmpty) {
      throw InvalidConfigurationException(
        'Totalpay API key is required',
        fieldName: 'apiKey',
      );
    }
    if (secretKey.isEmpty) {
      throw InvalidConfigurationException(
        'Totalpay secret key is required',
        fieldName: 'secretKey',
      );
    }

    // Initialize Dio client
    final baseUrl =
        environment == TotalpayEnvironment.sandbox ? _sandboxUrl : _productionUrl;

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    // Add interceptors for logging and error handling
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add authentication to each request
          _addAuthentication(options);
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle rate limiting with retry
          if (error.response?.statusCode == 429) {
            final retryAfter = error.response?.headers.value('retry-after');
            if (retryAfter != null) {
              final delay = int.tryParse(retryAfter) ?? 5;
              await Future.delayed(Duration(seconds: delay));

              // Retry the request
              try {
                final response = await _dio.fetch(error.requestOptions);
                return handler.resolve(response);
              } catch (e) {
                return handler.reject(error);
              }
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

  /// Adds authentication headers to the request.
  ///
  /// Totalpay uses merchant key (API key) and password (secret key) for
  /// authentication, along with a signed hash for request verification.
  void _addAuthentication(RequestOptions options) {
    // Add basic authentication headers
    options.headers['X-Merchant-Id'] = merchantId;
    options.headers['X-Api-Key'] = apiKey;

    // Generate request signature if data is present
    if (options.data != null) {
      final signature = _generateSignature(options.data);
      options.headers['X-Signature'] = signature;
    }
  }

  /// Generates HMAC-SHA256 signature for request data.
  ///
  /// TODO: Verify the exact signature format required by Totalpay API.
  /// This implementation uses HMAC-SHA256 which is common for payment APIs.
  String _generateSignature(dynamic data) {
    final payload = data is String ? data : jsonEncode(data);
    final hmac = Hmac(sha256, utf8.encode(secretKey));
    final digest = hmac.convert(utf8.encode(payload));
    return digest.toString();
  }

  /// Makes an HTTP request to the Totalpay API.
  ///
  /// Parameters:
  /// - [method]: HTTP method (GET, POST, DELETE)
  /// - [endpoint]: API endpoint path (e.g., '/customers')
  /// - [data]: Optional request data
  /// - [idempotencyKey]: Optional idempotency key for POST requests
  ///
  /// Returns the response data as a Map.
  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? data,
    String? idempotencyKey,
  }) async {
    try {
      final options = Options(
        method: method,
        headers: idempotencyKey != null
            ? {'Idempotency-Key': idempotencyKey}
            : null,
      );

      Response<dynamic> response;

      if (method == 'GET') {
        response = await _dio.get(endpoint, queryParameters: data);
      } else if (method == 'POST') {
        response = await _dio.post(
          endpoint,
          data: data,
          options: options,
        );
      } else if (method == 'DELETE') {
        response = await _dio.delete(endpoint, data: data);
      } else if (method == 'PUT') {
        response = await _dio.put(endpoint, data: data, options: options);
      } else {
        throw UnsupportedError('HTTP method $method is not supported');
      }

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleTotalpayError(e);
      rethrow; // This line won't be reached, but satisfies the analyzer
    }
  }

  /// Handles Totalpay API errors and converts them to appropriate exceptions.
  ///
  /// TODO: Update error handling based on actual Totalpay error response format.
  Never _handleTotalpayError(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;
    final errorData = response?.data;

    // Network errors
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      throw NetworkException(
        'Request timeout while communicating with Totalpay',
        code: 'timeout',
        url: error.requestOptions.uri.toString(),
        originalError: error,
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      throw NetworkException(
        'Failed to connect to Totalpay API',
        code: 'connection_error',
        url: error.requestOptions.uri.toString(),
        originalError: error,
      );
    }

    // Parse Totalpay error response
    if (errorData is Map<String, dynamic>) {
      final code = errorData['code'] as String?;
      final message = errorData['message'] as String? ??
          errorData['error'] as String? ??
          'Unknown error';
      final details = errorData['details'] as String?;

      // Authentication errors
      if (statusCode == 401 || statusCode == 403) {
        throw AuthenticationException(
          message,
          code: code,
          authenticationType: 'api_key',
          originalError: error,
        );
      }

      // Rate limiting
      if (statusCode == 429) {
        throw ProcessorException(
          'Rate limit exceeded',
          code: 'rate_limit_exceeded',
          processorName: 'Totalpay',
          originalError: error,
        );
      }

      // Payment/card errors
      if (code == 'card_declined' ||
          code == 'insufficient_funds' ||
          code == 'invalid_card' ||
          code == 'expired_card' ||
          code == 'invalid_cvc' ||
          code == 'processing_error') {
        throw PaymentMethodException(
          message,
          code: code,
          originalError: error,
        );
      }

      // Resource not found errors
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
          details ?? message,
          code: code,
          originalError: error,
        );
      }

      // Generic processor error
      throw ProcessorException(
        message,
        code: code,
        processorName: 'Totalpay',
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

  // ==========================================================================
  // CUSTOMER MANAGEMENT
  // ==========================================================================

  /// TODO: Implement once Totalpay customer API endpoints are documented.
  /// The current implementation creates a placeholder customer object.
  ///
  /// Required API information:
  /// - Customer creation endpoint
  /// - Required fields and their format
  /// - Response structure
  @override
  Future<Customer> createCustomer({
    required String email,
    String? name,
    String? phone,
    Map<String, dynamic>? metadata,
  }) async {
    // TODO: Replace with actual API call when documentation is available
    // Expected endpoint: POST /customers or /v1/customers
    throw UnimplementedError(
      'Totalpay customer creation requires API documentation. '
      'Contact Totalpay support at https://totalpay.global for API access. '
      'Once available, implement POST request to customer creation endpoint.',
    );

    /*
    // Example implementation (update when API is documented):
    final data = <String, dynamic>{
      'email': email,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (metadata != null) 'metadata': metadata,
    };

    final response = await _makeRequest(
      'POST',
      '/v1/customers',
      data: data,
      idempotencyKey: _uuid.v4(),
    );

    return _mapTotalpayCustomer(response);
    */
  }

  @override
  Future<Customer> getCustomer(String customerId) async {
    // TODO: Implement once API documentation is available
    throw UnimplementedError(
      'Totalpay customer retrieval requires API documentation. '
      'Expected endpoint: GET /customers/{id}',
    );
  }

  @override
  Future<Customer> updateCustomer(
    String customerId, {
    String? email,
    String? name,
    String? phone,
    Map<String, dynamic>? metadata,
  }) async {
    // TODO: Implement once API documentation is available
    throw UnimplementedError(
      'Totalpay customer update requires API documentation. '
      'Expected endpoint: PUT /customers/{id} or PATCH /customers/{id}',
    );
  }

  @override
  Future<void> deleteCustomer(String customerId) async {
    // TODO: Implement once API documentation is available
    throw UnimplementedError(
      'Totalpay customer deletion requires API documentation. '
      'Expected endpoint: DELETE /customers/{id}',
    );
  }

  // ==========================================================================
  // PAYMENT METHODS
  // ==========================================================================

  /// Totalpay supports card tokenization for recurring payments.
  ///
  /// TODO: Implement based on Totalpay's tokenization API.
  /// Reference: https://docs.totalpay.global/checkout_integration
  @override
  Future<PaymentMethod> addPaymentMethod({
    required String customerId,
    required String paymentMethodToken,
    bool setAsDefault = false,
  }) async {
    // TODO: Implement card tokenization API integration
    throw UnimplementedError(
      'Totalpay payment method management requires API documentation. '
      'Totalpay supports card tokenization via recurringToken. '
      'Expected endpoint: POST /payment-methods or /tokens',
    );
  }

  @override
  Future<PaymentMethod> getPaymentMethod(String paymentMethodId) async {
    // TODO: Implement once API documentation is available
    throw UnimplementedError(
      'Totalpay payment method retrieval requires API documentation. '
      'Expected endpoint: GET /payment-methods/{id}',
    );
  }

  @override
  Future<List<PaymentMethod>> listPaymentMethods(String customerId) async {
    // TODO: Implement once API documentation is available
    throw UnimplementedError(
      'Totalpay payment method listing requires API documentation. '
      'Expected endpoint: GET /customers/{id}/payment-methods',
    );
  }

  @override
  Future<PaymentMethod> setDefaultPaymentMethod({
    required String customerId,
    required String paymentMethodId,
  }) async {
    // TODO: Implement once API documentation is available
    throw UnimplementedError(
      'Totalpay default payment method setting requires API documentation.',
    );
  }

  @override
  Future<void> removePaymentMethod(String paymentMethodId) async {
    // TODO: Implement once API documentation is available
    throw UnimplementedError(
      'Totalpay payment method removal requires API documentation. '
      'Expected endpoint: DELETE /payment-methods/{id}',
    );
  }

  // ==========================================================================
  // SUBSCRIPTIONS
  // ==========================================================================

  /// Creates a recurring payment subscription.
  ///
  /// Totalpay supports recurring payments using recurringInit flag.
  ///
  /// TODO: Implement based on Totalpay recurring payment API.
  @override
  Future<Subscription> createSubscription({
    required String customerId,
    required String priceId,
    String? paymentMethodId,
    int? trialDays,
    int quantity = 1,
    Map<String, dynamic>? metadata,
  }) async {
    // TODO: Implement recurring payment initialization
    throw UnimplementedError(
      'Totalpay subscription creation requires API documentation. '
      'Totalpay supports recurring payments via recurringInit parameter. '
      'Expected endpoint: POST /subscriptions or /recurring-payments',
    );
  }

  @override
  Future<Subscription> getSubscription(String subscriptionId) async {
    // TODO: Implement once API documentation is available
    throw UnimplementedError(
      'Totalpay subscription retrieval requires API documentation. '
      'Expected endpoint: GET /subscriptions/{id}',
    );
  }

  @override
  Future<List<Subscription>> listSubscriptions(String customerId) async {
    // TODO: Implement once API documentation is available
    throw UnimplementedError(
      'Totalpay subscription listing requires API documentation. '
      'Expected endpoint: GET /customers/{id}/subscriptions',
    );
  }

  @override
  Future<Subscription> updateSubscription({
    required String subscriptionId,
    String? priceId,
    int? quantity,
    Map<String, dynamic>? metadata,
  }) async {
    // TODO: Implement once API documentation is available
    throw UnimplementedError(
      'Totalpay subscription update requires API documentation. '
      'Expected endpoint: PUT /subscriptions/{id}',
    );
  }

  @override
  Future<Subscription> cancelSubscription({
    required String subscriptionId,
    bool immediate = false,
  }) async {
    // TODO: Implement once API documentation is available
    throw UnimplementedError(
      'Totalpay subscription cancellation requires API documentation. '
      'Expected endpoint: DELETE /subscriptions/{id} or POST /subscriptions/{id}/cancel',
    );
  }

  @override
  Future<Subscription> resumeSubscription(String subscriptionId) async {
    // TODO: Implement once API documentation is available
    throw UnimplementedError(
      'Totalpay subscription resumption requires API documentation. '
      'Expected endpoint: POST /subscriptions/{id}/resume',
    );
  }

  @override
  Future<Subscription> pauseSubscription(String subscriptionId) async {
    // TODO: Implement once API documentation is available
    // Note: Check if Totalpay supports pausing subscriptions
    throw UnimplementedError(
      'Totalpay subscription pausing requires API documentation. '
      'Check if this feature is supported by Totalpay.',
    );
  }

  @override
  Future<Subscription> swapPlan({
    required String subscriptionId,
    required String newPriceId,
    bool prorate = true,
  }) async {
    // TODO: Implement once API documentation is available
    // Note: Check if Totalpay supports plan swapping
    throw UnimplementedError(
      'Totalpay plan swapping requires API documentation. '
      'Check if this feature is supported by Totalpay.',
    );
  }

  // ==========================================================================
  // CHARGES (ONE-TIME PAYMENTS)
  // ==========================================================================

  /// Creates a one-time payment charge.
  ///
  /// Totalpay supports one-time purchases through their payment gateway.
  ///
  /// TODO: Implement based on Totalpay payment API.
  @override
  Future<Charge> createCharge({
    required String customerId,
    required int amount,
    required String currency,
    String? description,
    String? paymentMethodId,
    Map<String, dynamic>? metadata,
  }) async {
    // TODO: Implement payment initiation API
    throw UnimplementedError(
      'Totalpay charge creation requires API documentation. '
      'Totalpay supports one-time payments via operation: "purchase". '
      'Expected endpoint: POST /payments or /charges',
    );

    /*
    // Example implementation (update when API is documented):
    final data = <String, dynamic>{
      'merchant_id': merchantId,
      'amount': amount,
      'currency': currency.toUpperCase(),
      'operation': 'purchase',
      if (description != null) 'description': description,
      if (paymentMethodId != null) 'payment_method_id': paymentMethodId,
      if (metadata != null) 'metadata': metadata,
    };

    final response = await _makeRequest(
      'POST',
      '/v1/payments',
      data: data,
      idempotencyKey: _uuid.v4(),
    );

    return _mapTotalpayCharge(response, customerId);
    */
  }

  @override
  Future<Charge> getCharge(String chargeId) async {
    // TODO: Implement once API documentation is available
    throw UnimplementedError(
      'Totalpay charge retrieval requires API documentation. '
      'Expected endpoint: GET /payments/{id} or /charges/{id}',
    );
  }

  @override
  Future<List<Charge>> listCharges({
    String? customerId,
    int limit = 10,
  }) async {
    // TODO: Implement once API documentation is available
    throw UnimplementedError(
      'Totalpay charge listing requires API documentation. '
      'Expected endpoint: GET /payments or /charges',
    );
  }

  @override
  Future<Charge> refundCharge({
    required String chargeId,
    int? amount,
    String? reason,
  }) async {
    // TODO: Implement once API documentation is available
    throw UnimplementedError(
      'Totalpay refund processing requires API documentation. '
      'Expected endpoint: POST /refunds or POST /payments/{id}/refund',
    );
  }

  // ==========================================================================
  // WEBHOOK HANDLING
  // ==========================================================================

  /// Handles incoming webhook events from Totalpay.
  ///
  /// TODO: Implement based on Totalpay webhook documentation.
  @override
  Future<WebhookEvent> handleWebhook({
    required Map<String, dynamic> payload,
    String? signature,
  }) async {
    // Verify signature if provided
    if (signature != null) {
      final isValid = verifyWebhookSignature(
        payload: jsonEncode(payload),
        signature: signature,
        secret: secretKey,
      );

      if (!isValid) {
        throw WebhookException(
          'Invalid webhook signature',
          code: 'invalid_signature',
        );
      }
    }

    // TODO: Update event parsing based on actual Totalpay webhook format
    final id = payload['id'] as String? ??
        payload['transaction_id'] as String? ??
        _uuid.v4();
    final type = payload['event_type'] as String? ??
        payload['type'] as String? ??
        'unknown';
    final timestamp = payload['timestamp'] as int? ?? payload['created'] as int?;

    return WebhookEvent(
      id: id,
      type: type,
      processor: ProcessorType.totalpayGlobal,
      data: payload,
      createdAt: timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)
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
      // TODO: Verify the exact signature format used by Totalpay
      // This implementation uses HMAC-SHA256 which is common for webhooks
      final hmac = Hmac(sha256, utf8.encode(secret));
      final digest = hmac.convert(utf8.encode(payload));
      final expectedSignature = digest.toString();

      // Constant-time comparison would be ideal for production
      return expectedSignature == signature;
    } catch (e) {
      return false;
    }
  }

  // ==========================================================================
  // UTILITY METHODS
  // ==========================================================================

  @override
  ProcessorType get processorType => ProcessorType.totalpayGlobal;

  @override
  String get name => 'Totalpay Global';

  @override
  bool get supportsTrialPeriods => false; // TODO: Verify with documentation

  @override
  bool get supportsPlanSwapping => false; // TODO: Verify with documentation

  @override
  bool get supportsProration => false; // TODO: Verify with documentation

  @override
  Future<bool> validateConfiguration() async {
    try {
      // TODO: Make a simple API call to validate the configuration
      // For now, just validate that credentials are present
      if (merchantId.isEmpty || apiKey.isEmpty || secretKey.isEmpty) {
        throw InvalidConfigurationException(
          'Totalpay credentials are incomplete',
          code: 'incomplete_credentials',
        );
      }

      // TODO: Replace with actual API validation call
      // Example: await _makeRequest('GET', '/v1/merchant/info');
      return true;
    } on AuthenticationException {
      throw InvalidConfigurationException(
        'Invalid Totalpay API credentials',
        code: 'invalid_credentials',
      );
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw InvalidConfigurationException(
        'Failed to validate Totalpay configuration: $e',
        originalError: e,
      );
    }
  }

  // ==========================================================================
  // MAPPER METHODS (To be implemented)
  // ==========================================================================

  /// Maps a Totalpay customer response to our Customer model.
  ///
  /// TODO: Implement based on actual API response format.
  Customer _mapTotalpayCustomer(Map<String, dynamic> json) {
    // TODO: Update field mappings based on actual Totalpay response
    return Customer(
      id: json['id'] as String? ?? json['customer_id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      processor: ProcessorType.totalpayGlobal,
      processorCustomerId: json['id'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: _parseTimestamp(json['created_at'] ?? json['created']),
      updatedAt: _parseTimestamp(json['updated_at'] ?? json['updated']),
    );
  }

  /// Maps a Totalpay subscription response to our Subscription model.
  ///
  /// TODO: Implement based on actual API response format.
  Subscription _mapTotalpaySubscription(
    Map<String, dynamic> json,
    String customerId,
  ) {
    // TODO: Update field mappings based on actual Totalpay response
    return Subscription(
      id: json['id'] as String? ?? '',
      customerId: customerId,
      status: _mapTotalpaySubscriptionStatus(json['status'] as String?),
      priceId: json['price_id'] as String? ?? '',
      productId: json['product_id'] as String? ?? '',
      currentPeriodStart: _parseTimestamp(json['current_period_start']),
      currentPeriodEnd: _parseTimestamp(json['current_period_end']),
      trialStart: _parseTimestamp(json['trial_start']),
      trialEnd: _parseTimestamp(json['trial_end']),
      canceledAt: _parseTimestamp(json['canceled_at']),
      cancelAtPeriodEnd: json['cancel_at_period_end'] as bool? ?? false,
      quantity: json['quantity'] as int? ?? 1,
      processor: ProcessorType.totalpayGlobal,
      processorSubscriptionId: json['id'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Maps a Totalpay payment response to our Charge model.
  ///
  /// TODO: Implement based on actual API response format.
  Charge _mapTotalpayCharge(Map<String, dynamic> json, String customerId) {
    // TODO: Update field mappings based on actual Totalpay response
    return Charge(
      id: json['id'] as String? ?? json['transaction_id'] as String? ?? '',
      customerId: customerId,
      amount: json['amount'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'usd',
      status: _mapTotalpayChargeStatus(json['status'] as String?),
      description: json['description'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      refunded: json['refunded'] as bool? ?? false,
      refundedAmount: json['refunded_amount'] as int?,
      processorChargeId: json['id'] as String? ?? '',
      processor: ProcessorType.totalpayGlobal,
      createdAt: _parseTimestamp(json['created_at'] ?? json['created']),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Maps a Totalpay payment method response to our PaymentMethod model.
  ///
  /// TODO: Implement based on actual API response format.
  PaymentMethod _mapTotalpayPaymentMethod(
    Map<String, dynamic> json,
    String customerId,
    bool isDefault,
  ) {
    // TODO: Update field mappings based on actual Totalpay response
    return PaymentMethod(
      id: json['id'] as String? ?? json['token'] as String? ?? '',
      customerId: customerId,
      type: _mapTotalpayPaymentMethodType(json['type'] as String?),
      last4: json['last4'] as String?,
      brand: json['brand'] as String? ?? json['card_type'] as String?,
      expiryMonth: json['exp_month'] as int?,
      expiryYear: json['exp_year'] as int?,
      isDefault: isDefault,
      billingDetails: null, // TODO: Map if available in response
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Maps Totalpay subscription status to our enum.
  ///
  /// TODO: Update based on actual Totalpay status values.
  SubscriptionStatus _mapTotalpaySubscriptionStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return SubscriptionStatus.active;
      case 'trialing':
      case 'trial':
        return SubscriptionStatus.trialing;
      case 'past_due':
      case 'overdue':
        return SubscriptionStatus.pastDue;
      case 'canceled':
      case 'cancelled':
        return SubscriptionStatus.canceled;
      case 'paused':
      case 'suspended':
        return SubscriptionStatus.paused;
      case 'incomplete':
      case 'pending':
        return SubscriptionStatus.incomplete;
      default:
        return SubscriptionStatus.incomplete;
    }
  }

  /// Maps Totalpay payment status to our ChargeStatus enum.
  ///
  /// TODO: Update based on actual Totalpay status values.
  ChargeStatus _mapTotalpayChargeStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'success':
      case 'succeeded':
      case 'completed':
      case 'approved':
        return ChargeStatus.succeeded;
      case 'failed':
      case 'declined':
      case 'error':
        return ChargeStatus.failed;
      case 'pending':
      case 'processing':
      case 'initiated':
        return ChargeStatus.pending;
      case 'refunded':
        return ChargeStatus.refunded;
      default:
        return ChargeStatus.pending;
    }
  }

  /// Maps Totalpay payment method type to our enum.
  ///
  /// TODO: Update based on actual Totalpay payment method types.
  PaymentMethodType _mapTotalpayPaymentMethodType(String? type) {
    switch (type?.toLowerCase()) {
      case 'card':
      case 'credit_card':
      case 'debit_card':
        return PaymentMethodType.card;
      case 'bank_account':
      case 'bank':
        return PaymentMethodType.bankAccount;
      case 'paypal':
        return PaymentMethodType.paypal;
      case 'apple_pay':
        return PaymentMethodType.applePay;
      case 'google_pay':
        return PaymentMethodType.googlePay;
      default:
        return PaymentMethodType.card;
    }
  }

  /// Parses a timestamp from various formats.
  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.now();
    }

    if (timestamp is int) {
      // Assume Unix timestamp in seconds
      return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    }

    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        return DateTime.now();
      }
    }

    return DateTime.now();
  }
}

/// Totalpay environment configuration
enum TotalpayEnvironment {
  /// Sandbox/test environment
  sandbox,

  /// Production/live environment
  production,
}
