import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:riverpod/riverpod.dart';

import '../exceptions/exceptions.dart';
import '../models/models.dart';
import '../processors/base_processor.dart';
import 'storage.dart';

/// Service layer that handles business logic and state management for payments.
///
/// This service wraps a [PaymentProcessor] and provides:
/// - High-level business methods for common payment operations
/// - Caching strategy to minimize API calls
/// - Error handling and retry logic for transient failures
/// - State management integration with Riverpod
///
/// Example usage:
/// ```dart
/// final service = PaymentService(
///   processor: StripeProcessor(apiKey: 'sk_...'),
///   storage: SharedPreferencesStorage(
///     getPreferences: () => SharedPreferences.getInstance(),
///   ),
/// );
///
/// // Initialize with customer data
/// await service.initialize(
///   email: 'user@example.com',
///   name: 'John Doe',
/// );
///
/// // Subscribe to a plan
/// final subscription = await service.subscribe(
///   priceId: 'price_premium',
///   trialDays: 14,
/// );
///
/// // Check subscription status
/// final hasActive = await service.hasActiveSubscription();
/// ```
class PaymentService {
  final PaymentProcessor _processor;
  final Storage _storage;

  // Cache keys
  static const String _customerIdKey = 'payment_service_customer_id';
  static const String _customerDataKey = 'payment_service_customer_data';
  static const String _subscriptionsKey = 'payment_service_subscriptions';
  static const String _defaultPaymentMethodKey =
      'payment_service_default_payment_method';

  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  /// Creates a [PaymentService] instance.
  ///
  /// Parameters:
  /// - [processor]: The payment processor to use for API calls
  /// - [storage]: Storage implementation for caching data
  PaymentService({
    required PaymentProcessor processor,
    required Storage storage,
  })  : _processor = processor,
        _storage = storage;

  // ==========================================================================
  // INITIALIZATION
  // ==========================================================================

  /// Initializes the payment service with customer information.
  ///
  /// This method either creates a new customer or retrieves an existing one.
  /// Customer data is cached locally to minimize API calls.
  ///
  /// Parameters:
  /// - [email]: Customer's email address (required)
  /// - [name]: Customer's full name (optional)
  /// - [phone]: Customer's phone number (optional)
  ///
  /// Throws:
  /// - [ValidationException] if email is invalid
  /// - [PaymentException] if customer creation fails
  /// - [NetworkException] if there's a network connectivity issue
  ///
  /// Example:
  /// ```dart
  /// await service.initialize(
  ///   email: 'user@example.com',
  ///   name: 'John Doe',
  ///   phone: '+1234567890',
  /// );
  /// ```
  Future<void> initialize({
    required String email,
    String? name,
    String? phone,
  }) async {
    try {
      // Check if customer already exists in cache
      final cachedCustomerId = await _storage.getString(_customerIdKey);

      Customer customer;
      if (cachedCustomerId != null) {
        // Try to retrieve existing customer
        try {
          customer = await _retryOnNetworkError(
            () => _processor.getCustomer(cachedCustomerId),
          );
        } on CustomerNotFoundException {
          // Customer no longer exists, create a new one
          customer = await _retryOnNetworkError(
            () => _processor.createCustomer(
              email: email,
              name: name,
              phone: phone,
            ),
          );
        }
      } else {
        // Create new customer
        customer = await _retryOnNetworkError(
          () => _processor.createCustomer(
            email: email,
            name: name,
            phone: phone,
          ),
        );
      }

      // Cache customer data
      await _cacheCustomer(customer);
    } catch (e) {
      developer.log(
        'Failed to initialize payment service',
        error: e,
        name: 'PaymentService',
      );
      rethrow;
    }
  }

  /// Checks if the payment service has been initialized.
  ///
  /// Returns true if a customer ID is cached, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// if (await service.isInitialized()) {
  ///   // Service is ready to use
  /// } else {
  ///   // Need to call initialize() first
  /// }
  /// ```
  Future<bool> isInitialized() async {
    final customerId = await _storage.getString(_customerIdKey);
    return customerId != null;
  }

