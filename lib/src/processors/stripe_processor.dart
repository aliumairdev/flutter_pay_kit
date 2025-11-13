import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../exceptions/exceptions.dart';
import '../models/models.dart';
import 'base_processor.dart';

/// Stripe payment processor implementation.
///
/// This class provides a complete implementation of the PaymentProcessor
/// interface for Stripe's API v1 REST endpoints.
///
/// Example usage:
/// ```dart
/// final processor = StripeProcessor(
///   publishableKey: 'pk_test_...',
///   secretKey: 'sk_test_...',
///   webhookSecret: 'whsec_...',
/// );
///
/// final customer = await processor.createCustomer(
///   email: 'user@example.com',
///   name: 'John Doe',
/// );
/// ```
class StripeProcessor extends PaymentProcessor {
  /// Stripe publishable key for client-side operations
  final String publishableKey;

  /// Stripe secret key for server-side operations
  final String secretKey;

  /// Stripe API version to use
  final String apiVersion;

  /// Webhook signing secret for verifying webhook signatures
  final String? webhookSecret;

  /// HTTP client for making API requests
  late final Dio _dio;

  /// UUID generator for idempotency keys
  final _uuid = const Uuid();

  /// Base URL for Stripe API
  static const String _baseUrl = 'https://api.stripe.com';

  /// Creates a new [StripeProcessor] instance.
  ///
  /// Parameters:
  /// - [publishableKey]: Stripe publishable key (pk_test_... or pk_live_...)
  /// - [secretKey]: Stripe secret key (sk_test_... or sk_live_...)
  /// - [apiVersion]: Stripe API version (defaults to '2024-11-20')
  /// - [webhookSecret]: Optional webhook signing secret for signature verification
  ///
  /// Throws [InvalidConfigurationException] if keys are invalid.
  StripeProcessor({
    required this.publishableKey,
    required this.secretKey,
    this.apiVersion = '2024-11-20',
    this.webhookSecret,
  }) {
    // Validate configuration
    if (publishableKey.isEmpty) {
      throw InvalidConfigurationException(
        'Stripe publishable key is required',
        fieldName: 'publishableKey',
      );
    }
    if (secretKey.isEmpty) {
      throw InvalidConfigurationException(
        'Stripe secret key is required',
        fieldName: 'secretKey',
      );
    }
    if (!publishableKey.startsWith('pk_')) {
      throw InvalidConfigurationException(
        'Invalid Stripe publishable key format',
        fieldName: 'publishableKey',
      );
    }
    if (!secretKey.startsWith('sk_')) {
      throw InvalidConfigurationException(
        'Invalid Stripe secret key format',
        fieldName: 'secretKey',
      );
    }

    // Initialize Dio client
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        headers: {
          'Authorization': 'Bearer $secretKey',
          'Stripe-Version': apiVersion,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    // Add interceptors for logging and retry logic
    _dio.interceptors.add(
      InterceptorsWrapper(
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

  /// Makes an HTTP request to the Stripe API.
  ///
  /// Parameters:
  /// - [method]: HTTP method (GET, POST, DELETE)
  /// - [endpoint]: API endpoint path (e.g., '/v1/customers')
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
        // Stripe uses form-encoded data
        final formData = data != null ? _encodeFormData(data) : '';
        response = await _dio.post(
          endpoint,
          data: formData,
          options: options,
        );
      } else if (method == 'DELETE') {
        response = await _dio.delete(endpoint);
      } else {
        throw UnsupportedError('HTTP method $method is not supported');
      }

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleStripeError(e);
      rethrow; // This line won't be reached, but satisfies the analyzer
    }
  }

  /// Encodes data as application/x-www-form-urlencoded format.
  String _encodeFormData(Map<String, dynamic> data) {
    final parts = <String>[];

    void addPart(String key, dynamic value) {
      if (value == null) return;

      if (value is Map) {
        value.forEach((k, v) {
          addPart('$key[$k]', v);
        });
      } else if (value is List) {
        for (var i = 0; i < value.length; i++) {
          addPart('$key[$i]', value[i]);
        }
      } else {
        parts.add('${Uri.encodeComponent(key)}=${Uri.encodeComponent(value.toString())}');
      }
    }

    data.forEach(addPart);
    return parts.join('&');
  }

  /// Handles Stripe API errors and converts them to appropriate exceptions.
  Never _handleStripeError(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;
    final errorData = response?.data;

    // Network errors
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      throw NetworkException(
        'Request timeout while communicating with Stripe',
        code: 'timeout',
        url: error.requestOptions.uri.toString(),
        originalError: error,
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      throw NetworkException(
        'Failed to connect to Stripe API',
        code: 'connection_error',
        url: error.requestOptions.uri.toString(),
        originalError: error,
      );
    }

    // Parse Stripe error response
    if (errorData is Map<String, dynamic>) {
      final stripeError = errorData['error'] as Map<String, dynamic>?;
      final code = stripeError?['code'] as String?;
      final message = stripeError?['message'] as String? ?? 'Unknown error';
      final type = stripeError?['type'] as String?;
      final param = stripeError?['param'] as String?;

      // Authentication errors
      if (statusCode == 401) {
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
          processorName: 'Stripe',
          originalError: error,
        );
      }

      // Card/payment method errors
      if (code == 'card_declined' ||
          code == 'insufficient_funds' ||
          code == 'lost_card' ||
          code == 'stolen_card' ||
          code == 'expired_card' ||
          code == 'incorrect_cvc' ||
          code == 'processing_error' ||
          code == 'incorrect_number') {
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
            customerId: param,
            originalError: error,
          );
        } else if (message.toLowerCase().contains('subscription')) {
          throw SubscriptionNotFoundException(
            message,
            subscriptionId: param,
            originalError: error,
          );
        }
      }

