import '../models/models.dart';

/// Abstract base class that all payment processors must implement.
///
/// This class defines a unified interface for interacting with various payment
/// processors (Stripe, Paddle, Braintree, Lemon Squeezy, Totalpay Global).
///
/// Each concrete implementation should handle the processor-specific API calls
/// while maintaining this consistent interface for the consuming application.
///
/// Example usage:
/// ```dart
/// final PaymentProcessor processor = StripeProcessor(apiKey: 'sk_...');
///
/// // Create a customer
/// final customer = await processor.createCustomer(
///   email: 'user@example.com',
///   name: 'John Doe',
/// );
///
/// // Add a payment method
/// final paymentMethod = await processor.addPaymentMethod(
///   customerId: customer.id,
///   paymentMethodToken: 'pm_...',
///   setAsDefault: true,
/// );
///
/// // Create a subscription
/// final subscription = await processor.createSubscription(
///   customerId: customer.id,
///   priceId: 'price_...',
///   trialDays: 14,
/// );
/// ```
abstract class PaymentProcessor {
  // ============================================================================
  // CUSTOMER MANAGEMENT
  // ============================================================================

  /// Creates a new customer in the payment processor's system.
  ///
  /// Parameters:
  /// - [email]: Required email address for the customer
  /// - [name]: Optional full name of the customer
  /// - [phone]: Optional phone number for the customer
  /// - [metadata]: Optional key-value pairs for storing additional information
  ///
  /// Returns a [Customer] object with the processor-assigned ID.
  ///
  /// Throws:
  /// - [PaymentException] if customer creation fails
  /// - [ValidationException] if the email is invalid
  /// - [NetworkException] if there's a network connectivity issue
  ///
  /// Example:
  /// ```dart
  /// final customer = await processor.createCustomer(
  ///   email: 'user@example.com',
  ///   name: 'John Doe',
  ///   phone: '+1234567890',
  ///   metadata: {'user_id': '12345', 'source': 'mobile_app'},
  /// );
  /// ```
  Future<Customer> createCustomer({
    required String email,
    String? name,
    String? phone,
    Map<String, dynamic>? metadata,
  });

  /// Retrieves an existing customer by their ID.
  ///
  /// Parameters:
  /// - [customerId]: The unique identifier of the customer
  ///
  /// Returns the [Customer] object if found.
  ///
  /// Throws:
  /// - [CustomerNotFoundException] if the customer doesn't exist
  /// - [PaymentException] if retrieval fails
  /// - [NetworkException] if there's a network connectivity issue
  ///
  /// Example:
  /// ```dart
  /// final customer = await processor.getCustomer('cus_abc123');
  /// print(customer.email);
  /// ```
  Future<Customer> getCustomer(String customerId);

  /// Updates an existing customer's information.
  ///
  /// Parameters:
  /// - [customerId]: The unique identifier of the customer to update
  /// - [email]: Optional new email address
  /// - [name]: Optional new name
  /// - [phone]: Optional new phone number
  /// - [metadata]: Optional metadata to update (merges with existing metadata)
  ///
  /// Returns the updated [Customer] object.
  ///
  /// Throws:
  /// - [CustomerNotFoundException] if the customer doesn't exist
  /// - [ValidationException] if the new email is invalid
  /// - [PaymentException] if update fails
  /// - [NetworkException] if there's a network connectivity issue
  ///
  /// Example:
  /// ```dart
  /// final updatedCustomer = await processor.updateCustomer(
  ///   'cus_abc123',
  ///   name: 'Jane Doe',
  ///   phone: '+1987654321',
  /// );
  /// ```
  Future<Customer> updateCustomer(
    String customerId, {
    String? email,
    String? name,
    String? phone,
    Map<String, dynamic>? metadata,
  });

  /// Deletes a customer from the payment processor's system.
  ///
  /// Parameters:
  /// - [customerId]: The unique identifier of the customer to delete
  ///
  /// **Warning**: This operation is typically irreversible. Ensure all active
  /// subscriptions are canceled before deleting a customer.
  ///
  /// Throws:
  /// - [CustomerNotFoundException] if the customer doesn't exist
  /// - [PaymentException] if deletion fails (e.g., active subscriptions exist)
  /// - [NetworkException] if there's a network connectivity issue
  ///
  /// Example:
  /// ```dart
  /// await processor.deleteCustomer('cus_abc123');
  /// ```
  Future<void> deleteCustomer(String customerId);