  /// Gets the current customer data.
  ///
  /// Returns cached customer data if available, otherwise fetches from API.
  /// Returns null if service is not initialized.
  ///
  /// Example:
  /// ```dart
  /// final customer = await service.getCurrentCustomer();
  /// if (customer != null) {
  ///   print('Customer: ${customer.email}');
  /// }
  /// ```
  Future<Customer?> getCurrentCustomer() async {
    try {
      // Try to get from cache first
      final cachedData = await _storage.getString(_customerDataKey);
      if (cachedData != null) {
        return Customer.fromJson(jsonDecode(cachedData));
      }

      // Fetch from API if not in cache
      final customerId = await _storage.getString(_customerIdKey);
      if (customerId == null) {
        return null;
      }

      final customer = await _retryOnNetworkError(
        () => _processor.getCustomer(customerId),
      );

      await _cacheCustomer(customer);
      return customer;
    } catch (e) {
      developer.log(
        'Failed to get current customer',
        error: e,
        name: 'PaymentService',
      );
      return null;
    }
  }

  // ==========================================================================
  // PAYMENT METHODS
  // ==========================================================================

  /// Sets the default payment method for the customer.
  ///
  /// Parameters:
  /// - [paymentMethodToken]: Token representing the payment method
  ///
  /// Throws:
  /// - [PaymentException] if service is not initialized or operation fails
  ///
  /// Example:
  /// ```dart
  /// await service.setDefaultPaymentMethod('pm_token_xyz');
  /// ```
  Future<void> setDefaultPaymentMethod(String paymentMethodToken) async {
    final customerId = await _requireCustomerId();

    try {
      // Add payment method and set as default
      final paymentMethod = await _retryOnNetworkError(
        () => _processor.addPaymentMethod(
          customerId: customerId,
          paymentMethodToken: paymentMethodToken,
          setAsDefault: true,
        ),
      );

      // Cache the default payment method
      await _storage.setString(
        _defaultPaymentMethodKey,
        jsonEncode(paymentMethod.toJson()),
      );

      developer.log(
        'Set default payment method: ${paymentMethod.id}',
        name: 'PaymentService',
      );
    } catch (e) {
      developer.log(
        'Failed to set default payment method',
        error: e,
        name: 'PaymentService',
      );
      rethrow;
    }
  }

  /// Gets the default payment method for the customer.
  ///
  /// Returns the default payment method if one exists, null otherwise.
  ///
  /// Example:
  /// ```dart
  /// final defaultMethod = await service.getDefaultPaymentMethod();
  /// if (defaultMethod != null) {
  ///   print('Default: ${defaultMethod.brand} ending in ${defaultMethod.last4}');
  /// }
  /// ```
  Future<PaymentMethod?> getDefaultPaymentMethod() async {
    try {
      // Try cache first
      final cachedData = await _storage.getString(_defaultPaymentMethodKey);
      if (cachedData != null) {
        return PaymentMethod.fromJson(jsonDecode(cachedData));
      }

      // Fetch from API
      final methods = await getPaymentMethods();
      return methods.firstWhere(
        (m) => m.isDefault,
        orElse: () => throw PaymentException(
          'No default payment method found',
          code: 'no_default_payment_method',
        ),
      );
    } catch (e) {
      developer.log(
        'Failed to get default payment method',
        error: e,
        name: 'PaymentService',
      );
      return null;
    }
  }