      // Validation errors
      if (type == 'invalid_request_error') {
        throw ValidationException(
          message,
          code: code,
          fieldName: param,
          originalError: error,
        );
      }

      // Generic processor error
      throw ProcessorException(
        message,
        code: code,
        processorName: 'Stripe',
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

  @override
  Future<Customer> createCustomer({
    required String email,
    String? name,
    String? phone,
    Map<String, dynamic>? metadata,
  }) async {
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

    return _mapStripeCustomer(response);
  }

  @override
  Future<Customer> getCustomer(String customerId) async {
    final response = await _makeRequest('GET', '/v1/customers/$customerId');
    return _mapStripeCustomer(response);
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
      if (phone != null) 'phone': phone,
      if (metadata != null) 'metadata': metadata,
    };

    final response = await _makeRequest(
      'POST',
      '/v1/customers/$customerId',
      data: data,
    );

    return _mapStripeCustomer(response);
  }

  @override
  Future<void> deleteCustomer(String customerId) async {
    await _makeRequest('DELETE', '/v1/customers/$customerId');
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
    // Attach payment method to customer
    await _makeRequest(
      'POST',
      '/v1/payment_methods/$paymentMethodToken/attach',
      data: {'customer': customerId},
      idempotencyKey: _uuid.v4(),
    );

    // Set as default if requested
    if (setAsDefault) {
      await _makeRequest(
        'POST',
        '/v1/customers/$customerId',
        data: {
          'invoice_settings': {
            'default_payment_method': paymentMethodToken,
          },
        },
      );
    }

    final response = await _makeRequest(
      'GET',
      '/v1/payment_methods/$paymentMethodToken',
    );

    return _mapStripePaymentMethod(response, customerId, setAsDefault);
  }

  @override
  Future<PaymentMethod> getPaymentMethod(String paymentMethodId) async {
    final response = await _makeRequest(
      'GET',
      '/v1/payment_methods/$paymentMethodId',
    );

    final customerId = response['customer'] as String? ?? '';
    return _mapStripePaymentMethod(response, customerId, false);
  }

  @override
  Future<List<PaymentMethod>> listPaymentMethods(String customerId) async {
    final response = await _makeRequest(
      'GET',
      '/v1/payment_methods',
      data: {
        'customer': customerId,
        'type': 'card',
      },
    );

    final data = response['data'] as List<dynamic>? ?? [];

    // Get customer to find default payment method
    final customer = await _makeRequest('GET', '/v1/customers/$customerId');
    final defaultPmId = customer['invoice_settings']?['default_payment_method'] as String?;

    return data.map((pm) {
      final pmMap = pm as Map<String, dynamic>;
      final isDefault = pmMap['id'] == defaultPmId;
      return _mapStripePaymentMethod(pmMap, customerId, isDefault);
    }).toList();
  }