  // ============================================================================
  // PAYMENT METHODS
  // ============================================================================

  /// Adds a new payment method to a customer's account.
  ///
  /// Parameters:
  /// - [customerId]: The unique identifier of the customer
  /// - [paymentMethodToken]: Token representing the payment method (obtained
  ///   from the payment processor's client SDK or tokenization service)
  /// - [setAsDefault]: Whether to set this as the customer's default payment
  ///   method (defaults to false)
  ///
  /// Returns the created [PaymentMethod] object.
  ///
  /// Throws:
  /// - [CustomerNotFoundException] if the customer doesn't exist
  /// - [InvalidPaymentMethodException] if the token is invalid
  /// - [PaymentException] if adding the payment method fails
  /// - [NetworkException] if there's a network connectivity issue
  ///
  /// Example:
  /// ```dart
  /// final paymentMethod = await processor.addPaymentMethod(
  ///   customerId: 'cus_abc123',
  ///   paymentMethodToken: 'pm_token_xyz',
  ///   setAsDefault: true,
  /// );
  /// ```
  Future<PaymentMethod> addPaymentMethod({
    required String customerId,
    required String paymentMethodToken,
    bool setAsDefault = false,
  });

  /// Retrieves a specific payment method by its ID.
  ///
  /// Parameters:
  /// - [paymentMethodId]: The unique identifier of the payment method
  ///
  /// Returns the [PaymentMethod] object if found.
  ///
  /// Throws:
  /// - [PaymentMethodNotFoundException] if the payment method doesn't exist
  /// - [PaymentException] if retrieval fails
  /// - [NetworkException] if there's a network connectivity issue
  ///
  /// Example:
  /// ```dart
  /// final paymentMethod = await processor.getPaymentMethod('pm_abc123');
  /// print('Last 4: ${paymentMethod.last4}');
  /// ```
  Future<PaymentMethod> getPaymentMethod(String paymentMethodId);

  /// Lists all payment methods for a customer.
  ///
  /// Parameters:
  /// - [customerId]: The unique identifier of the customer
  ///
  /// Returns a list of [PaymentMethod] objects. Returns an empty list if the
  /// customer has no payment methods.
  ///
  /// Throws:
  /// - [CustomerNotFoundException] if the customer doesn't exist
  /// - [PaymentException] if retrieval fails
  /// - [NetworkException] if there's a network connectivity issue
  ///
  /// Example:
  /// ```dart
  /// final methods = await processor.listPaymentMethods('cus_abc123');
  /// for (final method in methods) {
  ///   print('${method.brand} ending in ${method.last4}');
  /// }
  /// ```
  Future<List<PaymentMethod>> listPaymentMethods(String customerId);

  /// Sets a payment method as the default for a customer.
  ///
  /// Parameters:
  /// - [customerId]: The unique identifier of the customer
  /// - [paymentMethodId]: The unique identifier of the payment method to set as default
  ///
  /// Returns the updated [PaymentMethod] object with `isDefault` set to true.
  ///
  /// Throws:
  /// - [CustomerNotFoundException] if the customer doesn't exist
  /// - [PaymentMethodNotFoundException] if the payment method doesn't exist
  /// - [PaymentException] if the update fails
  /// - [NetworkException] if there's a network connectivity issue
  ///
  /// Example:
  /// ```dart
  /// final defaultMethod = await processor.setDefaultPaymentMethod(
  ///   customerId: 'cus_abc123',
  ///   paymentMethodId: 'pm_xyz789',
  /// );
  /// ```
  Future<PaymentMethod> setDefaultPaymentMethod({
    required String customerId,
    required String paymentMethodId,
  });

  /// Removes a payment method from the system.
  ///
  /// Parameters:
  /// - [paymentMethodId]: The unique identifier of the payment method to remove
  ///
  /// **Warning**: If this is the default payment method and the customer has
  /// active subscriptions, the operation may fail or the processor may
  /// automatically assign a new default.
  ///
  /// Throws:
  /// - [PaymentMethodNotFoundException] if the payment method doesn't exist
  /// - [PaymentException] if deletion fails
  /// - [NetworkException] if there's a network connectivity issue
  ///
  /// Example:
  /// ```dart
  /// await processor.removePaymentMethod('pm_abc123');
  /// ```
  Future<void> removePaymentMethod(String paymentMethodId);

