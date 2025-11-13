# Lemon Squeezy Integration Guide

[Lemon Squeezy](https://www.lemonsqueezy.com/) is a modern merchant of record platform specifically designed for digital product creators and SaaS businesses.

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

### 1. Create a Lemon Squeezy Account

1. Go to [lemonsqueezy.com](https://www.lemonsqueezy.com/)
2. Click "Get Started" and sign up
3. Verify your email address
4. Complete your profile

### 2. Create a Store

1. In the dashboard, click "Create Store"
2. Enter store details:
   - Store name
   - URL slug
   - Currency
   - Country
3. Complete store setup

### 3. Activate Your Account

For live payments:
1. Go to Store Settings → Payments
2. Complete business verification
3. Add payout information (bank account or PayPal)
4. Submit for review (usually approved within 24-48 hours)

### Test Mode

- Lemon Squeezy provides a test mode toggle
- No separate test account needed
- Test mode uses the same API keys
- Stripe test cards work in test mode

## Getting API Credentials

### API Key

1. Go to **Settings → API**
2. Click "Create API Key"
3. Give it a name (e.g., "Production App")
4. Copy the API key (starts with `lemon_`)
5. **Important**: Store securely - it won't be shown again

### Store ID

1. Go to **Settings → Stores**
2. Click on your store
3. Find Store ID in the URL or settings
4. Format: Numeric ID (e.g., `12345`)

### Webhook Secret

1. Go to **Settings → Webhooks**
2. Create a webhook endpoint
3. Copy the signing secret
4. Used for webhook signature verification

## Configuration

### Basic Configuration

```dart
import 'package:flutter_universal_payments/flutter_universal_payments.dart';

final config = PaymentConfigurationBuilder()
  .useLemonSqueezy(
    apiKey: 'lemon_...',              // Your API key
    storeId: '12345',                 // Your store ID
    webhookSecret: 'whsec_...',       // Optional webhook secret
  )
  .enableLogging()
  .build();

await FlutterUniversalPayments.initialize(
  config: config,
  storage: storage,
);
```

### Production Configuration

```dart
final config = PaymentConfigurationBuilder()
  .useLemonSqueezy(
    apiKey: const String.fromEnvironment('LEMON_SQUEEZY_API_KEY'),
    storeId: const String.fromEnvironment('LEMON_SQUEEZY_STORE_ID'),
    webhookSecret: const String.fromEnvironment('LEMON_SQUEEZY_WEBHOOK_SECRET'),
  )
  .build();
```

## Features

### Supported Features

✅ **Product Types**
- Subscriptions (recurring billing)
- One-time purchases
- Digital downloads
- Software licenses
- Bundles

✅ **Payment Methods**
- Credit/debit cards
- PayPal
- Apple Pay
- Google Pay
- Bank transfers (high-value)

✅ **Subscriptions**
- Multiple billing frequencies (daily, weekly, monthly, yearly)
- Trial periods
- Usage-based billing
- Volume discounts
- Pause and resume

✅ **Customer Management**
- Customer portal (self-service)
- Email-based identification
- Custom data fields
- Order history

✅ **Lemon Squeezy-Specific Features**
- Automatic tax calculation (VAT, sales tax)
- Multi-currency support (150+ currencies)
- Email receipts and invoices
- Fraud detection
- Affiliate program support
- Discount codes
- License key management

### Merchant of Record Benefits

Lemon Squeezy acts as merchant of record:

- **Tax Compliance**: Automatic VAT and sales tax handling globally
- **Fraud Protection**: Built-in fraud detection and chargeback management
- **Customer Support**: Lemon Squeezy handles payment-related support
- **Global Reach**: Accept payments in 135+ countries
- **Lower Fees**: 5% + $0.50 per transaction (competitive pricing)

## Limitations

❌ **Not Supported**
- Physical product shipping
- Crypto payments
- Custom payment flows (must use Lemon Squeezy checkout)

⚠️ **Restrictions**
- 5% + $0.50 transaction fee
- Payout schedule (weekly or monthly)
- Requires approval for some business types
- Limited checkout customization

## Testing

### Test Mode

Enable test mode in your Lemon Squeezy dashboard:

1. Click "Test Mode" toggle in top bar
2. All transactions are test transactions
3. No real charges are made
4. Same API key works for both modes

```dart
// No code change needed - controlled via dashboard
final config = PaymentConfigurationBuilder()
  .useLemonSqueezy(
    apiKey: 'lemon_...',
    storeId: '12345',
  )
  .build();
```

### Test Cards

In test mode, use Stripe test cards:

**Successful Payment**
```
Card Number: 4242 4242 4242 4242
CVV: Any 3 digits
Expiry: Any future date
```

**Requires Authentication**
```
Card Number: 4000 0025 0000 3155
CVV: Any 3 digits
Expiry: Any future date
```

**Declined**
```
Card Number: 4000 0000 0000 0002
CVV: Any 3 digits
Expiry: Any future date
```

### Test PayPal

In test mode:
- PayPal sandbox is automatically used
- Complete payment with any test PayPal account
- No real money is transferred

### Testing Subscriptions

```dart
// Create test subscription
final subscription = await paymentService.subscribe(
  priceId: 'variant_123',  // Product variant ID from Lemon Squeezy
  trialDays: 14,
);

// Test scenarios:
// - Successful subscription
// - Failed payments
// - Plan changes
// - Cancellations
// - Refunds
```

## Webhooks

### Setting Up Webhooks

**1. Create Webhook Endpoint**

1. Go to **Settings → Webhooks**
2. Click "Add endpoint"
3. Enter URL: `https://yourapp.com/webhooks/lemonsqueezy`
4. Select events to receive
5. Copy the signing secret

**2. Handle Webhooks in Backend**

```dart
router.post('/webhooks/lemonsqueezy', (Request request) async {
  final signature = request.headers['x-signature'];
  final payload = await request.readAsString();

  try {
    final event = await processor.handleWebhook(signature, payload);

    switch (event.type) {
      case 'subscription_created':
        // New subscription
        final data = event.payload;
        await activateSubscription(
          userId: data['meta']['custom_data']['user_id'],
          subscriptionId: data['data']['id'],
        );
        break;

      case 'subscription_updated':
        // Subscription changed
        await updateSubscription(event.payload['data']);
        break;

      case 'subscription_cancelled':
        // Subscription canceled
        await revokeAccess(event.payload['data']);
        break;

      case 'subscription_payment_success':
        // Payment successful
        await extendSubscription(event.payload['data']);
        break;

      case 'subscription_payment_failed':
        // Payment failed
        await handleFailedPayment(event.payload['data']);
        break;

      case 'order_created':
        // One-time purchase
        await deliverProduct(event.payload['data']);
        break;

      case 'order_refunded':
        // Order refunded
        await handleRefund(event.payload['data']);
        break;
    }

    return Response.ok('Webhook processed');
  } catch (e) {
    return Response(400, body: 'Webhook error: $e');
  }
});
```

### Important Webhook Events

| Event | Description | Action |
|-------|-------------|--------|
| `subscription_created` | New subscription | Activate features |
| `subscription_updated` | Subscription modified | Update user plan |
| `subscription_cancelled` | Subscription ended | Revoke access |
| `subscription_resumed` | Subscription resumed | Restore access |
| `subscription_expired` | Subscription expired | Handle expiration |
| `subscription_paused` | Subscription paused | Pause access |
| `subscription_unpaused` | Subscription resumed | Resume access |
| `subscription_payment_success` | Payment succeeded | Extend period |
| `subscription_payment_failed` | Payment failed | Send notification |
| `subscription_payment_recovered` | Failed payment recovered | Update status |
| `order_created` | One-time purchase | Deliver product |
| `order_refunded` | Order refunded | Process refund |
| `license_key_created` | License key generated | Send to customer |

### Webhook Security

Lemon Squeezy signs webhooks for verification:

```dart
// Automatically verified by the package
final event = await processor.handleWebhook(signature, payload);

if (!event.verified) {
  throw WebhookException('Invalid webhook signature');
}
```

### Testing Webhooks

**1. Local Testing**

```bash
# Use ngrok to expose local server
ngrok http 3000

# Update webhook URL in Lemon Squeezy Dashboard
https://<your-ngrok-id>.ngrok.io/webhooks/lemonsqueezy
```

**2. Manual Testing**

- Lemon Squeezy Dashboard → Webhooks
- View webhook attempts
- Resend any webhook
- Test different event types

## Best Practices

### Product Setup

**Create Products in Dashboard**

1. Go to **Products**
2. Click "Create Product"
3. Set product type (subscription/one-time)
4. Create variants (pricing tiers)
5. Configure subscription settings:
   - Billing frequency
   - Trial period
   - Description
6. Copy Variant IDs for use in app

**Use Variant IDs**

```dart
// Use variant IDs from Lemon Squeezy Dashboard
final subscription = await paymentService.subscribe(
  priceId: 'variant_123456', // Variant ID
  trialDays: 14,
);
```

### Custom Data

Pass custom data to Lemon Squeezy:

```dart
await processor.createSubscription(
  customerId: customerId,
  priceId: 'variant_123',
  metadata: {
    'user_id': 'user_abc',
    'source': 'mobile_app',
    'plan_name': 'Premium',
  },
);

// Access in webhooks via meta.custom_data
```

### Customer Portal

Lemon Squeezy provides a hosted customer portal:

```dart
// Get customer portal URL
final portalUrl = 'https://app.lemonsqueezy.com/my-orders';

// Direct customers there for:
// - View invoices
// - Update payment method
// - Manage subscriptions
// - Download products
```

### Discount Codes

Create discount codes in dashboard:

1. Go to **Discounts**
2. Create discount code
3. Set percentage or fixed amount
4. Set expiration and usage limits

Customers can apply at checkout - no code changes needed.

### Error Handling

```dart
try {
  final subscription = await paymentService.subscribe(priceId: 'variant_123');
} on ProcessorException catch (e) {
  switch (e.code) {
    case 'invalid_variant':
      showError('This plan is no longer available.');
      break;
    case 'payment_failed':
      showError('Payment failed. Please check your card details.');
      break;
    case 'customer_deactivated':
      showError('Your account has been deactivated. Please contact support.');
      break;
    default:
      showError('An error occurred: ${e.message}');
  }
} on NetworkException catch (e) {
  showError('Network error. Please check your connection.');
}
```

### Multi-Currency

Lemon Squeezy handles currency conversion:

```dart
// Set base currency in store settings
// Customers see price in their local currency
// You receive payouts in your chosen currency
// No code changes needed
```

## Common Issues

### "Invalid API Key"

**Cause**: Wrong API key or key deleted

**Solution**:
- Verify API key in dashboard
- Regenerate key if necessary
- Check for extra spaces
- Ensure key is not expired

### "Store Not Found"

**Cause**: Wrong store ID

**Solution**:
- Verify store ID in Settings → Stores
- Check for typos
- Ensure store is activated

### "Product Not Found"

**Cause**: Invalid variant ID

**Solution**:
- Go to Products → Select product → Variants
- Copy correct variant ID
- Ensure variant is active
- Check test mode status

### "Webhook Signature Verification Failed"

**Cause**: Wrong signing secret or modified payload

**Solution**:
- Verify signing secret matches dashboard
- Use raw request body (not parsed JSON)
- Check webhook configuration
- Regenerate secret if needed

## Resources

- [Lemon Squeezy API Documentation](https://docs.lemonsqueezy.com/api)
- [Lemon Squeezy Webhooks](https://docs.lemonsqueezy.com/api/webhooks)
- [Subscription Guide](https://docs.lemonsqueezy.com/guides/subscriptions)
- [Testing Guide](https://docs.lemonsqueezy.com/guides/testing)
- [Help Center](https://help.lemonsqueezy.com/)

## Support

- **Email**: hello@lemonsqueezy.com
- **Help Docs**: [docs.lemonsqueezy.com](https://docs.lemonsqueezy.com)
- **Community**: [Lemon Squeezy Discord](https://discord.gg/lemonsqueezy)
- **Status**: [status.lemonsqueezy.com](https://status.lemonsqueezy.com)

---

Ready to sell digital products with Lemon Squeezy! 🍋
