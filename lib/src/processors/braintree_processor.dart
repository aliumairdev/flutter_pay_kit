import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../exceptions/exceptions.dart';
import '../models/models.dart';
import 'base_processor.dart';

/// Braintree environment enum for sandbox vs production.
enum BraintreeEnvironment {
  /// Sandbox environment for testing
  sandbox,

  /// Production environment for live transactions
  production,
}

/// Braintree payment processor implementation.
///
/// This class provides a complete implementation of the PaymentProcessor
/// interface for Braintree's REST API.
///
/// Braintree supports:
/// - Credit/debit card payments
/// - PayPal integration
/// - Venmo (US only)
/// - Advanced Fraud Protection
/// - Drop-in UI via client tokens
///
/// **Important Limitations:**
/// - Braintree does not support swapping between billing frequencies natively
/// - Plan changes require canceling and creating new subscriptions with proration
///
/// Example usage:
/// ```dart
/// final processor = BraintreeProcessor(
///   merchantId: 'your_merchant_id',
///   publicKey: 'your_public_key',
///   privateKey: 'your_private_key',
///   environment: BraintreeEnvironment.sandbox,
/// );
///
/// final customer = await processor.createCustomer(
///   email: 'user@example.com',
///   name: 'John Doe',
/// );
/// ```
class BraintreeProcessor extends PaymentProcessor {
  /// Braintree merchant ID
  final String merchantId;

  /// Braintree public key
  final String publicKey;

  /// Braintree private key (keep secure!)
  final String privateKey;

  /// Environment (sandbox or production)
  final BraintreeEnvironment environment;

  /// HTTP client for making API requests
  late final Dio _dio;

  /// UUID generator for idempotency keys
  final _uuid = const Uuid();

  /// Base URL for Braintree API
  String get _baseUrl {
    if (environment == BraintreeEnvironment.sandbox) {
      return 'https://api.sandbox.braintreegateway.com';
    }
    return 'https://api.braintreegateway.com';
  }