  // ============================================================================
  // SUBSCRIPTIONS
  // ============================================================================

  /// Creates a new subscription for a customer.
  ///
  /// Parameters:
  /// - [customerId]: The unique identifier of the customer
  /// - [priceId]: The unique identifier of the price/plan to subscribe to
  /// - [paymentMethodId]: Optional payment method ID. If not provided, uses
  ///   the customer's default payment method
  /// - [trialDays]: Optional number of trial days before charging begins
  /// - [quantity]: Number of seats/units for the subscription (defaults to 1)
  /// - [metadata]: Optional key-value pairs for storing additional information
  ///
  /// Returns the created [Subscription] object.
  ///
  /// Throws:
  /// - [CustomerNotFoundException] if the customer doesn't exist
  /// - [PriceNotFoundException] if the price/plan doesn't exist
  /// - [PaymentMethodNotFoundException] if specified payment method doesn't exist
  /// - [NoDefaultPaymentMethodException] if no payment method is specified and
  ///   customer has no default
  /// - [PaymentException] if subscription creation fails
  /// - [NetworkException] if there's a network connectivity issue
  ///
  /// Example:
  /// ```dart
  /// final subscription = await processor.createSubscription(
  ///   customerId: 'cus_abc123',
  ///   priceId: 'price_premium_monthly',
  ///   trialDays: 14,
  ///   quantity: 5,
  ///   metadata: {'team_id': 'team_xyz'},
  /// );
  /// ```
  Future<Subscription> createSubscription({
    required String customerId,
    required String priceId,
    String? paymentMethodId,
    int? trialDays,
    int quantity = 1,
    Map<String, dynamic>? metadata,
  });

  /// Retrieves a specific subscription by its ID.
  ///
  /// Parameters:
  /// - [subscriptionId]: The unique identifier of the subscription
  ///
  /// Returns the [Subscription] object if found.
  ///
  /// Throws:
  /// - [SubscriptionNotFoundException] if the subscription doesn't exist
  /// - [PaymentException] if retrieval fails
  /// - [NetworkException] if there's a network connectivity issue
  ///
  /// Example:
  /// ```dart
  /// final subscription = await processor.getSubscription('sub_abc123');
  /// print('Status: ${subscription.status}');
  /// ```
  Future<Subscription> getSubscription(String subscriptionId);

  /// Lists all subscriptions for a customer.
  ///
  /// Parameters:
  /// - [customerId]: The unique identifier of the customer
  ///
  /// Returns a list of [Subscription] objects. Returns an empty list if the
  /// customer has no subscriptions.
  ///
  /// Throws:
  /// - [CustomerNotFoundException] if the customer doesn't exist
  /// - [PaymentException] if retrieval fails
  /// - [NetworkException] if there's a network connectivity issue
  ///
  /// Example:
  /// ```dart
  /// final subscriptions = await processor.listSubscriptions('cus_abc123');
  /// for (final sub in subscriptions) {
  ///   print('${sub.id}: ${sub.status}');
  /// }
  /// ```
  Future<List<Subscription>> listSubscriptions(String customerId);

  /// Updates an existing subscription.
  ///
  /// Parameters:
  /// - [subscriptionId]: The unique identifier of the subscription to update
  /// - [priceId]: Optional new price/plan ID (use [swapPlan] for plan changes
  ///   with proration)
  /// - [quantity]: Optional new quantity
  /// - [metadata]: Optional metadata to update (merges with existing metadata)
  ///
  /// Returns the updated [Subscription] object.
  ///
  /// **Note**: For plan changes that require proration calculation, use
  /// [swapPlan] instead.
  ///
  /// Throws:
  /// - [SubscriptionNotFoundException] if the subscription doesn't exist
  /// - [PriceNotFoundException] if the new price doesn't exist
  /// - [PaymentException] if update fails
  /// - [NetworkException] if there's a network connectivity issue
  ///
  /// Example:
  /// ```dart
  /// final updated = await processor.updateSubscription(
  ///   subscriptionId: 'sub_abc123',
  ///   quantity: 10,
  ///   metadata: {'seats_added': '5'},
  /// );
  /// ```
  Future<Subscription> updateSubscription({
    required String subscriptionId,
    String? priceId,
    int? quantity,
    Map<String, dynamic>? metadata,
  });

