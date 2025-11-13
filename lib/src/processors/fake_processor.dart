import 'dart:math';
import 'package:uuid/uuid.dart';

import '../exceptions/exceptions.dart';
import '../models/models.dart';
import 'base_processor.dart';

/// Fake payment processor implementation for testing and development.
///
/// This processor simulates payment processing behavior without making actual
/// API calls. Perfect for testing, demos, and development environments.
///
/// Features:
/// - In-memory storage for all entities
/// - Configurable delays and failure rates
/// - Realistic ID generation with 'fake_' prefix
/// - Support for all payment processor operations
/// - Optional logging for debugging
///
/// Example usage:
/// ```dart
/// final processor = FakeProcessor(
///   simulateDelays: true,
///   delayDuration: Duration(milliseconds: 500),
///   failureRate: 0.0, // Never fail
///   enableLogging: true,
/// );
///
/// final customer = await processor.createCustomer(
///   email: 'test@example.com',
///   name: 'Test User',
/// );
/// ```
class FakeProcessor extends PaymentProcessor {
  /// Whether to simulate network delays
  final bool simulateDelays;

  /// Duration of simulated delays
  final Duration delayDuration;

  /// Failure rate from 0.0 (never fail) to 1.0 (always fail)
  final double failureRate;

  /// Whether to enable logging
  final bool enableLogging;

  /// Random number generator for failure simulation
  final Random _random = Random();

  /// UUID generator for creating fake IDs
  final _uuid = const Uuid();

  // ============================================================================
  // IN-MEMORY STORAGE
  // ============================================================================

  /// In-memory customer storage
  final Map<String, Customer> _customers = {};

  /// In-memory subscription storage
  final Map<String, Subscription> _subscriptions = {};

  /// In-memory charge storage
  final Map<String, Charge> _charges = {};

  /// In-memory payment method storage
  final Map<String, PaymentMethod> _paymentMethods = {};

  /// Track default payment methods per customer
  final Map<String, String> _defaultPaymentMethods = {};