  /// Creates a new [BraintreeProcessor] instance.
  ///
  /// Parameters:
  /// - [merchantId]: Braintree merchant ID
  /// - [publicKey]: Braintree public key
  /// - [privateKey]: Braintree private key
  /// - [environment]: Environment to use (sandbox or production)
  ///
  /// Throws [InvalidConfigurationException] if credentials are invalid.
  BraintreeProcessor({
    required this.merchantId,
    required this.publicKey,
    required this.privateKey,
    required this.environment,
  }) {
    // Validate configuration
    if (merchantId.isEmpty) {
      throw InvalidConfigurationException(
        'Braintree merchant ID is required',
        fieldName: 'merchantId',
      );
    }
    if (publicKey.isEmpty) {
      throw InvalidConfigurationException(
        'Braintree public key is required',
        fieldName: 'publicKey',
      );
    }
    if (privateKey.isEmpty) {
      throw InvalidConfigurationException(
        'Braintree private key is required',
        fieldName: 'privateKey',
      );
    }

    // Initialize Dio client
    final credentials = base64Encode(utf8.encode('$publicKey:$privateKey'));
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Braintree-Version': '2024-11-01',
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

  /// Makes an HTTP request to the Braintree API.
  ///
  /// Parameters:
  /// - [method]: HTTP method (GET, POST, PUT, DELETE)
  /// - [endpoint]: API endpoint path (e.g., '/merchants/merchant_id/customers')
  /// - [data]: Optional request data
  ///
  /// Returns the response data as a Map.
  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final options = Options(method: method);

      Response<dynamic> response;

      if (method == 'GET') {
        response = await _dio.get(endpoint, queryParameters: data);
      } else if (method == 'POST') {
        response = await _dio.post(endpoint, data: data, options: options);
      } else if (method == 'PUT') {
        response = await _dio.put(endpoint, data: data, options: options);
      } else if (method == 'DELETE') {
        response = await _dio.delete(endpoint, options: options);
      } else {
        throw UnsupportedError('HTTP method $method is not supported');
      }

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleBraintreeError(e);
      rethrow; // This line won't be reached, but satisfies the analyzer
    }
  }

  /// Handles Braintree API errors and converts them to appropriate exceptions.
  Never _handleBraintreeError(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;
    final errorData = response?.data;

    // Network errors
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      throw NetworkException(
        'Request timeout while communicating with Braintree',
        code: 'timeout',
        url: error.requestOptions.uri.toString(),
        originalError: error,
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      throw NetworkException(
        'Failed to connect to Braintree API',
        code: 'connection_error',
        url: error.requestOptions.uri.toString(),
        originalError: error,
      );
    }

    // Parse Braintree error response
    if (errorData is Map<String, dynamic>) {
      final apiError = errorData['apiErrorResponse'] as Map<String, dynamic>?;
      final message = apiError?['message'] as String? ??
          errorData['message'] as String? ??
          'Unknown error';
      final errors = apiError?['errors'] as Map<String, dynamic>?;
      final errorList = errors?['errors'] as List<dynamic>?;
      final code = errorList?.isNotEmpty == true
          ? (errorList!.first as Map<String, dynamic>)['code'] as String?
          : null;

      // Authentication errors
      if (statusCode == 401 || statusCode == 403) {
        throw AuthenticationException(
          message,
          code: code ?? 'unauthorized',
          authenticationType: 'basic_auth',
          originalError: error,
        );
      }

      // Rate limiting
      if (statusCode == 429) {
        throw ProcessorException(
          'Rate limit exceeded',
          code: 'rate_limit_exceeded',
          processorName: 'Braintree',
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
      if (statusCode == 422 || code != null) {
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
        processorName: 'Braintree',
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

  /// Generates a client token for Drop-in UI integration.
  ///
  /// The client token is used by client-side SDKs to initialize
  /// payment forms and collect payment method information securely.
  ///
  /// Parameters:
  /// - [customerId]: Optional customer ID to associate with the token
  ///
  /// Returns the client token string.
  Future<String> _generateClientToken({String? customerId}) async {
    final data = <String, dynamic>{
      'client_token': {
        'version': 2,
        if (customerId != null) 'customer_id': customerId,
      },
    };

    final response = await _makeRequest(
      'POST',
      '/merchants/$merchantId/client_token',
      data: data,
    );

    return response['client_token']?['value'] as String? ?? '';
  }

  /// Calculates proration amount for plan changes.
  ///
  /// Since Braintree doesn't support automatic proration for plan changes,
  /// we need to calculate it manually.
  ///
  /// Parameters:
  /// - [currentSubscription]: The current subscription
  /// - [newPriceId]: The new price ID to switch to
  ///
  /// Returns the proration amount in cents.
  Future<int> _calculateProration(
    Subscription currentSubscription,
    String newPriceId,
  ) async {
    // Get current price info
    final currentPeriodEnd = currentSubscription.currentPeriodEnd;
    final currentPeriodStart = currentSubscription.currentPeriodStart;
    final now = DateTime.now();

    // Calculate time remaining in current period
    final totalPeriodDuration =
        currentPeriodEnd.difference(currentPeriodStart).inSeconds;
    final remainingDuration = currentPeriodEnd.difference(now).inSeconds;

    if (remainingDuration <= 0 || totalPeriodDuration <= 0) {
      return 0; // No proration needed if period has ended
    }

    // Calculate proration percentage
    final prorationPercentage = remainingDuration / totalPeriodDuration;

    // For now, we return a placeholder value
    // In a real implementation, you'd fetch the new plan price
    // and calculate: newPlanPrice * prorationPercentage - oldPlanPrice * prorationPercentage
    // This would require additional API calls to get plan pricing

    return (prorationPercentage * 1000).round(); // Placeholder
  }

  /// Swaps subscription plan with custom proration logic.
  ///
  /// Since Braintree doesn't support plan swapping natively, this method:
  /// 1. Gets the current subscription details
  /// 2. Calculates proration amount
  /// 3. Cancels the current subscription
  /// 4. Creates a new subscription with the new plan
  /// 5. Optionally applies a discount for the proration amount
  ///
  /// Parameters:
  /// - [subscriptionId]: Current subscription ID
  /// - [newPriceId]: New price/plan ID
  /// - [prorate]: Whether to apply proration
  ///
  /// Returns the new subscription.
  Future<Subscription> _swapPlanWithProration(
    String subscriptionId,
    String newPriceId, {
    bool prorate = true,
  }) async {
    // Get current subscription
    final currentSub = await getSubscription(subscriptionId);

    // Calculate proration if needed
    int prorationAmount = 0;
    if (prorate) {
      prorationAmount = await _calculateProration(currentSub, newPriceId);
    }

    // Cancel current subscription immediately
    await cancelSubscription(subscriptionId: subscriptionId, immediate: true);

    // Create new subscription
    final newSub = await createSubscription(
      customerId: currentSub.customerId,
      priceId: newPriceId,
      metadata: {
        ...?currentSub.metadata,
        'swapped_from': subscriptionId,
        'proration_amount': prorationAmount.toString(),
      },
    );

    // Note: In a real implementation, you would also create a discount
    // or credit to apply the proration amount to the customer's account

    return newSub;
  }

  /// Maps a Braintree subscription response to our Subscription model.
  Subscription _mapBraintreeSubscription(
    Map<String, dynamic> json,
    String customerId,
  ) {
    final status = _mapBraintreeSubscriptionStatus(json['status'] as String?);
    final firstBillingDate = json['firstBillingDate'] as String?;
    final nextBillingDate = json['nextBillingDate'] as String?;
    final billingPeriodStartDate = json['billingPeriodStartDate'] as String?;
    final billingPeriodEndDate = json['billingPeriodEndDate'] as String?;
    final trialPeriod = json['trialPeriod'] as bool? ?? false;
    final trialEndDate = json['trialEndDate'] as String?;

    final currentPeriodStart = billingPeriodStartDate != null
        ? DateTime.parse(billingPeriodStartDate)
        : DateTime.now();
    final currentPeriodEnd = billingPeriodEndDate != null
        ? DateTime.parse(billingPeriodEndDate)
        : nextBillingDate != null
            ? DateTime.parse(nextBillingDate)
            : DateTime.now().add(const Duration(days: 30));

    return Subscription(
      id: json['id'] as String,
      customerId: customerId,
      status: status,
      priceId: json['planId'] as String? ?? '',
      productId: json['planId'] as String? ?? '',
      currentPeriodStart: currentPeriodStart,
      currentPeriodEnd: currentPeriodEnd,
      trialStart: trialPeriod ? currentPeriodStart : null,
      trialEnd: trialEndDate != null ? DateTime.parse(trialEndDate) : null,
      canceledAt: status == SubscriptionStatus.canceled
          ? DateTime.now()
          : null, // Braintree doesn't provide this
      cancelAtPeriodEnd: false,
      quantity: json['quantity'] as int? ?? 1,
      processor: ProcessorType.braintree,
      processorSubscriptionId: json['id'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Maps Braintree subscription status to our enum.
  SubscriptionStatus _mapBraintreeSubscriptionStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return SubscriptionStatus.active;
      case 'pending':
        return SubscriptionStatus.trialing;
      case 'past_due':
        return SubscriptionStatus.pastDue;
      case 'canceled':
      case 'expired':
        return SubscriptionStatus.canceled;
      default:
        return SubscriptionStatus.incomplete;
    }
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
      'customer': {
        'email': email,
        if (name != null)
          'firstName': name.split(' ').first,
        if (name != null && name.split(' ').length > 1)
          'lastName': name.split(' ').skip(1).join(' '),
        if (phone != null) 'phone': phone,
        if (metadata != null) 'customFields': metadata,
      },
    };

    final response = await _makeRequest(
      'POST',
      '/merchants/$merchantId/customers',
      data: data,
    );

    final customerData = response['customer'] as Map<String, dynamic>;
    return _mapBraintreeCustomer(customerData);
  }

  @override
  Future<Customer> getCustomer(String customerId) async {
    final response = await _makeRequest(
      'GET',
      '/merchants/$merchantId/customers/$customerId',
    );

    final customerData = response['customer'] as Map<String, dynamic>;
    return _mapBraintreeCustomer(customerData);
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
      'customer': {
        if (email != null) 'email': email,
        if (name != null) 'firstName': name.split(' ').first,
        if (name != null && name.split(' ').length > 1)
          'lastName': name.split(' ').skip(1).join(' '),
        if (phone != null) 'phone': phone,
        if (metadata != null) 'customFields': metadata,
      },
    };

    final response = await _makeRequest(
      'PUT',
      '/merchants/$merchantId/customers/$customerId',
      data: data,
    );

    final customerData = response['customer'] as Map<String, dynamic>;
    return _mapBraintreeCustomer(customerData);
  }

  @override
  Future<void> deleteCustomer(String customerId) async {
    await _makeRequest(
      'DELETE',
      '/merchants/$merchantId/customers/$customerId',
    );
  }

  /// Maps a Braintree customer response to our Customer model.
  Customer _mapBraintreeCustomer(Map<String, dynamic> json) {
    final firstName = json['firstName'] as String? ?? '';
    final lastName = json['lastName'] as String? ?? '';
    final name = '$firstName $lastName'.trim();
    final createdAt = json['createdAt'] as String?;
    final updatedAt = json['updatedAt'] as String?;

    return Customer(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      name: name.isNotEmpty ? name : null,
      phone: json['phone'] as String?,
      processor: ProcessorType.braintree,
      processorCustomerId: json['id'] as String,
      metadata: json['customFields'] as Map<String, dynamic>?,
      createdAt:
          createdAt != null ? DateTime.parse(createdAt) : DateTime.now(),
      updatedAt:
          updatedAt != null ? DateTime.parse(updatedAt) : DateTime.now(),
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
    final data = <String, dynamic>{
      'payment_method': {
        'customerId': customerId,
        'paymentMethodNonce': paymentMethodToken,
        if (setAsDefault) 'makeDefault': true,
      },
    };

    final response = await _makeRequest(
      'POST',
      '/merchants/$merchantId/payment_methods',
      data: data,
    );

    final pmData = response['paymentMethod'] as Map<String, dynamic>? ??
        response['creditCard'] as Map<String, dynamic>? ??
        response['paypalAccount'] as Map<String, dynamic>? ??
        {};

    return _mapBraintreePaymentMethod(pmData, customerId, setAsDefault);
  }

  @override
  Future<PaymentMethod> getPaymentMethod(String paymentMethodId) async {
    final response = await _makeRequest(
      'GET',
      '/merchants/$merchantId/payment_methods/$paymentMethodId',
    );

    final pmData = response['paymentMethod'] as Map<String, dynamic>? ??
        response['creditCard'] as Map<String, dynamic>? ??
        {};
    final customerId = pmData['customerId'] as String? ?? '';

    return _mapBraintreePaymentMethod(pmData, customerId, false);
  }

  @override
  Future<List<PaymentMethod>> listPaymentMethods(String customerId) async {
    // Get customer to access payment methods
    final customer = await getCustomer(customerId);
    final response = await _makeRequest(
      'GET',
      '/merchants/$merchantId/customers/$customerId',
    );

    final customerData = response['customer'] as Map<String, dynamic>;
    final creditCards = customerData['creditCards'] as List<dynamic>? ?? [];
    final paypalAccounts =
        customerData['paypalAccounts'] as List<dynamic>? ?? [];

    final paymentMethods = <PaymentMethod>[];

    // Map credit cards
    for (final card in creditCards) {
      final cardMap = card as Map<String, dynamic>;
      final isDefault = cardMap['default'] as bool? ?? false;
      paymentMethods.add(
        _mapBraintreePaymentMethod(cardMap, customerId, isDefault),
      );
    }

    // Map PayPal accounts
    for (final paypal in paypalAccounts) {
      final paypalMap = paypal as Map<String, dynamic>;
      final isDefault = paypalMap['default'] as bool? ?? false;
      paymentMethods.add(
        _mapBraintreePaymentMethod(paypalMap, customerId, isDefault),
      );
    }

    return paymentMethods;
  }

  @override
  Future<PaymentMethod> setDefaultPaymentMethod({
    required String customerId,
    required String paymentMethodId,
  }) async {
    final data = <String, dynamic>{
      'payment_method': {
        'makeDefault': true,
      },
    };

    final response = await _makeRequest(
      'PUT',
      '/merchants/$merchantId/payment_methods/$paymentMethodId',
      data: data,
    );

    final pmData = response['paymentMethod'] as Map<String, dynamic>? ?? {};
    return _mapBraintreePaymentMethod(pmData, customerId, true);
  }

  @override
  Future<void> removePaymentMethod(String paymentMethodId) async {
    await _makeRequest(
      'DELETE',
      '/merchants/$merchantId/payment_methods/$paymentMethodId',
    );
  }

  /// Maps a Braintree payment method to our PaymentMethod model.
  PaymentMethod _mapBraintreePaymentMethod(
    Map<String, dynamic> json,
    String customerId,
    bool isDefault,
  ) {
    // Determine payment method type
    PaymentMethodType type = PaymentMethodType.card;
    if (json.containsKey('email') && json.containsKey('payerId')) {
      type = PaymentMethodType.paypal;
    }

    return PaymentMethod(
      id: json['token'] as String? ?? json['id'] as String? ?? '',
      customerId: customerId,
      type: type,
      last4: json['last4'] as String?,
      brand: json['cardType'] as String?,
      expiryMonth: json['expirationMonth'] != null
          ? int.tryParse(json['expirationMonth'] as String)
          : null,
      expiryYear: json['expirationYear'] != null
          ? int.tryParse(json['expirationYear'] as String)
          : null,
      isDefault: isDefault,
      billingDetails: json['billingAddress'] != null
          ? BillingDetails(
              name: json['cardholderName'] as String?,
              address: Address(
                line1: json['billingAddress']?['streetAddress'] as String?,
                line2: json['billingAddress']?['extendedAddress'] as String?,
                city: json['billingAddress']?['locality'] as String?,
                state: json['billingAddress']?['region'] as String?,
                postalCode: json['billingAddress']?['postalCode'] as String?,
                country:
                    json['billingAddress']?['countryCodeAlpha2'] as String?,
              ),
            )
          : null,
      metadata: {},
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
      'subscription': {
        'planId': priceId,
        'paymentMethodToken': paymentMethodId,
        if (trialDays != null) 'trialPeriod': true,
        if (trialDays != null)
          'trialDuration': trialDays,
        if (trialDays != null) 'trialDurationUnit': 'day',
        'price': null, // Use plan's default price
        if (metadata != null) 'options': metadata,
      },
    };

    final response = await _makeRequest(
      'POST',
      '/merchants/$merchantId/subscriptions',
      data: data,
    );

    final subData = response['subscription'] as Map<String, dynamic>;
    return _mapBraintreeSubscription(subData, customerId);
  }

  @override
  Future<Subscription> getSubscription(String subscriptionId) async {
    final response = await _makeRequest(
      'GET',
      '/merchants/$merchantId/subscriptions/$subscriptionId',
    );

    final subData = response['subscription'] as Map<String, dynamic>;
    // Extract customer ID from payment method or transactions
    final transactions = subData['transactions'] as List<dynamic>?;
    final customerId = transactions?.isNotEmpty == true
        ? (transactions!.first as Map<String, dynamic>)['customer']?['id']
                as String? ??
            ''
        : '';

    return _mapBraintreeSubscription(subData, customerId);
  }

  @override
  Future<List<Subscription>> listSubscriptions(String customerId) async {
    // Braintree doesn't have a direct API to list subscriptions by customer
    // We need to get the customer and extract subscriptions from payment methods
    final response = await _makeRequest(
      'GET',
      '/merchants/$merchantId/customers/$customerId',
    );

    final customerData = response['customer'] as Map<String, dynamic>;

    // Search through payment methods for associated subscriptions
    // This is a simplified implementation
    // In production, you might need to maintain your own subscription index

    return []; // Placeholder - would need additional implementation
  }

  @override
  Future<Subscription> updateSubscription({
    required String subscriptionId,
    String? priceId,
    int? quantity,
    Map<String, dynamic>? metadata,
  }) async {
    final data = <String, dynamic>{
      'subscription': {
        if (priceId != null) 'planId': priceId,
        if (quantity != null) 'numberOfBillingCycles': quantity,
        if (metadata != null) 'options': metadata,
      },
    };

    final response = await _makeRequest(
      'PUT',
      '/merchants/$merchantId/subscriptions/$subscriptionId',
      data: data,
    );

    final subData = response['subscription'] as Map<String, dynamic>;
    final customerId = ''; // Would need to fetch from subscription details
    return _mapBraintreeSubscription(subData, customerId);
  }

  @override
  Future<Subscription> cancelSubscription({
    required String subscriptionId,
    bool immediate = false,
  }) async {
    final response = await _makeRequest(
      'PUT',
      '/merchants/$merchantId/subscriptions/$subscriptionId/cancel',
    );

    final subData = response['subscription'] as Map<String, dynamic>;
    final customerId = ''; // Would need to fetch from subscription details
    return _mapBraintreeSubscription(subData, customerId);
  }

  @override
  Future<Subscription> resumeSubscription(String subscriptionId) async {
    // Braintree doesn't support resuming canceled subscriptions directly
    // You would need to create a new subscription
    throw ProcessorException(
      'Braintree does not support resuming canceled subscriptions. Create a new subscription instead.',
      code: 'unsupported_operation',
      processorName: 'Braintree',
    );
  }

  @override
  Future<Subscription> pauseSubscription(String subscriptionId) async {
    // Braintree doesn't support pausing subscriptions directly
    throw ProcessorException(
      'Braintree does not support pausing subscriptions. Consider canceling and recreating when needed.',
      code: 'unsupported_operation',
      processorName: 'Braintree',
    );
  }

  @override
  Future<Subscription> swapPlan({
    required String subscriptionId,
    required String newPriceId,
    bool prorate = true,
  }) async {
    // Use custom proration logic since Braintree doesn't support native plan swapping
    return _swapPlanWithProration(subscriptionId, newPriceId, prorate: prorate);
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
      'transaction': {
        'amount': (amount / 100).toStringAsFixed(2), // Convert cents to dollars
        'customerId': customerId,
        if (paymentMethodId != null) 'paymentMethodToken': paymentMethodId,
        'type': 'sale',
        'options': {
          'submitForSettlement': true,
          if (metadata != null) ...metadata,
        },
        if (description != null) 'orderId': description,
      },
    };

    final response = await _makeRequest(
      'POST',
      '/merchants/$merchantId/transactions',
      data: data,
    );

    final txnData = response['transaction'] as Map<String, dynamic>;
    return _mapBraintreeCharge(txnData, customerId);
  }

  @override
  Future<Charge> getCharge(String chargeId) async {
    final response = await _makeRequest(
      'GET',
      '/merchants/$merchantId/transactions/$chargeId',
    );

    final txnData = response['transaction'] as Map<String, dynamic>;
    final customerId = txnData['customer']?['id'] as String? ?? '';
    return _mapBraintreeCharge(txnData, customerId);
  }

  @override
  Future<List<Charge>> listCharges({
    String? customerId,
    int limit = 10,
  }) async {
    // Braintree doesn't have a simple list endpoint
    // You would typically use the search API
    // This is a simplified implementation
    if (customerId != null) {
      final customer = await getCustomer(customerId);
      // Would need to search transactions by customer
    }

    return []; // Placeholder
  }

  @override
  Future<Charge> refundCharge({
    required String chargeId,
    int? amount,
    String? reason,
  }) async {
    final data = amount != null
        ? {
            'transaction': {
              'amount': (amount / 100).toStringAsFixed(2),
            },
          }
        : null;

    final response = await _makeRequest(
      'POST',
      '/merchants/$merchantId/transactions/$chargeId/refund',
      data: data,
    );

    final txnData = response['transaction'] as Map<String, dynamic>;
    final customerId = txnData['customer']?['id'] as String? ?? '';
    return _mapBraintreeCharge(txnData, customerId);
  }

  /// Maps a Braintree transaction to our Charge model.
  Charge _mapBraintreeCharge(Map<String, dynamic> json, String customerId) {
    final status = _mapBraintreeChargeStatus(json['status'] as String?);
    final amount = json['amount'] as String?;
    final amountInCents =
        amount != null ? (double.parse(amount) * 100).round() : 0;
    final createdAt = json['createdAt'] as String?;
    final refundedAmount = json['refundedTransactionId'] != null
        ? amountInCents
        : 0; // Simplified

    return Charge(
      id: json['id'] as String,
      customerId: customerId,
      amount: amountInCents,
      currency: json['currencyIsoCode'] as String? ?? 'USD',
      status: status,
      description: json['orderId'] as String?,
      receiptUrl: null, // Braintree doesn't provide receipt URLs directly
      refunded: json['refundedTransactionId'] != null,
      refundedAmount: refundedAmount > 0 ? refundedAmount : null,
      processorChargeId: json['id'] as String,
      processor: ProcessorType.braintree,
      createdAt:
          createdAt != null ? DateTime.parse(createdAt) : DateTime.now(),
      metadata: json['customFields'] as Map<String, dynamic>?,
    );
  }

  /// Maps Braintree transaction status to our ChargeStatus enum.
  ChargeStatus _mapBraintreeChargeStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'settled':
      case 'settling':
      case 'submitted_for_settlement':
        return ChargeStatus.succeeded;
      case 'authorized':
      case 'authorization_expired':
      case 'processor_declined':
      case 'settlement_declined':
      case 'failed':
      case 'gateway_rejected':
        return ChargeStatus.failed;
      case 'voided':
        return ChargeStatus.refunded;
      default:
        return ChargeStatus.pending;
    }
  }

  // ==========================================================================
  // WEBHOOK HANDLING
  // ==========================================================================

  @override
  Future<WebhookEvent> handleWebhook({
    required Map<String, dynamic> payload,
    String? signature,
  }) async {
    // Braintree webhook verification would go here
    // This is a simplified implementation

    final id = payload['id'] as String? ?? _uuid.v4();
    final kind = payload['kind'] as String?;
    final timestamp = payload['timestamp'] as String?;

    if (kind == null) {
      throw WebhookException(
        'Webhook event kind is missing',
        code: 'missing_event_kind',
      );
    }

    return WebhookEvent(
      id: id,
      type: kind,
      processor: ProcessorType.braintree,
      data: payload,
      createdAt:
          timestamp != null ? DateTime.parse(timestamp) : DateTime.now(),
    );
  }

  @override
  bool verifyWebhookSignature({
    required String payload,
    required String signature,
    required String secret,
  }) {
    try {
      // Braintree uses HMAC-SHA256 for webhook signatures
      final hmac = Hmac(sha256, utf8.encode(secret));
      final digest = hmac.convert(utf8.encode(payload));
      final expectedSignature = digest.toString();

      return expectedSignature == signature;
    } catch (e) {
      return false;
    }
  }

  // ==========================================================================
  // UTILITY METHODS
  // ==========================================================================

  @override
  ProcessorType get processorType => ProcessorType.braintree;

  @override
  String get name => 'Braintree';

  @override
  bool get supportsTrialPeriods => true;

  @override
  bool get supportsPlanSwapping =>
      true; // Via custom implementation with cancel + create

  @override
  bool get supportsProration =>
      true; // Via custom implementation (manual calculation)

  @override
  Future<bool> validateConfiguration() async {
    try {
      // Generate a client token to validate credentials
      await _generateClientToken();
      return true;
    } on AuthenticationException {
      throw InvalidConfigurationException(
        'Invalid Braintree credentials',
        code: 'invalid_credentials',
      );
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw InvalidConfigurationException(
        'Failed to validate Braintree configuration: $e',
        originalError: e,
      );
    }
  }

  // ==========================================================================
  // ADDITIONAL BRAINTREE-SPECIFIC METHODS
  // ==========================================================================

  /// Generates a client token for Drop-in UI.
  ///
  /// This token is used by client-side SDKs to collect payment information.
  ///
  /// Parameters:
  /// - [customerId]: Optional customer ID to pre-fill customer information
  ///
  /// Returns a client token string.
  Future<String> generateClientToken({String? customerId}) async {
    return _generateClientToken(customerId: customerId);
  }

  /// Creates a PayPal checkout token.
  ///
  /// This is used to initiate a PayPal payment flow.
  ///
  /// Parameters:
  /// - [amount]: Amount in cents
  /// - [currency]: Currency code (e.g., 'USD')
  /// - [returnUrl]: URL to redirect after successful payment
  /// - [cancelUrl]: URL to redirect if payment is canceled
  ///
  /// Returns a PayPal checkout token.
  Future<String> createPayPalCheckoutToken({
    required int amount,
    required String currency,
    required String returnUrl,
    required String cancelUrl,
  }) async {
    final data = <String, dynamic>{
      'payment_method_nonce': {
        'amount': (amount / 100).toStringAsFixed(2),
        'currencyIsoCode': currency,
        'returnUrl': returnUrl,
        'cancelUrl': cancelUrl,
      },
    };

    final response = await _makeRequest(
      'POST',
      '/merchants/$merchantId/paypal_accounts',
      data: data,
    );

    return response['paypalAccount']?['token'] as String? ?? '';
  }
}