  /// Cancels a subscription.
  ///
  /// Parameters:
  /// - [subscriptionId]: The unique identifier of the subscription to cancel
  /// - [immediate]: If true, cancels immediately. If false, cancels at the end
  ///   of the current billing period (defaults to false)
  ///
  /// Returns the updated [Subscription] object with canceled status or
  /// `cancelAtPeriodEnd` set to true.
  ///
  /// Throws:
  /// - [SubscriptionNotFoundException] if the subscription doesn't exist
  /// - [PaymentException] if cancellation fails
  /// - [NetworkException] if there's a network connectivity issue
  ///
  /// Example:
  /// ```dart
  /// // Cancel at period end (user retains access until then)
  /// final subscription = await processor.cancelSubscription(
  ///   subscriptionId: 'sub_abc123',
  ///   immediate: false,
  /// );
  ///
  /// // Cancel immediately (access revoked now)
  /// final subscription = await processor.cancelSubscription(
  ///   subscriptionId: 'sub_abc123',
  ///   immediate: true,
  /// );
  /// ```
  Future<Subscription> cancelSubscription({
    required String subscriptionId,
    bool immediate = false,
  });

  /// Resumes a canceled subscription.
  ///
  /// Parameters:
  /// - [subscriptionId]: The unique identifier of the subscription to resume
  ///
  /// This method can only resume subscriptions that were canceled with
  /// `immediate: false` and are still within their grace period.
  ///
  /// Returns the resumed [Subscription] object with active status.
  ///
  /// Throws:
  /// - [SubscriptionNotFoundException] if the subscription doesn't exist
  /// - [InvalidSubscriptionStateException] if the subscription cannot be resumed
  /// - [PaymentException] if resumption fails
  /// - [NetworkException] if there's a network connectivity issue
  ///
  /// Example:
  /// ```dart
  /// final resumed = await processor.resumeSubscription('sub_abc123');
  /// ```
  Future<Subscription> resumeSubscription(String subscriptionId);

  /// Pauses a subscription temporarily.
  ///
  /// Parameters:
  /// - [subscriptionId]: The unique identifier of the subscription to pause
  ///
  /// **Note**: Not all payment processors support pausing subscriptions.
  /// Check [supportsPlanSwapping] capability before using this method.
  ///
  /// Returns the paused [Subscription] object.
  ///
  /// Throws:
  /// - [SubscriptionNotFoundException] if the subscription doesn't exist
  /// - [UnsupportedOperationException] if the processor doesn't support pausing
  /// - [PaymentException] if pausing fails
  /// - [NetworkException] if there's a network connectivity issue
  ///
  /// Example:
  /// ```dart
  /// if (processor.supportsPlanSwapping) {
  ///   final paused = await processor.pauseSubscription('sub_abc123');
  /// }
  /// ```
  Future<Subscription> pauseSubscription(String subscriptionId);

  /// Swaps a subscription to a different plan/price.
  ///
  /// Parameters:
  /// - [subscriptionId]: The unique identifier of the subscription
  /// - [newPriceId]: The unique identifier of the new price/plan
  /// - [prorate]: Whether to prorate the charges based on time remaining in
  ///   the current billing period (defaults to true)
  ///
  /// When [prorate] is true:
  /// - If upgrading, customer is charged the difference immediately
  /// - If downgrading, credit is applied to the next invoice
  ///
  /// When [prorate] is false:
  /// - Changes take effect at the next billing period
  /// - No immediate charge or credit
  ///
  /// **Note**: Not all payment processors support plan swapping.
  /// Check [supportsPlanSwapping] and [supportsProration] capabilities.
  ///
  /// Returns the updated [Subscription] object with the new plan.
  ///
  /// Throws:
  /// - [SubscriptionNotFoundException] if the subscription doesn't exist
  /// - [PriceNotFoundException] if the new price doesn't exist
  /// - [UnsupportedOperationException] if the processor doesn't support plan swapping
  /// - [PaymentException] if the swap fails
  /// - [NetworkException] if there's a network connectivity issue
  ///
  /// Example:
  /// ```dart
  /// // Upgrade with immediate proration
  /// final upgraded = await processor.swapPlan(
  ///   subscriptionId: 'sub_abc123',
  ///   newPriceId: 'price_premium',
  ///   prorate: true,
  /// );
  ///
  /// // Downgrade at next billing period
  /// final downgraded = await processor.swapPlan(
  ///   subscriptionId: 'sub_abc123',
  ///   newPriceId: 'price_basic',
  ///   prorate: false,
  /// );
  /// ```
  Future<Subscription> swapPlan({
    required String subscriptionId,
    required String newPriceId,
    bool prorate = true,
  });