  /// Creates a new [FakeProcessor] instance.
  ///
  /// Parameters:
  /// - [simulateDelays]: Whether to simulate network delays (defaults to true)
  /// - [delayDuration]: Duration of delays (defaults to 500ms)
  /// - [failureRate]: Rate of random failures 0.0-1.0 (defaults to 0.0)
  /// - [enableLogging]: Whether to log operations (defaults to false)
  FakeProcessor({
    this.simulateDelays = true,
    this.delayDuration = const Duration(milliseconds: 500),
    this.failureRate = 0.0,
    this.enableLogging = false,
  }) {
    if (failureRate < 0.0 || failureRate > 1.0) {
      throw ArgumentError('failureRate must be between 0.0 and 1.0');
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Generates a fake ID with the given prefix
  String _generateId(String prefix) {
    return '${prefix}_${_uuid.v4().replaceAll('-', '')}';
  }

  /// Simulates a network delay if configured
  Future<void> _simulateDelay() async {
    if (simulateDelays) {
      await Future.delayed(delayDuration);
    }
  }

  /// Checks if the current operation should fail based on failure rate
  bool _shouldFail() {
    if (failureRate <= 0.0) return false;
    return _random.nextDouble() < failureRate;
  }

  /// Logs an operation if logging is enabled
  void _logOperation(String operation) {
    if (enableLogging) {
      print('[FakeProcessor] $operation');
    }
  }

  /// Resets all in-memory storage (useful for testing)
  void reset() {
    _customers.clear();
    _subscriptions.clear();
    _charges.clear();
    _paymentMethods.clear();
    _defaultPaymentMethods.clear();
    _logOperation('Reset all storage');
  }

  // ============================================================================
  // CUSTOMER MANAGEMENT
  // ============================================================================

  @override
  Future<Customer> createCustomer({
    required String email,
    String? name,
    String? phone,
    Map<String, dynamic>? metadata,
  }) async {
    _logOperation('createCustomer: $email');
    await _simulateDelay();

    if (_shouldFail()) {
      throw PaymentException(
        'Simulated failure: Customer creation failed',
        code: 'simulated_failure',
      );
    }

    // Validate email format
    if (!email.contains('@')) {
      throw ValidationException(
        'Invalid email address',
        fieldName: 'email',
      );
    }

    final now = DateTime.now();
    final id = _generateId('fake_cus');

    final customer = Customer(
      id: id,
      email: email,
      name: name,
      phone: phone,
      processor: ProcessorType.fake,
      processorCustomerId: id,
      metadata: metadata,
      createdAt: now,
      updatedAt: now,
    );

    _customers[id] = customer;
    _logOperation('Created customer: $id');
    return customer;
  }

  @override
  Future<Customer> getCustomer(String customerId) async {
    _logOperation('getCustomer: $customerId');
    await _simulateDelay();

    if (_shouldFail()) {
      throw PaymentException(
        'Simulated failure: Customer retrieval failed',
        code: 'simulated_failure',
      );
    }

    final customer = _customers[customerId];
    if (customer == null) {
      throw CustomerNotFoundException(
        'Customer not found',
        customerId: customerId,
      );
    }

    return customer;
  }

  @override
  Future<Customer> updateCustomer(
    String customerId, {
    String? email,
    String? name,
    String? phone,
    Map<String, dynamic>? metadata,
  }) async {
    _logOperation('updateCustomer: $customerId');
    await _simulateDelay();

    if (_shouldFail()) {
      throw PaymentException(
        'Simulated failure: Customer update failed',
        code: 'simulated_failure',
      );
    }

    final customer = _customers[customerId];
    if (customer == null) {
      throw CustomerNotFoundException(
        'Customer not found',
        customerId: customerId,
      );
    }

    // Validate email if provided
    if (email != null && !email.contains('@')) {
      throw ValidationException(
        'Invalid email address',
        fieldName: 'email',
      );
    }

    final updatedCustomer = customer.copyWith(
      email: email ?? customer.email,
      name: name ?? customer.name,
      phone: phone ?? customer.phone,
      metadata: metadata != null
          ? {...?customer.metadata, ...metadata}
          : customer.metadata,
      updatedAt: DateTime.now(),
    );

    _customers[customerId] = updatedCustomer;
    _logOperation('Updated customer: $customerId');
    return updatedCustomer;
  }

  @override
  Future<void> deleteCustomer(String customerId) async {
    _logOperation('deleteCustomer: $customerId');
    await _simulateDelay();

    if (_shouldFail()) {
      throw PaymentException(
        'Simulated failure: Customer deletion failed',
        code: 'simulated_failure',
      );
    }

    final customer = _customers[customerId];
    if (customer == null) {
      throw CustomerNotFoundException(
        'Customer not found',
        customerId: customerId,
      );
    }

    // Check for active subscriptions
    final hasActiveSubscriptions = _subscriptions.values.any(
      (sub) =>
          sub.customerId == customerId &&
          (sub.status == SubscriptionStatus.active ||
              sub.status == SubscriptionStatus.trialing),
    );

    if (hasActiveSubscriptions) {
      throw PaymentException(
        'Cannot delete customer with active subscriptions',
        code: 'has_active_subscriptions',
      );
    }

    // Remove customer and related data
    _customers.remove(customerId);
    _paymentMethods.removeWhere((_, pm) => pm.customerId == customerId);
    _defaultPaymentMethods.remove(customerId);
    _logOperation('Deleted customer: $customerId');
  }

  // ============================================================================
  // PAYMENT METHODS
  // ============================================================================

  @override
  Future<PaymentMethod> addPaymentMethod({
    required String customerId,
    required String paymentMethodToken,
    bool setAsDefault = false,
  }) async {
    _logOperation('addPaymentMethod: $customerId');
    await _simulateDelay();

    if (_shouldFail()) {
      throw PaymentException(
        'Simulated failure: Payment method addition failed',
        code: 'simulated_failure',
      );
    }

    final customer = _customers[customerId];
    if (customer == null) {
      throw CustomerNotFoundException(
        'Customer not found',
        customerId: customerId,
      );
    }

    // Validate token format
    if (paymentMethodToken.isEmpty) {
      throw PaymentMethodException(
        'Payment method token cannot be empty',
        code: 'invalid_token',
      );
    }

    final id = _generateId('fake_pm');

    // Generate realistic card data
    final brands = ['visa', 'mastercard', 'amex', 'discover'];
    final brand = brands[_random.nextInt(brands.length)];
    final last4 = (_random.nextInt(9000) + 1000).toString();
    final expiryMonth = _random.nextInt(12) + 1;
    final expiryYear = DateTime.now().year + _random.nextInt(5) + 1;

    // If setting as default or this is the first payment method, update default
    final isFirstPaymentMethod =
        !_paymentMethods.values.any((pm) => pm.customerId == customerId);
    final isDefault = setAsDefault || isFirstPaymentMethod;

    // If setting as default, update other payment methods
    if (isDefault) {
      _updateDefaultPaymentMethod(customerId, id);
    }

    final paymentMethod = PaymentMethod(
      id: id,
      customerId: customerId,
      type: PaymentMethodType.card,
      last4: last4,
      brand: brand,
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
      isDefault: isDefault,
    );

    _paymentMethods[id] = paymentMethod;
    _logOperation('Added payment method: $id');
    return paymentMethod;
  }

  @override
  Future<PaymentMethod> getPaymentMethod(String paymentMethodId) async {
    _logOperation('getPaymentMethod: $paymentMethodId');
    await _simulateDelay();

    if (_shouldFail()) {
      throw PaymentException(
        'Simulated failure: Payment method retrieval failed',
        code: 'simulated_failure',
      );
    }

    final paymentMethod = _paymentMethods[paymentMethodId];
    if (paymentMethod == null) {
      throw PaymentMethodException(
        'Payment method not found',
        code: 'not_found',
      );
    }

    return paymentMethod;
  }

  @override
  Future<List<PaymentMethod>> listPaymentMethods(String customerId) async {
    _logOperation('listPaymentMethods: $customerId');
    await _simulateDelay();

    if (_shouldFail()) {
      throw PaymentException(
        'Simulated failure: Payment method listing failed',
        code: 'simulated_failure',
      );
    }

    final customer = _customers[customerId];
    if (customer == null) {
      throw CustomerNotFoundException(
        'Customer not found',
        customerId: customerId,
      );
    }

    return _paymentMethods.values
        .where((pm) => pm.customerId == customerId)
        .toList();
  }

  @override
  Future<PaymentMethod> setDefaultPaymentMethod({
    required String customerId,
    required String paymentMethodId,
  }) async {
    _logOperation('setDefaultPaymentMethod: $paymentMethodId');
    await _simulateDelay();

    if (_shouldFail()) {
      throw PaymentException(
        'Simulated failure: Setting default payment method failed',
        code: 'simulated_failure',
      );
    }

    final customer = _customers[customerId];
    if (customer == null) {
      throw CustomerNotFoundException(
        'Customer not found',
        customerId: customerId,
      );
    }

    final paymentMethod = _paymentMethods[paymentMethodId];
    if (paymentMethod == null) {
      throw PaymentMethodException(
        'Payment method not found',
        code: 'not_found',
      );
    }

    if (paymentMethod.customerId != customerId) {
      throw PaymentException(
        'Payment method does not belong to customer',
        code: 'payment_method_mismatch',
      );
    }

    _updateDefaultPaymentMethod(customerId, paymentMethodId);
    final updatedMethod = _paymentMethods[paymentMethodId]!;
    _logOperation('Set default payment method: $paymentMethodId');
    return updatedMethod;
  }

  @override
  Future<void> removePaymentMethod(String paymentMethodId) async {
    _logOperation('removePaymentMethod: $paymentMethodId');
    await _simulateDelay();

    if (_shouldFail()) {
      throw PaymentException(
        'Simulated failure: Payment method removal failed',
        code: 'simulated_failure',
      );
    }

    final paymentMethod = _paymentMethods[paymentMethodId];
    if (paymentMethod == null) {
      throw PaymentMethodException(
        'Payment method not found',
        code: 'not_found',
      );
    }

    // Check if any active subscriptions use this payment method
    final hasActiveSubscriptions = _subscriptions.values.any(
      (sub) =>
          sub.customerId == paymentMethod.customerId &&
          (sub.status == SubscriptionStatus.active ||
              sub.status == SubscriptionStatus.trialing),
    );

    if (hasActiveSubscriptions && paymentMethod.isDefault) {
      // Find another payment method to set as default
      final otherMethods = _paymentMethods.values
          .where((pm) =>
              pm.customerId == paymentMethod.customerId && pm.id != paymentMethodId)
          .toList();

      if (otherMethods.isEmpty) {
        throw PaymentException(
          'Cannot remove the only payment method with active subscriptions',
          code: 'last_payment_method',
        );
      }
    }

    _paymentMethods.remove(paymentMethodId);
    if (_defaultPaymentMethods[paymentMethod.customerId] == paymentMethodId) {
      _defaultPaymentMethods.remove(paymentMethod.customerId);

      // Set first available payment method as default
      final otherMethod = _paymentMethods.values
          .where((pm) => pm.customerId == paymentMethod.customerId)
          .firstOrNull;
      if (otherMethod != null) {
        _updateDefaultPaymentMethod(paymentMethod.customerId, otherMethod.id);
      }
    }

    _logOperation('Removed payment method: $paymentMethodId');
  }

  /// Helper method to update default payment method
  void _updateDefaultPaymentMethod(String customerId, String paymentMethodId) {
    // Remove default flag from all customer's payment methods
    _paymentMethods.forEach((id, pm) {
      if (pm.customerId == customerId && pm.isDefault) {
        _paymentMethods[id] = pm.copyWith(isDefault: false);
      }
    });

    // Set new default
    final pm = _paymentMethods[paymentMethodId];
    if (pm != null) {
      _paymentMethods[paymentMethodId] = pm.copyWith(isDefault: true);
      _defaultPaymentMethods[customerId] = paymentMethodId;
    }
  }

  // ============================================================================
  // SUBSCRIPTIONS
  // ============================================================================

  @override
  Future<Subscription> createSubscription({
    required String customerId,
    required String priceId,
    String? paymentMethodId,
    int? trialDays,
    int quantity = 1,
    Map<String, dynamic>? metadata,
  }) async {
    _logOperation('createSubscription: $customerId, $priceId');
    await _simulateDelay();

    if (_shouldFail()) {
      throw PaymentException(
        'Simulated failure: Subscription creation failed',
        code: 'simulated_failure',
      );
    }

    final customer = _customers[customerId];
    if (customer == null) {
      throw CustomerNotFoundException(
        'Customer not found',
        customerId: customerId,
      );
    }

    // Check payment method if not in trial
    if (trialDays == null || trialDays == 0) {
      final pmId = paymentMethodId ?? _defaultPaymentMethods[customerId];
      if (pmId == null) {
        throw PaymentMethodException(
          'No default payment method found for customer',
          code: 'no_default_payment_method',
        );
      }

      final pm = _paymentMethods[pmId];
      if (pm == null) {
        throw PaymentMethodException(
          'Payment method not found',
          code: 'not_found',
        );
      }
    }

    final now = DateTime.now();
    final id = _generateId('fake_sub');

    // Calculate trial period
    DateTime? trialStart;
    DateTime? trialEnd;
    DateTime currentPeriodStart;
    DateTime currentPeriodEnd;
    SubscriptionStatus status;

    if (trialDays != null && trialDays > 0) {
      trialStart = now;
      trialEnd = now.add(Duration(days: trialDays));
      currentPeriodStart = now;
      currentPeriodEnd = trialEnd;
      status = SubscriptionStatus.trialing;
    } else {
      currentPeriodStart = now;
      currentPeriodEnd = now.add(const Duration(days: 30)); // Default to monthly
      status = SubscriptionStatus.active;
    }

    final subscription = Subscription(
      id: id,
      customerId: customerId,
      status: status,
      priceId: priceId,
      productId: 'fake_prod_${priceId.hashCode}',
      currentPeriodStart: currentPeriodStart,
      currentPeriodEnd: currentPeriodEnd,
      trialStart: trialStart,
      trialEnd: trialEnd,
      canceledAt: null,
      cancelAtPeriodEnd: false,
      quantity: quantity,
      processor: ProcessorType.fake,
      processorSubscriptionId: id,
      metadata: metadata,
    );

    _subscriptions[id] = subscription;
    _logOperation('Created subscription: $id');
    return subscription;
  }

  @override
  Future<Subscription> getSubscription(String subscriptionId) async {
    _logOperation('getSubscription: $subscriptionId');
    await _simulateDelay();

    if (_shouldFail()) {
      throw PaymentException(
        'Simulated failure: Subscription retrieval failed',
        code: 'simulated_failure',
      );
    }

    final subscription = _subscriptions[subscriptionId];
    if (subscription == null) {
      throw SubscriptionNotFoundException(
        'Subscription not found',
        subscriptionId: subscriptionId,
      );
    }

    return subscription;
  }

  @override
  Future<List<Subscription>> listSubscriptions(String customerId) async {
    _logOperation('listSubscriptions: $customerId');
    await _simulateDelay();

    if (_shouldFail()) {
      throw PaymentException(
        'Simulated failure: Subscription listing failed',
        code: 'simulated_failure',
      );
    }

    final customer = _customers[customerId];
    if (customer == null) {
      throw CustomerNotFoundException(
        'Customer not found',
        customerId: customerId,
      );
    }

    return _subscriptions.values
        .where((sub) => sub.customerId == customerId)
        .toList();
  }

  @override
  Future<Subscription> updateSubscription({
    required String subscriptionId,
    String? priceId,
    int? quantity,
    Map<String, dynamic>? metadata,
  }) async {
    _logOperation('updateSubscription: $subscriptionId');
    await _simulateDelay();

    if (_shouldFail()) {
      throw PaymentException(
        'Simulated failure: Subscription update failed',
        code: 'simulated_failure',
      );
    }

    final subscription = _subscriptions[subscriptionId];
    if (subscription == null) {
      throw SubscriptionNotFoundException(
        'Subscription not found',
        subscriptionId: subscriptionId,
      );
    }

    final updatedSubscription = subscription.copyWith(
      priceId: priceId ?? subscription.priceId,
      quantity: quantity ?? subscription.quantity,
      metadata: metadata != null
          ? {...?subscription.metadata, ...metadata}
          : subscription.metadata,
    );

    _subscriptions[subscriptionId] = updatedSubscription;
    _logOperation('Updated subscription: $subscriptionId');
    return updatedSubscription;
  }

  @override
  Future<Subscription> cancelSubscription({
    required String subscriptionId,
    bool immediate = false,
  }) async {
    _logOperation('cancelSubscription: $subscriptionId (immediate: $immediate)');
    await _simulateDelay();

    if (_shouldFail()) {
      throw PaymentException(
        'Simulated failure: Subscription cancellation failed',
        code: 'simulated_failure',
      );
    }

    final subscription = _subscriptions[subscriptionId];
    if (subscription == null) {
      throw SubscriptionNotFoundException(
        'Subscription not found',
        subscriptionId: subscriptionId,
      );
    }

    final now = DateTime.now();

    final updatedSubscription = immediate
        ? subscription.copyWith(
            status: SubscriptionStatus.canceled,
            canceledAt: now,
            cancelAtPeriodEnd: false,
          )
        : subscription.copyWith(
            canceledAt: now,
            cancelAtPeriodEnd: true,
          );

    _subscriptions[subscriptionId] = updatedSubscription;
    _logOperation('Canceled subscription: $subscriptionId');
    return updatedSubscription;
  }

  @override
  Future<Subscription> resumeSubscription(String subscriptionId) async {
    _logOperation('resumeSubscription: $subscriptionId');
    await _simulateDelay();

    if (_shouldFail()) {
      throw PaymentException(
        'Simulated failure: Subscription resumption failed',
        code: 'simulated_failure',
      );
    }

    final subscription = _subscriptions[subscriptionId];
    if (subscription == null) {
      throw SubscriptionNotFoundException(
        'Subscription not found',
        subscriptionId: subscriptionId,
      );
    }

    if (!subscription.cancelAtPeriodEnd) {
      throw PaymentException(
        'Cannot resume subscription that was not scheduled for cancellation',
        code: 'invalid_subscription_state',
      );
    }

    final updatedSubscription = subscription.copyWith(
      canceledAt: null,
      cancelAtPeriodEnd: false,
    );

    _subscriptions[subscriptionId] = updatedSubscription;
    _logOperation('Resumed subscription: $subscriptionId');
    return updatedSubscription;
  }

  @override
  Future<Subscription> pauseSubscription(String subscriptionId) async {
    _logOperation('pauseSubscription: $subscriptionId');
    await _simulateDelay();

    if (_shouldFail()) {
      throw PaymentException(
        'Simulated failure: Subscription pausing failed',
        code: 'simulated_failure',
      );
    }

    final subscription = _subscriptions[subscriptionId];
    if (subscription == null) {
      throw SubscriptionNotFoundException(
        'Subscription not found',
        subscriptionId: subscriptionId,
      );
    }

    if (subscription.status == SubscriptionStatus.paused) {
      return subscription;
    }

    final updatedSubscription = subscription.copyWith(
      status: SubscriptionStatus.paused,
    );

    _subscriptions[subscriptionId] = updatedSubscription;
    _logOperation('Paused subscription: $subscriptionId');
    return updatedSubscription;
  }

  @override
  Future<Subscription> swapPlan({
    required String subscriptionId,
    required String newPriceId,
    bool prorate = true,
  }) async {
    _logOperation('swapPlan: $subscriptionId to $newPriceId (prorate: $prorate)');
    await _simulateDelay();

    if (_shouldFail()) {
      throw PaymentException(
        'Simulated failure: Plan swap failed',
        code: 'simulated_failure',
      );
    }

    final subscription = _subscriptions[subscriptionId];
    if (subscription == null) {
      throw SubscriptionNotFoundException(
        'Subscription not found',
        subscriptionId: subscriptionId,
      );
    }

    // If prorating, charge might be created (simulated)
    if (prorate && subscription.status == SubscriptionStatus.active) {
      _logOperation('Simulating proration charge for plan swap');
    }

    final updatedSubscription = subscription.copyWith(
      priceId: newPriceId,
      productId: 'fake_prod_${newPriceId.hashCode}',
    );

    _subscriptions[subscriptionId] = updatedSubscription;
    _logOperation('Swapped plan for subscription: $subscriptionId');
    return updatedSubscription;
  }

  // ============================================================================
  // CHARGES (ONE-TIME PAYMENTS)
  // ============================================================================

  @override
  Future<Charge> createCharge({
    required String customerId,
    required int amount,
    required String currency,
    String? description,
    String? paymentMethodId,
    Map<String, dynamic>? metadata,
  }) async {
    _logOperation('createCharge: $customerId, $amount $currency');
    await _simulateDelay();

    if (_shouldFail()) {
      throw PaymentException(
        'Simulated failure: Charge creation failed',
        code: 'simulated_failure',
      );
    }

    final customer = _customers[customerId];
    if (customer == null) {
      throw CustomerNotFoundException(
        'Customer not found',
        customerId: customerId,
      );
    }

    // Check payment method
    final pmId = paymentMethodId ?? _defaultPaymentMethods[customerId];
    if (pmId == null) {
      throw NoDefaultPaymentMethodException(customerId);
    }

    final pm = _paymentMethods[pmId];
    if (pm == null) {
      throw PaymentMethodException(
        'Payment method not found',
        code: 'not_found',
      );
    }

    final id = _generateId('fake_ch');
    final now = DateTime.now();

    final charge = Charge(
      id: id,
      customerId: customerId,
      amount: amount,
      currency: currency.toLowerCase(),
      status: ChargeStatus.succeeded,
      description: description,
      receiptUrl: 'https://fake-processor.example.com/receipt/$id',
      refunded: false,
      refundedAmount: 0,
      processorChargeId: id,
      processor: ProcessorType.fake,
      createdAt: now,
      metadata: metadata,
    );

    _charges[id] = charge;
    _logOperation('Created charge: $id');
    return charge;
  }

  @override
  Future<Charge> getCharge(String chargeId) async {
    _logOperation('getCharge: $chargeId');
    await _simulateDelay();

    if (_shouldFail()) {
      throw PaymentException(
        'Simulated failure: Charge retrieval failed',
        code: 'simulated_failure',
      );
    }

    final charge = _charges[chargeId];
    if (charge == null) {
      throw PaymentException(
        'Charge not found',
        code: 'charge_not_found',
      );
    }

    return charge;
  }

  @override
  Future<List<Charge>> listCharges({
    String? customerId,
    int limit = 10,
  }) async {
    _logOperation('listCharges: customerId=$customerId, limit=$limit');
    await _simulateDelay();

    if (_shouldFail()) {
      throw PaymentException(
        'Simulated failure: Charge listing failed',
        code: 'simulated_failure',
      );
    }

    if (customerId != null) {
      final customer = _customers[customerId];
      if (customer == null) {
        throw CustomerNotFoundException(
        'Customer not found',
        customerId: customerId,
      );
      }
    }

    var charges = _charges.values.toList();

    if (customerId != null) {
      charges = charges.where((c) => c.customerId == customerId).toList();
    }

    // Sort by creation date (newest first)
    charges.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return charges.take(limit).toList();
  }

  @override
  Future<Charge> refundCharge({
    required String chargeId,
    int? amount,
    String? reason,
  }) async {
    _logOperation('refundCharge: $chargeId, amount=$amount');
    await _simulateDelay();

    if (_shouldFail()) {
      throw PaymentException(
        'Simulated failure: Charge refund failed',
        code: 'simulated_failure',
      );
    }

    final charge = _charges[chargeId];
    if (charge == null) {
      throw ChargeNotFoundException(chargeId);
    }

    final refundAmount = amount ?? charge.amount;
    final currentRefunded = charge.refundedAmount ?? 0;

    if (currentRefunded + refundAmount > charge.amount) {
      throw PaymentException(
        'Refund amount exceeds charge amount',
        code: 'invalid_refund_amount',
      );
    }

    final totalRefunded = currentRefunded + refundAmount;
    final isFullyRefunded = totalRefunded >= charge.amount;

    final updatedCharge = charge.copyWith(
      refunded: isFullyRefunded,
      refundedAmount: totalRefunded,
      status: isFullyRefunded ? ChargeStatus.refunded : charge.status,
    );

    _charges[chargeId] = updatedCharge;
    _logOperation('Refunded charge: $chargeId');
    return updatedCharge;
  }

  // ============================================================================
  // WEBHOOK HANDLING
  // ============================================================================

  @override
  Future<WebhookEvent> handleWebhook({
    required Map<String, dynamic> payload,
    String? signature,
  }) async {
    _logOperation('handleWebhook: ${payload['type']}');
    await _simulateDelay();

    if (_shouldFail()) {
      throw WebhookException(
        'Simulated failure: Webhook handling failed',
        code: 'simulated_failure',
      );
    }

    final type = payload['type'] as String?;
    if (type == null || type.isEmpty) {
      throw WebhookException(
        'Missing webhook event type',
        code: 'missing_event_type',
      );
    }

    final event = WebhookEvent(
      id: _generateId('fake_evt'),
      type: type,
      processor: ProcessorType.fake,
      data: payload,
      createdAt: DateTime.now(),
    );

    _logOperation('Processed webhook event: ${event.id}');
    return event;
  }

  @override
  bool verifyWebhookSignature({
    required String payload,
    required String signature,
    required String secret,
  }) {
    _logOperation('verifyWebhookSignature');

    // For fake processor, we just check if signature matches a simple pattern
    // In real implementation, this would use HMAC or similar
    return signature.startsWith('fake_sig_') && signature.length > 10;
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  @override
  ProcessorType get processorType => ProcessorType.fake;

  @override
  String get name => 'Fake Processor';

  @override
  bool get supportsTrialPeriods => true;

  @override
  bool get supportsPlanSwapping => true;

  @override
  bool get supportsProration => true;

  @override
  Future<bool> validateConfiguration() async {
    _logOperation('validateConfiguration');
    await _simulateDelay();

    // Fake processor is always valid
    return true;
  }

  // ============================================================================
  // TESTING UTILITIES
  // ============================================================================

  /// Gets all customers (for testing purposes)
  List<Customer> getAllCustomers() => _customers.values.toList();

  /// Gets all subscriptions (for testing purposes)
  List<Subscription> getAllSubscriptions() => _subscriptions.values.toList();

  /// Gets all charges (for testing purposes)
  List<Charge> getAllCharges() => _charges.values.toList();

  /// Gets all payment methods (for testing purposes)
  List<PaymentMethod> getAllPaymentMethods() => _paymentMethods.values.toList();

  /// Simulates a webhook event for testing
  WebhookEvent simulateWebhookEvent(String type, Map<String, dynamic> data) {
    _logOperation('simulateWebhookEvent: $type');
    return WebhookEvent(
      id: _generateId('fake_evt'),
      type: type,
      processor: ProcessorType.fake,
      data: data,
      createdAt: DateTime.now(),
    );
  }
}