  @override
  Future<PaymentMethod> setDefaultPaymentMethod({
    required String customerId,
    required String paymentMethodId,
  }) async {
    await _makeRequest(
      'POST',
      '/v1/customers/$customerId',
      data: {
        'invoice_settings': {
          'default_payment_method': paymentMethodId,
        },
      },
    );

    final response = await _makeRequest(
      'GET',
      '/v1/payment_methods/$paymentMethodId',
    );

    return _mapStripePaymentMethod(response, customerId, true);
  }

  @override
  Future<void> removePaymentMethod(String paymentMethodId) async {
    await _makeRequest(
      'POST',
      '/v1/payment_methods/$paymentMethodId/detach',
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
    final data = <String, dynamic>{
      'customer': customerId,
      'items': [
        {'price': priceId, 'quantity': quantity},
      ],
      if (paymentMethodId != null) 'default_payment_method': paymentMethodId,
      if (trialDays != null) 'trial_period_days': trialDays,
      if (metadata != null) 'metadata': metadata,
      'expand': ['latest_invoice.payment_intent'],
    };

    final response = await _makeRequest(
      'POST',
      '/v1/subscriptions',
      data: data,
      idempotencyKey: _uuid.v4(),
    );

    return _mapStripeSubscription(response, customerId);
  }

  @override
  Future<Subscription> getSubscription(String subscriptionId) async {
    final response = await _makeRequest(
      'GET',
      '/v1/subscriptions/$subscriptionId',
      data: {'expand': ['customer']},
    );

    final customerId = _extractCustomerId(response);
    return _mapStripeSubscription(response, customerId);
  }

  @override
  Future<List<Subscription>> listSubscriptions(String customerId) async {
    final response = await _makeRequest(
      'GET',
      '/v1/subscriptions',
      data: {'customer': customerId},
    );

    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((sub) => _mapStripeSubscription(
            sub as Map<String, dynamic>, customerId))
        .toList();
  }

  @override
  Future<Subscription> updateSubscription({
    required String subscriptionId,
    String? priceId,
    int? quantity,
    Map<String, dynamic>? metadata,
  }) async {
    final data = <String, dynamic>{
      if (priceId != null)
        'items': [
          {'price': priceId, if (quantity != null) 'quantity': quantity},
        ],
      if (priceId == null && quantity != null) 'quantity': quantity,
      if (metadata != null) 'metadata': metadata,
    };

    final response = await _makeRequest(
      'POST',
      '/v1/subscriptions/$subscriptionId',
      data: data,
    );

    final customerId = _extractCustomerId(response);
    return _mapStripeSubscription(response, customerId);
  }

  @override
  Future<Subscription> cancelSubscription({
    required String subscriptionId,
    bool immediate = false,
  }) async {
    if (immediate) {
      final response = await _makeRequest(
        'DELETE',
        '/v1/subscriptions/$subscriptionId',
      );
      final customerId = _extractCustomerId(response);
      return _mapStripeSubscription(response, customerId);
    } else {
      final response = await _makeRequest(
        'POST',
        '/v1/subscriptions/$subscriptionId',
        data: {'cancel_at_period_end': true},
      );
      final customerId = _extractCustomerId(response);
      return _mapStripeSubscription(response, customerId);
    }
  }

  @override
  Future<Subscription> resumeSubscription(String subscriptionId) async {
    final response = await _makeRequest(
      'POST',
      '/v1/subscriptions/$subscriptionId',
      data: {'cancel_at_period_end': false},
    );

    final customerId = _extractCustomerId(response);
    return _mapStripeSubscription(response, customerId);
  }

  @override
  Future<Subscription> pauseSubscription(String subscriptionId) async {
    final response = await _makeRequest(
      'POST',
      '/v1/subscriptions/$subscriptionId',
      data: {
        'pause_collection': {'behavior': 'mark_uncollectible'},
      },
    );

    final customerId = _extractCustomerId(response);
    return _mapStripeSubscription(response, customerId);
  }

  @override
  Future<Subscription> swapPlan({
    required String subscriptionId,
    required String newPriceId,
    bool prorate = true,
  }) async {
    // Get current subscription to find the subscription item
    final currentSub = await _makeRequest(
      'GET',
      '/v1/subscriptions/$subscriptionId',
    );

    final items = currentSub['items']?['data'] as List<dynamic>?;
    if (items == null || items.isEmpty) {
      throw ProcessorException(
        'Subscription has no items',
        processorName: 'Stripe',
      );
    }

    final currentItem = items.first as Map<String, dynamic>;
    final itemId = currentItem['id'] as String;

    final data = <String, dynamic>{
      'items': [
        {
          'id': itemId,
          'price': newPriceId,
        },
      ],
      'proration_behavior': prorate ? 'create_prorations' : 'none',
    };

    final response = await _makeRequest(
      'POST',
      '/v1/subscriptions/$subscriptionId',
      data: data,
    );

    final customerId = _extractCustomerId(response);
    return _mapStripeSubscription(response, customerId);
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
    final data = <String, dynamic>{
      'customer': customerId,
      'amount': amount,
      'currency': currency.toLowerCase(),
      if (description != null) 'description': description,
      if (paymentMethodId != null) 'payment_method': paymentMethodId,
      if (metadata != null) 'metadata': metadata,
      'confirm': true,
      if (paymentMethodId == null) 'off_session': true,
    };

    final response = await _makeRequest(
      'POST',
      '/v1/payment_intents',
      data: data,
      idempotencyKey: _uuid.v4(),
    );

    return _mapStripeCharge(response, customerId);
  }

  @override
  Future<Charge> getCharge(String chargeId) async {
    // Try as payment intent first
    try {
      final response = await _makeRequest('GET', '/v1/payment_intents/$chargeId');
      final customerId = response['customer'] as String? ?? '';
      return _mapStripeCharge(response, customerId);
    } catch (e) {
      // Fall back to charge API
      final response = await _makeRequest('GET', '/v1/charges/$chargeId');
      final customerId = response['customer'] as String? ?? '';
      return _mapStripeChargeFromChargeObject(response, customerId);
    }
  }

  @override
  Future<List<Charge>> listCharges({
    String? customerId,
    int limit = 10,
  }) async {
    final data = <String, dynamic>{
      'limit': limit,
      if (customerId != null) 'customer': customerId,
    };

    final response = await _makeRequest('GET', '/v1/charges', data: data);
    final charges = response['data'] as List<dynamic>? ?? [];

    return charges
        .map((charge) => _mapStripeChargeFromChargeObject(
            charge as Map<String, dynamic>, customerId ?? ''))
        .toList();
  }

  @override
  Future<Charge> refundCharge({
    required String chargeId,
    int? amount,
    String? reason,
  }) async {
    final data = <String, dynamic>{
      'charge': chargeId,
      if (amount != null) 'amount': amount,
      if (reason != null) 'reason': reason,
    };

    await _makeRequest(
      'POST',
      '/v1/refunds',
      data: data,
      idempotencyKey: _uuid.v4(),
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
    if (signature != null && webhookSecret != null) {
      final payloadString = jsonEncode(payload);
      final isValid = verifyWebhookSignature(
        payload: payloadString,
        signature: signature,
        secret: webhookSecret!,
      );

      if (!isValid) {
        throw WebhookException(
          'Invalid webhook signature',
          code: 'invalid_signature',
        );
      }
    }

    final id = payload['id'] as String? ?? _uuid.v4();
    final type = payload['type'] as String?;
    final data = payload['data'] as Map<String, dynamic>? ?? {};
    final created = payload['created'] as int?;

    if (type == null) {
      throw WebhookException(
        'Webhook event type is missing',
        code: 'missing_event_type',
      );
    }

    return WebhookEvent(
      id: id,
      type: type,
      processor: ProcessorType.stripe,
      data: data,
      createdAt: created != null
          ? DateTime.fromMillisecondsSinceEpoch(created * 1000)
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
      // Stripe signature format: t=timestamp,v1=signature
      final parts = signature.split(',');
      String? timestamp;
      String? v1Signature;

      for (final part in parts) {
        final keyValue = part.split('=');
        if (keyValue.length == 2) {
          if (keyValue[0] == 't') {
            timestamp = keyValue[1];
          } else if (keyValue[0] == 'v1') {
            v1Signature = keyValue[1];
          }
        }
      }

      if (timestamp == null || v1Signature == null) {
        return false;
      }

      // Construct signed payload
      final signedPayload = '$timestamp.$payload';

      // Compute expected signature
      final hmac = Hmac(sha256, utf8.encode(secret));
      final digest = hmac.convert(utf8.encode(signedPayload));
      final expectedSignature = digest.toString();

      // Compare signatures (constant-time comparison would be ideal)
      return expectedSignature == v1Signature;
    } catch (e) {
      return false;
    }
  }

  // ==========================================================================
  // UTILITY METHODS
  // ==========================================================================

  @override
  ProcessorType get processorType => ProcessorType.stripe;

  @override
  String get name => 'Stripe';

  @override
  bool get supportsTrialPeriods => true;

  @override
  bool get supportsPlanSwapping => true;

  @override
  bool get supportsProration => true;

  @override
  Future<bool> validateConfiguration() async {
    try {
      // Make a simple API call to validate the configuration
      await _makeRequest('GET', '/v1/balance');
      return true;
    } on AuthenticationException {
      throw InvalidConfigurationException(
        'Invalid Stripe API keys',
        code: 'invalid_api_keys',
      );
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw InvalidConfigurationException(
        'Failed to validate Stripe configuration: $e',
        originalError: e,
      );
    }
  }

  // ==========================================================================
  // MAPPER METHODS
  // ==========================================================================

  /// Maps a Stripe customer response to our Customer model.
  Customer _mapStripeCustomer(Map<String, dynamic> json) {
    final created = json['created'] as int?;
    final createdAt = created != null
        ? DateTime.fromMillisecondsSinceEpoch(created * 1000)
        : DateTime.now();

    return Customer(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      processor: ProcessorType.stripe,
      processorCustomerId: json['id'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: createdAt,
      updatedAt: createdAt, // Stripe doesn't provide updated_at
    );
  }

  /// Maps a Stripe subscription response to our Subscription model.
  Subscription _mapStripeSubscription(
    Map<String, dynamic> json,
    String customerId,
  ) {
    final status = _mapStripeSubscriptionStatus(json['status'] as String?);
    final currentPeriodStart = json['current_period_start'] as int?;
    final currentPeriodEnd = json['current_period_end'] as int?;
    final trialStart = json['trial_start'] as int?;
    final trialEnd = json['trial_end'] as int?;
    final canceledAt = json['canceled_at'] as int?;
    final cancelAtPeriodEnd = json['cancel_at_period_end'] as bool? ?? false;

    // Extract price and product IDs
    final items = json['items']?['data'] as List<dynamic>?;
    final firstItem = items?.isNotEmpty == true
        ? items!.first as Map<String, dynamic>
        : null;
    final price = firstItem?['price'] as Map<String, dynamic>?;
    final priceId = price?['id'] as String? ?? '';
    final productId = price?['product'] as String? ?? '';
    final quantity = firstItem?['quantity'] as int? ?? 1;

    return Subscription(
      id: json['id'] as String,
      customerId: customerId,
      status: status,
      priceId: priceId,
      productId: productId,
      currentPeriodStart: currentPeriodStart != null
          ? DateTime.fromMillisecondsSinceEpoch(currentPeriodStart * 1000)
          : DateTime.now(),
      currentPeriodEnd: currentPeriodEnd != null
          ? DateTime.fromMillisecondsSinceEpoch(currentPeriodEnd * 1000)
          : DateTime.now(),
      trialStart: trialStart != null
          ? DateTime.fromMillisecondsSinceEpoch(trialStart * 1000)
          : null,
      trialEnd: trialEnd != null
          ? DateTime.fromMillisecondsSinceEpoch(trialEnd * 1000)
          : null,
      canceledAt: canceledAt != null
          ? DateTime.fromMillisecondsSinceEpoch(canceledAt * 1000)
          : null,
      cancelAtPeriodEnd: cancelAtPeriodEnd,
      quantity: quantity,
      processor: ProcessorType.stripe,
      processorSubscriptionId: json['id'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Maps a Stripe payment intent to our Charge model.
  Charge _mapStripeCharge(Map<String, dynamic> json, String customerId) {
    final status = _mapStripeChargeStatus(json['status'] as String?);
    final created = json['created'] as int?;
    final amount = json['amount'] as int? ?? 0;
    final amountRefunded = json['amount_refunded'] as int? ?? 0;

    return Charge(
      id: json['id'] as String,
      customerId: customerId,
      amount: amount,
      currency: json['currency'] as String? ?? 'usd',
      status: status,
      description: json['description'] as String?,
      receiptUrl: json['charges']?['data']?[0]?['receipt_url'] as String?,
      refunded: amountRefunded > 0,
      refundedAmount: amountRefunded > 0 ? amountRefunded : null,
      processorChargeId: json['id'] as String,
      processor: ProcessorType.stripe,
      createdAt: created != null
          ? DateTime.fromMillisecondsSinceEpoch(created * 1000)
          : DateTime.now(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Maps a Stripe charge object to our Charge model.
  Charge _mapStripeChargeFromChargeObject(
    Map<String, dynamic> json,
    String customerId,
  ) {
    final status = json['paid'] == true
        ? ChargeStatus.succeeded
        : json['refunded'] == true
            ? ChargeStatus.refunded
            : ChargeStatus.failed;
    final created = json['created'] as int?;
    final amount = json['amount'] as int? ?? 0;
    final amountRefunded = json['amount_refunded'] as int? ?? 0;

    return Charge(
      id: json['id'] as String,
      customerId: customerId,
      amount: amount,
      currency: json['currency'] as String? ?? 'usd',
      status: status,
      description: json['description'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      refunded: json['refunded'] as bool? ?? false,
      refundedAmount: amountRefunded > 0 ? amountRefunded : null,
      processorChargeId: json['id'] as String,
      processor: ProcessorType.stripe,
      createdAt: created != null
          ? DateTime.fromMillisecondsSinceEpoch(created * 1000)
          : DateTime.now(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Maps a Stripe payment method to our PaymentMethod model.
  PaymentMethod _mapStripePaymentMethod(
    Map<String, dynamic> json,
    String customerId,
    bool isDefault,
  ) {
    final type = _mapStripePaymentMethodType(json['type'] as String?);
    final card = json['card'] as Map<String, dynamic>?;
    final billingDetails = json['billing_details'] as Map<String, dynamic>?;

    return PaymentMethod(
      id: json['id'] as String,
      customerId: customerId,
      type: type,
      last4: card?['last4'] as String?,
      brand: card?['brand'] as String?,
      expiryMonth: card?['exp_month'] as int?,
      expiryYear: card?['exp_year'] as int?,
      isDefault: isDefault,
      billingDetails: billingDetails != null
          ? BillingDetails(
              name: billingDetails['name'] as String?,
              email: billingDetails['email'] as String?,
              phone: billingDetails['phone'] as String?,
              address: billingDetails['address'] != null
                  ? Address(
                      line1: billingDetails['address']['line1'] as String?,
                      line2: billingDetails['address']['line2'] as String?,
                      city: billingDetails['address']['city'] as String?,
                      state: billingDetails['address']['state'] as String?,
                      postalCode: billingDetails['address']['postal_code']
                          as String?,
                      country: billingDetails['address']['country'] as String?,
                    )
                  : null,
            )
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Maps Stripe subscription status to our enum.
  SubscriptionStatus _mapStripeSubscriptionStatus(String? status) {
    switch (status) {
      case 'active':
        return SubscriptionStatus.active;
      case 'trialing':
        return SubscriptionStatus.trialing;
      case 'past_due':
        return SubscriptionStatus.pastDue;
      case 'canceled':
        return SubscriptionStatus.canceled;
      case 'incomplete':
      case 'incomplete_expired':
        return SubscriptionStatus.incomplete;
      case 'paused':
        return SubscriptionStatus.paused;
      default:
        return SubscriptionStatus.incomplete;
    }
  }

  /// Maps Stripe payment intent status to our ChargeStatus enum.
  ChargeStatus _mapStripeChargeStatus(String? status) {
    switch (status) {
      case 'succeeded':
        return ChargeStatus.succeeded;
      case 'processing':
      case 'requires_action':
      case 'requires_capture':
      case 'requires_confirmation':
      case 'requires_payment_method':
        return ChargeStatus.pending;
      case 'canceled':
      case 'failed':
        return ChargeStatus.failed;
      default:
        return ChargeStatus.pending;
    }
  }

  /// Maps Stripe payment method type to our enum.
  PaymentMethodType _mapStripePaymentMethodType(String? type) {
    switch (type) {
      case 'card':
        return PaymentMethodType.card;
      case 'us_bank_account':
      case 'sepa_debit':
        return PaymentMethodType.bankAccount;
      case 'paypal':
        return PaymentMethodType.paypal;
      default:
        return PaymentMethodType.card;
    }
  }

  /// Extracts customer ID from a subscription response.
  String _extractCustomerId(Map<String, dynamic> response) {
    final customer = response['customer'];
    if (customer is String) {
      return customer;
    } else if (customer is Map<String, dynamic>) {
      return customer['id'] as String;
    }
    return '';
  }
}