  // ============================================================================
  // CHARGES (ONE-TIME PAYMENTS)
  // ============================================================================

  /// Creates a one-time charge for a customer.
  ///
  /// Parameters:
  /// - [customerId]: The unique identifier of the customer to charge
  /// - [amount]: The amount to charge in the smallest currency unit (e.g.,
  ///   cents for USD, pence for GBP). For $10.00, pass 1000
  /// - [currency]: Three-letter ISO currency code (e.g., 'usd', 'eur', 'gbp')
  /// - [description]: Optional description of what the charge is for
  /// - [paymentMethodId]: Optional payment method ID. If not provided, uses
  ///   the customer's default payment method
  /// - [metadata]: Optional key-value pairs for storing additional information
  ///
  /// Returns the created [Charge] object.
  ///
  /// Throws:
  /// - [CustomerNotFoundException] if the customer doesn't exist
  /// - [PaymentMethodNotFoundException] if specified payment method doesn't exist
  /// - [NoDefaultPaymentMethodException] if no payment method is specified and
  ///   customer has no default
  /// - [InsufficientFundsException] if the charge is declined
  /// - [PaymentException] if charge creation fails
  /// - [NetworkException] if there's a network connectivity issue
  ///
  /// Example:
  /// ```dart
  /// // Charge $25.00 USD
  /// final charge = await processor.createCharge(
  ///   customerId: 'cus_abc123',
  ///   amount: 2500,
  ///   currency: 'usd',
  ///   description: 'One-time setup fee',
  ///   metadata: {'invoice_id': 'inv_12345'},
  /// );
  /// ```
  Future<Charge> createCharge({
    required String customerId,
    required int amount,
    required String currency,
    String? description,
    String? paymentMethodId,
    Map<String, dynamic>? metadata,
  });

  /// Retrieves a specific charge by its ID.
  ///
  /// Parameters:
  /// - [chargeId]: The unique identifier of the charge
  ///
  /// Returns the [Charge] object if found.
  ///
  /// Throws:
  /// - [ChargeNotFoundException] if the charge doesn't exist
  /// - [PaymentException] if retrieval fails
  /// - [NetworkException] if there's a network connectivity issue
  ///
  /// Example:
  /// ```dart
  /// final charge = await processor.getCharge('ch_abc123');
  /// print('Amount: ${charge.amount} ${charge.currency}');
  /// ```
  Future<Charge> getCharge(String chargeId);

  /// Lists charges with optional filtering.
  ///
  /// Parameters:
  /// - [customerId]: Optional customer ID to filter charges
  /// - [limit]: Maximum number of charges to return (defaults to 10)
  ///
  /// Returns a list of [Charge] objects, ordered by creation date (newest first).
  ///
  /// Throws:
  /// - [CustomerNotFoundException] if the specified customer doesn't exist
  /// - [PaymentException] if retrieval fails
  /// - [NetworkException] if there's a network connectivity issue
  ///
  /// Example:
  /// ```dart
  /// // Get last 20 charges for a customer
  /// final charges = await processor.listCharges(
  ///   customerId: 'cus_abc123',
  ///   limit: 20,
  /// );
  ///
  /// // Get last 10 charges across all customers
  /// final allCharges = await processor.listCharges(limit: 10);
  /// ```
  Future<List<Charge>> listCharges({
    String? customerId,
    int limit = 10,
  });

  /// Refunds a charge, either partially or fully.
  ///
  /// Parameters:
  /// - [chargeId]: The unique identifier of the charge to refund
  /// - [amount]: Optional amount to refund in the smallest currency unit.
  ///   If not provided, refunds the entire charge
  /// - [reason]: Optional reason for the refund (e.g., 'requested_by_customer',
  ///   'duplicate', 'fraudulent')
  ///
  /// Returns the updated [Charge] object with refund information.
  ///
  /// Throws:
  /// - [ChargeNotFoundException] if the charge doesn't exist
  /// - [InvalidRefundException] if the refund amount exceeds the charge amount
  ///   or the charge is already fully refunded
  /// - [PaymentException] if refund fails
  /// - [NetworkException] if there's a network connectivity issue
  ///
  /// Example:
  /// ```dart
  /// // Full refund
  /// final refunded = await processor.refundCharge(
  ///   chargeId: 'ch_abc123',
  ///   reason: 'requested_by_customer',
  /// );
  ///
  /// // Partial refund of $5.00
  /// final partialRefund = await processor.refundCharge(
  ///   chargeId: 'ch_abc123',
  ///   amount: 500,
  ///   reason: 'partial_return',
  /// );
  /// ```
  Future<Charge> refundCharge({
    required String chargeId,
    int? amount,
    String? reason,
  });

