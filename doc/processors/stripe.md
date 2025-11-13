# Stripe Integration Guide

[Stripe](https://stripe.com) is one of the most popular payment processors in the world, known for its developer-friendly API and comprehensive feature set.

## Table of Contents

- [Account Setup](#account-setup)
- [Getting API Credentials](#getting-api-credentials)
- [Configuration](#configuration)
- [Features](#features)
- [Limitations](#limitations)
- [Testing](#testing)
- [Webhooks](#webhooks)
- [Best Practices](#best-practices)

## Account Setup

### 1. Create a Stripe Account

1. Go to [stripe.com](https://stripe.com)
2. Click "Start now" and create your account
3. Complete the registration process
4. Verify your email address

### 2. Activate Your Account

For production use, you'll need to activate your account:

1. Go to Settings → Account settings
2. Complete business details
3. Add bank account information
4. Verify your identity (may require documentation)

### 3. Enable Test Mode

Stripe provides a test mode for development:

- Toggle "Test mode" in the top-right corner of the dashboard
- Test mode uses separate API keys and doesn't process real charges
- All test data is separate from production

## Getting API Credentials

### API Keys

1. Go to **Developers → API keys** in your Stripe Dashboard
2. You'll see two types of keys:

**Publishable Key** (Public)
- Starts with `pk_test_` (test) or `pk_live_` (production)
- Safe to embed in client-side code
- Used for client-side operations

**Secret Key** (Private)
- Starts with `sk_test_` (test) or `sk_live_` (production)
- Must be kept secure
- Used for server-side operations
- **Never** commit to version control

### Webhook Signing Secret

1. Go to **Developers → Webhooks**
2. Click "Add endpoint"
3. Enter your webhook URL: `https://yourapp.com/webhooks/stripe`
4. Select events to listen to:
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.payment_succeeded`
   - `invoice.payment_failed`
5. Click "Add endpoint"
6. Copy the **Signing secret** (starts with `whsec_`)

## Configuration

### Basic Configuration

```dart
import 'package:flutter_universal_payments/flutter_universal_payments.dart';

final config = PaymentConfigurationBuilder()
  .useStripe(
    publishableKey: 'pk_test_51ABC...', // Your publishable key
    secretKey: 'sk_test_51ABC...',      // Your secret key
    webhookSecret: 'whsec_...',         // Optional but recommended
  )
  .enableLogging()
  .setTimeout(Duration(seconds: 30))
  .build();

await FlutterUniversalPayments.initialize(
  config: config,
  storage: storage,
);
```

### Environment Variables

**Recommended**: Store credentials in environment variables:

```dart
final config = PaymentConfigurationBuilder()
  .useStripe(
    publishableKey: const String.fromEnvironment('STRIPE_PUBLISHABLE_KEY'),
    secretKey: const String.fromEnvironment('STRIPE_SECRET_KEY'),
    webhookSecret: const String.fromEnvironment('STRIPE_WEBHOOK_SECRET'),
  )
  .build();
```

Run your app with:

```bash
flutter run \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_... \
  --dart-define=STRIPE_SECRET_KEY=sk_test_... \
  --dart-define=STRIPE_WEBHOOK_SECRET=whsec_...
```

## Features

### Supported Features

✅ **Customer Management**
- Create, update, delete customers
- Store customer metadata
- Email and name management

✅ **Payment Methods**
- Credit/debit cards
- Multiple payment methods per customer
- Default payment method selection
- Card brand detection

✅ **Subscriptions**
- Recurring billing (daily, weekly, monthly, yearly)
- Trial periods
- Multiple subscriptions per customer
- Proration on plan changes
- Grace periods for cancelations

✅ **One-Time Payments**
- Single charges
- Custom amounts
- Payment descriptions
- Receipt URLs

✅ **Advanced Features**
- Webhooks with signature verification
- Idempotency keys for safe retries
- Metadata support on all resources
- Refunds

### Stripe-Specific Capabilities

**Setup Intents**
- Collect payment methods without charging
- Useful for trial periods

**Payment Intents**
- Strong Customer Authentication (SCA) support
- 3D Secure authentication
- Automatic payment method confirmation

**Checkout Sessions**
- Pre-built checkout pages (not directly supported, but can be integrated)

## Limitations

❌ **Not Supported**
- Bank transfers (ACH/SEPA) - Cards only
- Cryptocurrency
- Buy Now Pay Later (BNPL) options
- Gift cards
- Wallet payments (Apple Pay, Google Pay) through this package

⚠️ **Restrictions**
- Minimum charge amount: $0.50 USD (or equivalent)
- Maximum charge amount: Varies by country and currency
- Requires HTTPS for webhook endpoints
- Webhook signature verification required for security

## Testing

### Test Mode

Always use test mode during development:

1. Toggle to "Test mode" in the Stripe Dashboard
2. Use test API keys (`pk_test_...` and `sk_test_...`)
3. Use test card numbers
4. No real charges will be made

### Test Cards

Stripe provides test card numbers for various scenarios:

**Successful Payments**
```dart
// Visa
'4242424242424242'

// Mastercard
'5555555555554444'

// American Express
'378282246310005'

// Discover
'6011111111111117'
```

**Authentication Required (3D Secure)**
```dart
'4000002500003155'  // Requires authentication
'4000002760003184'  // Requires authentication (Brazil)
```

**Declined Cards**
```dart
'4000000000000002'  // Generic decline
'4000000000009995'  // Insufficient funds
'4000000000009987'  // Lost card
'4000000000009979'  // Stolen card
```

**Specific Errors**
```dart
'4000000000000069'  // Expired card
'4000000000000127'  // Incorrect CVC
'4000000000000119'  // Processing error
```

### Test Configuration

```dart
final testConfig = PaymentConfigurationBuilder()
  .useStripe(
    publishableKey: 'pk_test_...',
    secretKey: 'sk_test_...',
  )
  .enableLogging()
  .build();
```

### Testing Subscriptions

```dart
// Create a test subscription
final subscription = await paymentService.subscribe(
  priceId: 'price_test_123',
  paymentMethodToken: 'pm_card_visa', // Test payment method
  trialDays: 14,
);

// In Stripe Dashboard, you can:
// - Fast-forward time for subscription testing
// - Simulate billing events
// - Test webhook delivery
```

## Webhooks

### Setting Up Webhooks

**1. Create Webhook Endpoint in Your Backend**

```dart
// Example backend endpoint (e.g., using Dart Shelf)
router.post('/webhooks/stripe', (Request request) async {
  final signature = request.headers['stripe-signature'];
  final payload = await request.readAsString();

  try {
    // Verify webhook signature
    final event = await processor.handleWebhook(signature, payload);

    // Handle event
    switch (event.type) {
      case 'customer.subscription.created':
        // Handle new subscription
        break;
      case 'customer.subscription.updated':
        // Handle subscription update
        break;
      case 'invoice.payment_succeeded':
        // Handle successful payment
        break;
      case 'invoice.payment_failed':
        // Handle failed payment
        break;
    }

    return Response.ok('Webhook received');
  } catch (e) {
    return Response(400, body: 'Webhook error: $e');
  }
});
```

**2. Register Webhook in Stripe Dashboard**

1. Go to **Developers → Webhooks**
2. Click "Add endpoint"
3. Enter URL: `https://yourapp.com/webhooks/stripe`
4. Select events:
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `customer.subscription.trial_will_end`
   - `invoice.payment_succeeded`
   - `invoice.payment_failed`
   - `payment_method.attached`
   - `payment_method.detached`
5. Copy the signing secret

**3. Test Webhooks Locally**

Use Stripe CLI:

```bash
# Install Stripe CLI
brew install stripe/stripe-cli/stripe

# Login
stripe login

# Forward webhooks to local server
stripe listen --forward-to localhost:3000/webhooks/stripe

# Trigger test events
stripe trigger customer.subscription.created
```

Or use ngrok:

```bash
ngrok http 3000
# Use the ngrok URL in Stripe Dashboard
```

### Webhook Events

Important events to handle:

| Event | Description | Action |
|-------|-------------|--------|
| `customer.subscription.created` | New subscription created | Update user's subscription status |
| `customer.subscription.updated` | Subscription modified | Update local subscription data |
| `customer.subscription.deleted` | Subscription canceled | Revoke user access |
| `invoice.payment_succeeded` | Payment successful | Extend subscription period |
| `invoice.payment_failed` | Payment failed | Notify user, retry payment |
| `customer.subscription.trial_will_end` | Trial ending soon | Notify user (3 days before) |

## Best Practices

### Security

1. **Never expose secret keys**
   ```dart
   // ❌ BAD
   final secretKey = 'sk_live_ABC123';

   // ✅ GOOD
   final secretKey = const String.fromEnvironment('STRIPE_SECRET_KEY');
   ```

2. **Always verify webhook signatures**
   ```dart
   final event = await processor.handleWebhook(signature, payload);
   if (!event.verified) {
     throw WebhookException('Invalid signature');
   }
   ```

3. **Use HTTPS for all API calls** (handled automatically by the package)

4. **Implement idempotency** for charge operations (handled automatically)

### Performance

1. **Cache customer and subscription data**
   ```dart
   // The package handles this automatically
   final customer = await paymentService.getCurrentCustomer(); // Cached
   await paymentService.refreshCustomer(); // Force refresh
   ```

2. **Use metadata for custom data**
   ```dart
   await processor.createCustomer(
     email: 'user@example.com',
     name: 'John Doe',
     metadata: {
       'userId': '123',
       'plan': 'premium',
       'source': 'mobile_app',
     },
   );
   ```

3. **Handle rate limits**
   - Stripe has rate limits (100 reads/sec, 100 writes/sec)
   - The package implements exponential backoff
   - Use webhooks instead of polling

### Error Handling

```dart
try {
  final subscription = await paymentService.subscribe(priceId: 'price_123');
} on AuthenticationException catch (e) {
  // Invalid API key
  print('Auth error: ${e.message}');
} on ProcessorException catch (e) {
  // Stripe API error
  if (e.code == 'card_declined') {
    // Show user-friendly message
  }
} on NetworkException catch (e) {
  // Network/connectivity issue
  print('Network error: ${e.message}');
}
```

### Testing Checklist

- [ ] Test successful subscription creation
- [ ] Test declined payments
- [ ] Test 3D Secure authentication
- [ ] Test trial periods
- [ ] Test subscription cancellation
- [ ] Test plan changes
- [ ] Test webhook delivery
- [ ] Test webhook signature verification
- [ ] Test error scenarios
- [ ] Test with multiple card brands

## Common Issues

### "Invalid API Key"

**Cause**: Wrong API key or key for wrong environment

**Solution**:
- Verify you're using test keys in test mode
- Check for extra spaces or newlines
- Regenerate keys if necessary

### "Card Declined"

**Cause**: Test card declined or real card issue

**Solution**:
```dart
try {
  await paymentService.subscribe(priceId: priceId);
} on ProcessorException catch (e) {
  if (e.code == 'card_declined') {
    // Show user: "Your card was declined. Please try another card."
  }
}
```

### "Webhook Signature Verification Failed"

**Cause**: Invalid signature or wrong secret

**Solution**:
- Verify webhook secret is correct
- Check that you're using raw request body (not parsed JSON)
- Ensure timestamp tolerance (default: 5 minutes)

## Resources

- [Stripe API Documentation](https://stripe.com/docs/api)
- [Stripe Testing Guide](https://stripe.com/docs/testing)
- [Webhook Best Practices](https://stripe.com/docs/webhooks/best-practices)
- [SCA/3D Secure Guide](https://stripe.com/docs/strong-customer-authentication)
- [Stripe CLI](https://stripe.com/docs/stripe-cli)
- [Security Best Practices](https://stripe.com/docs/security/guide)

## Support

- [Stripe Support](https://support.stripe.com/)
- [Stripe Community](https://github.com/stripe)
- [Status Page](https://status.stripe.com/)

---

Ready to accept payments with Stripe! 💳