  /// Gets all payment methods for the customer.
  ///
  /// Returns a list of payment methods. Returns empty list if service is not
  /// initialized or customer has no payment methods.
  ///
  /// Example:
  /// ```dart
  /// final methods = await service.getPaymentMethods();
  /// for (final method in methods) {
  ///   print('${method.brand} ending in ${method.last4}');
  /// }
  /// ```
  Future<List<PaymentMethod>> getPaymentMethods() async {
    try {
      final customerId = await _requireCustomerId();

      final methods = await _retryOnNetworkError(
        () => _processor.listPaymentMethods(customerId),
      );

      // Update cached default payment method if found
      final defaultMethod = methods.where((m) => m.isDefault).firstOrNull;
      if (defaultMethod != null) {
        await _storage.setString(
          _defaultPaymentMethodKey,
          jsonEncode(defaultMethod.toJson()),
        );
      }

      return methods;
    } catch (e) {
      developer.log(
        'Failed to get payment methods',
        error: e,
        name: 'PaymentService',
      );
      return [];
    }
  }

  /// Removes a payment method.
  ///
  /// Parameters:
  /// - [paymentMethodId]: The ID of the payment method to remove
  ///
  /// Throws:
  /// - [PaymentException] if removal fails
  ///
  /// Example:
  /// ```dart
  /// await service.removePaymentMethod('pm_abc123');
  /// ```
  Future<void> removePaymentMethod(String paymentMethodId) async {
    try {
      await _retryOnNetworkError(
        () => _processor.removePaymentMethod(paymentMethodId),
      );

      // Clear cached default if it was removed
      final cachedDefault = await _storage.getString(_defaultPaymentMethodKey);
      if (cachedDefault != null) {
        final defaultMethod = PaymentMethod.fromJson(jsonDecode(cachedDefault));
        if (defaultMethod.id == paymentMethodId) {
          await _storage.remove(_defaultPaymentMethodKey);
        }
      }

      developer.log(
        'Removed payment method: $paymentMethodId',
        name: 'PaymentService',
      );
    } catch (e) {
      developer.log(
        'Failed to remove payment method',
        error: e,
        name: 'PaymentService',
      );
      rethrow;
    }
  }

  // ==========================================================================
  // SUBSCRIPTIONS
  // ==========================================================================

  /// Creates a subscription for the customer.
  ///
  /// Parameters:
  /// - [priceId]: The ID of the price/plan to subscribe to
  /// - [paymentMethodToken]: Optional payment method token. If not provided,
  ///   uses the customer's default payment method
  /// - [trialDays]: Optional number of trial days before charging begins
  ///
  /// Returns the created subscription.
  ///
  /// Throws:
  /// - [PaymentException] if service is not initialized or subscription fails
  ///
  /// Example:
  /// ```dart
  /// final subscription = await service.subscribe(
  ///   priceId: 'price_premium',
  ///   trialDays: 14,
  /// );
  /// ```
  Future<Subscription> subscribe({
    required String priceId,
    String? paymentMethodToken,
    int? trialDays,
  }) async {
    final customerId = await _requireCustomerId();

    try {
      // If payment method token provided, add it as default first
      String? paymentMethodId;
      if (paymentMethodToken != null) {
        final paymentMethod = await _retryOnNetworkError(
          () => _processor.addPaymentMethod(
            customerId: customerId,
            paymentMethodToken: paymentMethodToken,
            setAsDefault: true,
          ),
        );
        paymentMethodId = paymentMethod.id;
      }

      // Create subscription
      final subscription = await _retryOnNetworkError(
        () => _processor.createSubscription(
          customerId: customerId,
          priceId: priceId,
          paymentMethodId: paymentMethodId,
          trialDays: trialDays,
        ),
      );

      // Invalidate subscriptions cache
      await _storage.remove(_subscriptionsKey);

      developer.log(
        'Created subscription: ${subscription.id}',
        name: 'PaymentService',
      );

      return subscription;
    } catch (e) {
      developer.log(
        'Failed to create subscription',
        error: e,
        name: 'PaymentService',
      );
      rethrow;
    }
  }