  // ============================================================================
  // WEBHOOK HANDLING
  // ============================================================================

  /// Handles an incoming webhook event from the payment processor.
  ///
  /// Parameters:
  /// - [payload]: The raw webhook payload as a map
  /// - [signature]: Optional webhook signature for verification (processor-specific)
  ///
  /// This method parses the processor-specific webhook format and converts it
  /// to a standardized [WebhookEvent] object.
  ///
  /// Returns a [WebhookEvent] object containing the parsed event data.
  ///
  /// Throws:
  /// - [InvalidWebhookException] if the signature verification fails or payload
  ///   is malformed
  /// - [PaymentException] if webhook handling fails
  ///
  /// Example:
  /// ```dart
  /// // In your webhook endpoint handler
  /// final event = await processor.handleWebhook(
  ///   payload: jsonDecode(request.body),
  ///   signature: request.headers['stripe-signature'],
  /// );
  ///
  /// switch (event.type) {
  ///   case 'customer.subscription.updated':
  ///     // Handle subscription update
  ///     break;
  ///   case 'charge.succeeded':
  ///     // Handle successful charge
  ///     break;
  /// }
  /// ```
  Future<WebhookEvent> handleWebhook({
    required Map<String, dynamic> payload,
    String? signature,
  });

  /// Verifies a webhook signature.
  ///
  /// Parameters:
  /// - [payload]: The raw webhook payload as a string
  /// - [signature]: The signature from the webhook headers
  /// - [secret]: The webhook signing secret from your processor dashboard
  ///
  /// Returns true if the signature is valid, false otherwise.
  ///
  /// **Security Note**: Always verify webhook signatures in production to ensure
  /// the webhook actually came from the payment processor and wasn't forged.
  ///
  /// Example:
  /// ```dart
  /// final isValid = processor.verifyWebhookSignature(
  ///   payload: request.body,
  ///   signature: request.headers['stripe-signature'] ?? '',
  ///   secret: 'whsec_...',
  /// );
  ///
  /// if (!isValid) {
  ///   throw Exception('Invalid webhook signature');
  /// }
  /// ```
  bool verifyWebhookSignature({
    required String payload,
    required String signature,
    required String secret,
  });

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// The type of payment processor this implementation represents.
  ///
  /// Example:
  /// ```dart
  /// if (processor.processorType == ProcessorType.stripe) {
  ///   // Stripe-specific logic
  /// }
  /// ```
  ProcessorType get processorType;

  /// Human-readable name of the payment processor.
  ///
  /// Example: 'Stripe', 'Paddle', 'Braintree'
  String get name;

  /// Whether this processor supports trial periods for subscriptions.
  ///
  /// If false, the [trialDays] parameter in [createSubscription] will be ignored.
  bool get supportsTrialPeriods;

  /// Whether this processor supports swapping between plans.
  ///
  /// If false, [swapPlan] will throw [UnsupportedOperationException].
  bool get supportsPlanSwapping;

  /// Whether this processor supports proration when swapping plans.
  ///
  /// If false, the [prorate] parameter in [swapPlan] will be ignored and
  /// changes will take effect at the next billing period.
  bool get supportsProration;

  /// Validates the processor configuration (API keys, environment setup, etc.).
  ///
  /// Returns true if the configuration is valid and the processor can make
  /// API calls successfully.
  ///
  /// This is useful for testing the integration during setup or for health
  /// checks in production.
  ///
  /// Throws:
  /// - [ConfigurationException] if configuration is invalid
  /// - [NetworkException] if there's a network connectivity issue
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   final isValid = await processor.validateConfiguration();
  ///   if (isValid) {
  ///     print('${processor.name} is configured correctly');
  ///   }
  /// } catch (e) {
  ///   print('Configuration error: $e');
  /// }
  /// ```
  Future<bool> validateConfiguration();
}