  /// Gets all subscriptions for the customer.
  ///
  /// Returns cached subscriptions if available, otherwise fetches from API.
  ///
  /// Example:
  /// ```dart
  /// final subscriptions = await service.getSubscriptions();
  /// for (final sub in subscriptions) {
  ///   print('${sub.id}: ${sub.status}');
  /// }
  /// ```
  Future<List<Subscription>> getSubscriptions() async {
    try {
      // Try cache first
      final cachedData = await _storage.getString(_subscriptionsKey);
      if (cachedData != null) {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        return jsonList
            .map((json) => Subscription.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // Fetch from API
      final customerId = await _requireCustomerId();
      final subscriptions = await _retryOnNetworkError(
        () => _processor.listSubscriptions(customerId),
      );

      // Cache subscriptions
      await _storage.setString(
        _subscriptionsKey,
        jsonEncode(subscriptions.map((s) => s.toJson()).toList()),
      );

      return subscriptions;
    } catch (e) {
      developer.log(
        'Failed to get subscriptions',
        error: e,
        name: 'PaymentService',
      );
      return [];
    }
  }

  /// Gets the active subscription for the customer.
  ///
  /// Parameters:
  /// - [productId]: Optional product ID to filter by specific product
  ///
  /// Returns the active subscription if one exists, null otherwise.
  ///
  /// Example:
  /// ```dart
  /// final activeSubscription = await service.getActiveSubscription();
  /// if (activeSubscription != null) {
  ///   print('Active until: ${activeSubscription.currentPeriodEnd}');
  /// }
  /// ```
  Future<Subscription?> getActiveSubscription({String? productId}) async {
    try {
      final subscriptions = await getSubscriptions();

      return subscriptions.firstWhere(
        (sub) {
          final isActiveOrTrialing = sub.status == SubscriptionStatus.active ||
              sub.status == SubscriptionStatus.trialing;

          if (productId != null) {
            return isActiveOrTrialing && sub.productId == productId;
          }

          return isActiveOrTrialing;
        },
        orElse: () => throw SubscriptionNotFoundException(
          'No active subscription found',
        ),
      );
    } catch (e) {
      if (e is! SubscriptionNotFoundException) {
        developer.log(
          'Failed to get active subscription',
          error: e,
          name: 'PaymentService',
        );
      }
      return null;
    }
  }

  /// Checks if the customer has an active subscription.
  ///
  /// Parameters:
  /// - [productId]: Optional product ID to check for specific product
  ///
  /// Returns true if an active subscription exists, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// if (await service.hasActiveSubscription()) {
  ///   // Show premium features
  /// }
  /// ```
  Future<bool> hasActiveSubscription({String? productId}) async {
    final subscription = await getActiveSubscription(productId: productId);
    return subscription != null;
  }

  /// Checks if the customer is on a trial period.
  ///
  /// Parameters:
  /// - [productId]: Optional product ID to check for specific product
  ///
  /// Returns true if on trial, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// if (await service.isOnTrial()) {
  ///   print('Trial ends in ${daysRemaining} days');
  /// }
  /// ```
  Future<bool> isOnTrial({String? productId}) async {
    try {
      final subscription = await getActiveSubscription(productId: productId);
      return subscription?.isOnTrial ?? false;
    } catch (e) {
      developer.log(
        'Failed to check trial status',
        error: e,
        name: 'PaymentService',
      );
      return false;
    }
  }

  /// Cancels a subscription.
  ///
  /// Parameters:
  /// - [subscriptionId]: The ID of the subscription to cancel
  /// - [immediate]: If true, cancels immediately. If false, cancels at the end
  ///   of the current billing period (defaults to false)
  ///
  /// Throws:
  /// - [SubscriptionNotFoundException] if subscription doesn't exist
  /// - [PaymentException] if cancellation fails
  ///
  /// Example:
  /// ```dart
  /// // Cancel at period end
  /// await service.cancelSubscription(subscriptionId);
  ///
  /// // Cancel immediately
  /// await service.cancelSubscription(subscriptionId, immediate: true);
  /// ```
  Future<void> cancelSubscription(
    String subscriptionId, {
    bool immediate = false,
  }) async {
    try {
      await _retryOnNetworkError(
        () => _processor.cancelSubscription(
          subscriptionId: subscriptionId,
          immediate: immediate,
        ),
      );

      // Invalidate subscriptions cache
      await _storage.remove(_subscriptionsKey);

      developer.log(
        'Canceled subscription: $subscriptionId (immediate: $immediate)',
        name: 'PaymentService',
      );
    } catch (e) {
      developer.log(
        'Failed to cancel subscription',
        error: e,
        name: 'PaymentService',
      );
      rethrow;
    }
  }

  /// Resumes a canceled subscription.
  ///
  /// Parameters:
  /// - [subscriptionId]: The ID of the subscription to resume
  ///
  /// This only works for subscriptions canceled with `immediate: false` that
  /// are still within their grace period.
  ///
  /// Throws:
  /// - [SubscriptionNotFoundException] if subscription doesn't exist
  /// - [PaymentException] if resumption fails
  ///
  /// Example:
  /// ```dart
  /// await service.resumeSubscription(subscriptionId);
  /// ```
  Future<void> resumeSubscription(String subscriptionId) async {
    try {
      await _retryOnNetworkError(
        () => _processor.resumeSubscription(subscriptionId),
      );

      // Invalidate subscriptions cache
      await _storage.remove(_subscriptionsKey);

      developer.log(
        'Resumed subscription: $subscriptionId',
        name: 'PaymentService',
      );
    } catch (e) {
      developer.log(
        'Failed to resume subscription',
        error: e,
        name: 'PaymentService',
      );
      rethrow;
    }
  }

  /// Changes a subscription to a different plan.
  ///
  /// Parameters:
  /// - [subscriptionId]: The ID of the subscription to change
  /// - [newPriceId]: The ID of the new price/plan
  ///
  /// Throws:
  /// - [SubscriptionNotFoundException] if subscription doesn't exist
  /// - [PaymentException] if plan change fails
  ///
  /// Example:
  /// ```dart
  /// await service.changePlan(
  ///   subscriptionId: 'sub_abc123',
  ///   newPriceId: 'price_premium',
  /// );
  /// ```
  Future<void> changePlan({
    required String subscriptionId,
    required String newPriceId,
  }) async {
    try {
      if (_processor.supportsPlanSwapping) {
        await _retryOnNetworkError(
          () => _processor.swapPlan(
            subscriptionId: subscriptionId,
            newPriceId: newPriceId,
            prorate: _processor.supportsProration,
          ),
        );
      } else {
        // Fallback to update subscription
        await _retryOnNetworkError(
          () => _processor.updateSubscription(
            subscriptionId: subscriptionId,
            priceId: newPriceId,
          ),
        );
      }

      // Invalidate subscriptions cache
      await _storage.remove(_subscriptionsKey);

      developer.log(
        'Changed plan for subscription: $subscriptionId to $newPriceId',
        name: 'PaymentService',
      );
    } catch (e) {
      developer.log(
        'Failed to change plan',
        error: e,
        name: 'PaymentService',
      );
      rethrow;
    }
  }

  // ==========================================================================
  // PAYMENTS
  // ==========================================================================

  /// Makes a one-time payment.
  ///
  /// Parameters:
  /// - [amount]: Amount to charge in smallest currency unit (e.g., cents)
  /// - [currency]: Three-letter ISO currency code (e.g., 'usd', 'eur')
  /// - [description]: Optional description of the payment
  /// - [paymentMethodToken]: Optional payment method token. If not provided,
  ///   uses the customer's default payment method
  ///
  /// Returns the created charge.
  ///
  /// Throws:
  /// - [PaymentException] if service is not initialized or payment fails
  ///
  /// Example:
  /// ```dart
  /// // Charge $25.00 USD
  /// final charge = await service.makePayment(
  ///   amount: 2500,
  ///   currency: 'usd',
  ///   description: 'One-time setup fee',
  /// );
  /// ```
  Future<Charge> makePayment({
    required int amount,
    required String currency,
    String? description,
    String? paymentMethodToken,
  }) async {
    final customerId = await _requireCustomerId();

    try {
      // If payment method token provided, add it first
      String? paymentMethodId;
      if (paymentMethodToken != null) {
        final paymentMethod = await _retryOnNetworkError(
          () => _processor.addPaymentMethod(
            customerId: customerId,
            paymentMethodToken: paymentMethodToken,
            setAsDefault: false,
          ),
        );
        paymentMethodId = paymentMethod.id;
      }

      // Create charge
      final charge = await _retryOnNetworkError(
        () => _processor.createCharge(
          customerId: customerId,
          amount: amount,
          currency: currency,
          description: description,
          paymentMethodId: paymentMethodId,
        ),
      );

      developer.log(
        'Created charge: ${charge.id} for $amount $currency',
        name: 'PaymentService',
      );

      return charge;
    } catch (e) {
      developer.log(
        'Failed to make payment',
        error: e,
        name: 'PaymentService',
      );
      rethrow;
    }
  }

  /// Gets the payment history for the customer.
  ///
  /// Parameters:
  /// - [limit]: Maximum number of charges to return (defaults to 10)
  ///
  /// Returns a list of charges, ordered by creation date (newest first).
  ///
  /// Example:
  /// ```dart
  /// final history = await service.getPaymentHistory(limit: 20);
  /// for (final charge in history) {
  ///   print('${charge.amount} ${charge.currency} - ${charge.status}');
  /// }
  /// ```
  Future<List<Charge>> getPaymentHistory({int limit = 10}) async {
    try {
      final customerId = await _requireCustomerId();

      final charges = await _retryOnNetworkError(
        () => _processor.listCharges(
          customerId: customerId,
          limit: limit,
        ),
      );

      return charges;
    } catch (e) {
      developer.log(
        'Failed to get payment history',
        error: e,
        name: 'PaymentService',
      );
      return [];
    }
  }

  // ==========================================================================
  // CACHE MANAGEMENT
  // ==========================================================================

  /// Refreshes the customer data from the API.
  ///
  /// Forces a fresh fetch from the payment processor and updates the cache.
  ///
  /// Example:
  /// ```dart
  /// await service.refreshCustomer();
  /// ```
  Future<void> refreshCustomer() async {
    try {
      final customerId = await _requireCustomerId();

      final customer = await _retryOnNetworkError(
        () => _processor.getCustomer(customerId),
      );

      await _cacheCustomer(customer);

      developer.log(
        'Refreshed customer data',
        name: 'PaymentService',
      );
    } catch (e) {
      developer.log(
        'Failed to refresh customer',
        error: e,
        name: 'PaymentService',
      );
      rethrow;
    }
  }

  /// Refreshes the subscriptions data from the API.
  ///
  /// Forces a fresh fetch from the payment processor and updates the cache.
  ///
  /// Example:
  /// ```dart
  /// await service.refreshSubscriptions();
  /// ```
  Future<void> refreshSubscriptions() async {
    try {
      final customerId = await _requireCustomerId();

      final subscriptions = await _retryOnNetworkError(
        () => _processor.listSubscriptions(customerId),
      );

      // Update cache
      await _storage.setString(
        _subscriptionsKey,
        jsonEncode(subscriptions.map((s) => s.toJson()).toList()),
      );

      developer.log(
        'Refreshed subscriptions data',
        name: 'PaymentService',
      );
    } catch (e) {
      developer.log(
        'Failed to refresh subscriptions',
        error: e,
        name: 'PaymentService',
      );
      rethrow;
    }
  }

  /// Clears all cached data.
  ///
  /// This forces all subsequent calls to fetch fresh data from the API.
  ///
  /// Example:
  /// ```dart
  /// await service.clearCache();
  /// ```
  Future<void> clearCache() async {
    try {
      await _storage.remove(_customerDataKey);
      await _storage.remove(_subscriptionsKey);
      await _storage.remove(_defaultPaymentMethodKey);

      developer.log(
        'Cleared payment service cache',
        name: 'PaymentService',
      );
    } catch (e) {
      developer.log(
        'Failed to clear cache',
        error: e,
        name: 'PaymentService',
      );
    }
  }

  // ==========================================================================
  // PRIVATE HELPER METHODS
  // ==========================================================================

  /// Gets the customer ID from storage or throws an exception.
  Future<String> _requireCustomerId() async {
    final customerId = await _storage.getString(_customerIdKey);
    if (customerId == null) {
      throw PaymentException(
        'Payment service not initialized. Call initialize() first.',
        code: 'not_initialized',
      );
    }
    return customerId;
  }

  /// Caches customer data in storage.
  Future<void> _cacheCustomer(Customer customer) async {
    await _storage.setString(_customerIdKey, customer.id);
    await _storage.setString(
      _customerDataKey,
      jsonEncode(customer.toJson()),
    );
  }

  /// Retries a function on network errors with exponential backoff.
  Future<T> _retryOnNetworkError<T>(
    Future<T> Function() function,
  ) async {
    int retryCount = 0;
    Duration delay = _retryDelay;

    while (true) {
      try {
        return await function();
      } on NetworkException catch (e) {
        retryCount++;

        if (retryCount >= _maxRetries) {
          developer.log(
            'Max retries reached for network error',
            error: e,
            name: 'PaymentService',
          );
          rethrow;
        }

        developer.log(
          'Network error, retrying in ${delay.inSeconds}s (attempt $retryCount/$_maxRetries)',
          error: e,
          name: 'PaymentService',
        );

        await Future.delayed(delay);
        delay *= 2; // Exponential backoff
      }
    }
  }
}

// ============================================================================
// RIVERPOD PROVIDERS
// ============================================================================

/// Provider for the payment service instance.
///
/// This must be overridden in your app with the actual service instance.
///
/// Example:
/// ```dart
/// final container = ProviderContainer(
///   overrides: [
///     paymentServiceProvider.overrideWithValue(
///       PaymentService(
///         processor: StripeProcessor(apiKey: 'sk_...'),
///         storage: SharedPreferencesStorage(
///           getPreferences: () => SharedPreferences.getInstance(),
///         ),
///       ),
///     ),
///   ],
/// );
/// ```
final paymentServiceProvider = Provider<PaymentService>((ref) {
  throw UnimplementedError('Must be overridden with actual PaymentService');
});

/// Provider for the current customer.
///
/// Automatically fetches the customer data when accessed.
///
/// Example:
/// ```dart
/// final customer = ref.watch(currentCustomerProvider);
/// customer.when(
///   data: (customer) => Text('Hello ${customer?.name}'),
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => Text('Error: $error'),
/// );
/// ```
final currentCustomerProvider = FutureProvider<Customer?>((ref) async {
  final service = ref.watch(paymentServiceProvider);
  return service.getCurrentCustomer();
});

/// Provider for the active subscription.
///
/// Automatically fetches the active subscription when accessed.
///
/// Example:
/// ```dart
/// final subscription = ref.watch(activeSubscriptionProvider);
/// subscription.when(
///   data: (sub) => Text(sub != null ? 'Active' : 'No subscription'),
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => Text('Error: $error'),
/// );
/// ```
final activeSubscriptionProvider = FutureProvider<Subscription?>((ref) async {
  final service = ref.watch(paymentServiceProvider);
  return service.getActiveSubscription();
});

/// Provider for checking if customer has an active subscription.
///
/// Automatically checks subscription status when accessed.
///
/// Example:
/// ```dart
/// final hasSubscription = ref.watch(hasActiveSubscriptionProvider);
/// hasSubscription.when(
///   data: (hasActive) => hasActive ? PremiumFeatures() : FreeTier(),
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => Text('Error: $error'),
/// );
/// ```
final hasActiveSubscriptionProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(paymentServiceProvider);
  return service.hasActiveSubscription();
});
