# Paddle Integration Guide

[Paddle](https://paddle.com) is a complete payment solution designed specifically for SaaS businesses, acting as a merchant of record.

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

### 1. Create a Paddle Account

1. Go to [paddle.com](https://paddle.com)
2. Click "Get Started" and create your account
3. Complete the registration wizard
4. Verify your email address

### 2. Complete Seller Information

Paddle acts as merchant of record, so you'll need to provide:

1. Business information
2. Tax details
3. Bank account for payouts
4. Identity verification documents

### 3. Sandbox vs Production

Paddle provides separate environments:

- **Sandbox**: For testing, uses fake transactions
- **Production**: For live transactions with real money

## Getting API Credentials

### Vendor ID

1. Go to **Developer Tools → Authentication**
2. Your Vendor ID is displayed at the top
3. This is the same for both sandbox and production

### Auth Code

1. In **Developer Tools → Authentication**
2. Click "Generate Auth Code"
3. Copy and securely store the auth code
4. You can generate separate auth codes for different environments

### Public Key

1. In **Developer Tools → Public Key**
2. Copy your public key
3. Used for webhook signature verification

## Configuration

### Basic Configuration

```dart
import 'package:flutter_universal_payments/flutter_universal_payments.dart';

final config = PaymentConfigurationBuilder()
  .usePaddle(
    vendorId: '12345',                    // Your vendor ID
    authCode: 'your_auth_code',           // Your auth code
    publicKey: 'your_public_key',         // Your public key
    environment: PaddleEnvironment.sandbox, // or .production
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
  .usePaddle(
    vendorId: const String.fromEnvironment('PADDLE_VENDOR_ID'),
    authCode: const String.fromEnvironment('PADDLE_AUTH_CODE'),
    publicKey: const String.fromEnvironment('PADDLE_PUBLIC_KEY'),
    environment: PaddleEnvironment.production,
  )
  .build();
```

## Features

### Supported Features

✅ **Customer Management**
- Create and manage customers
- Email-based identification
- Custom metadata support

✅ **Subscriptions**
- Recurring billing plans
- Trial periods
- Multiple billing frequencies
- Proration on plan changes
- Pause and resume subscriptions

✅ **One-Time Payments**
- Single product purchases
- Custom checkout

✅ **Payment Methods**
- Credit/debit cards
- PayPal
- Wire transfers (for high-value)
- Local payment methods

✅ **Paddle-Specific Features**
- Automatic tax calculation (VAT, sales tax)
- Compliance handling (SCA, EU VAT)
- Multiple currencies
- Email receipts
- Dunning management

### Merchant of Record Benefits

Paddle acts as the merchant of record, which means:

- **Simplified Compliance**: Paddle handles VAT, sales tax, and regulatory requirements
- **Global Payments**: Accept payments in 200+ countries
- **Fraud Protection**: Built-in fraud detection
- **Payment Recovery**: Automatic retry for failed payments
- **Customer Support**: Paddle can handle customer payment queries

## Limitations

❌ **Not Supported**
- Usage-based billing
- Custom invoice generation
- Direct bank transfers in all regions

⚠️ **Restrictions**
- 5% + 50¢ per transaction fee (Paddle's take)
- Payouts on specific schedule (varies by plan)
- Limited customization of checkout flow
- Requires business registration in some countries

## Testing

### Sandbox Mode

```dart
final config = PaymentConfigurationBuilder()
  .usePaddle(
    vendorId: '12345',
    authCode: 'test_auth_code',
    publicKey: 'test_public_key',
    environment: PaddleEnvironment.sandbox,
  )
  .build();
```

### Test Cards

In sandbox mode, use these test cards:

**Successful Payment**
```
Card Number: 4242 4242 4242 4242
CVV: Any 3 digits
Expiry: Any future date
```

**Declined Payment**
```
Card Number: 4000 0000 0000 0002
CVV: Any 3 digits
Expiry: Any future date
```

**Requires Authentication**
```
Card Number: 4000 0025 0000 3155
CVV: Any 3 digits
Expiry: Any future date
```

### Test PayPal

In sandbox:
- Use PayPal sandbox account
- Create test accounts at developer.paypal.com
- Link to Paddle sandbox

### Testing Subscriptions

```dart
// Create test subscription
final subscription = await paymentService.subscribe(
  priceId: 'sandbox_plan_123',
  trialDays: 7,
);

// Paddle Dashboard lets you:
// - Simulate subscription events
// - Test payment failures
// - Fast-forward billing cycles
```

### Sandbox Limitations

- Some features may behave differently
- Webhooks work the same way
- No real money or emails sent
- Subscription cycles can be accelerated for testing

## Webhooks

### Setting Up Webhooks

**1. Configure Webhook URL**

1. Go to **Developer Tools → Webhooks**
2. Enter your webhook URL: `https://yourapp.com/webhooks/paddle`
3. Save the configuration

**2. Handle Webhooks in Your Backend**

```dart
router.post('/webhooks/paddle', (Request request) async {
  final signature = request.headers['paddle-signature'];
  final payload = await request.readAsString();

  try {
    final event = await processor.handleWebhook(signature, payload);

    switch (event.type) {
      case 'subscription_created':
        // Handle new subscription
        final data = event.payload;
        await updateUserSubscription(data['subscription_id']);
        break;

      case 'subscription_updated':
        // Handle subscription update
        break;

      case 'subscription_cancelled':
        // Handle cancellation
        await revokeUserAccess(data['user_id']);
        break;

      case 'payment_succeeded':
        // Handle successful payment
        break;

      case 'payment_failed':
        // Handle failed payment
        await notifyUserPaymentFailed(data['email']);
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
| `subscription_created` | New subscription | Activate user features |
| `subscription_updated` | Subscription changed | Update user's plan |
| `subscription_cancelled` | Subscription ended | Revoke access |
| `subscription_payment_succeeded` | Payment successful | Extend subscription |
| `subscription_payment_failed` | Payment failed | Send reminder |
| `payment_succeeded` | One-time payment success | Deliver product |
| `payment_refunded` | Payment refunded | Handle refund |

### Webhook Security

Paddle signs webhooks with your public key:

```dart
// Automatically verified by the package
final event = await processor.handleWebhook(signature, payload);

if (!event.verified) {
  throw WebhookException('Invalid webhook signature');
}
```

### Testing Webhooks

1. Use ngrok for local testing:
   ```bash
   ngrok http 3000
   ```

2. In Paddle Dashboard:
   - Go to Developer Tools → Webhooks
   - Use ngrok URL
   - Test webhook delivery

3. Use Paddle's webhook simulator:
   - Developer Tools → Webhook History
   - Resend any webhook event

## Best Practices

### Pricing Configuration

**Create Products in Paddle Dashboard**

1. Go to **Catalog → Products**
2. Click "Create Product"
3. Set product details:
   - Name and description
   - Base price (Paddle handles currency conversion)
   - Tax category
4. Create subscription plans:
   - Billing frequency (monthly, yearly, etc.)
   - Trial periods
   - Setup fees

**Use Product IDs in Your App**

```dart
final subscription = await paymentService.subscribe(
  priceId: 'paddle_plan_12345', // From Paddle Dashboard
  trialDays: 14,
);
```

### Currency Handling

Paddle supports 150+ currencies:

```dart
// Paddle automatically handles currency conversion
// Just specify your base currency in the dashboard
final charge = await paymentService.makePayment(
  amount: 2999, // $29.99 USD
  currency: 'USD',
  description: 'Premium upgrade',
);

// Customer sees price in their local currency
// You receive payout in your chosen currency
```

### Tax Compliance

Paddle handles all tax compliance:

- Automatic VAT calculation for EU
- US sales tax calculation
- Tax registration in required jurisdictions
- Tax reporting

No action needed on your side!

### Customer Communication

Paddle sends automated emails:
- Payment receipts
- Subscription confirmations
- Payment failure notifications
- Cancellation confirmations

Customize email templates in Paddle Dashboard.

### Error Handling

```dart
try {
  final subscription = await paymentService.subscribe(priceId: 'plan_123');
} on ProcessorException catch (e) {
  // Paddle-specific error
  switch (e.code) {
    case 'payment_declined':
      // Card declined
      showError('Payment was declined. Please try another card.');
      break;
    case 'invalid_product':
      // Product/plan doesn't exist
      showError('This plan is no longer available.');
      break;
    case 'subscription_exists':
      // Already subscribed
      showError('You already have an active subscription.');
      break;
    default:
      showError('Payment error: ${e.message}');
  }
} on NetworkException catch (e) {
  showError('Network error. Please check your connection.');
}
```

### Subscription Management

```dart
// Check subscription status
final subscription = await paymentService.getActiveSubscription('product_id');

if (subscription != null) {
  if (subscription.cancelAtPeriodEnd) {
    // Show "Resume subscription" option
    await paymentService.resumeSubscription(id: subscription.id);
  } else {
    // Show "Cancel subscription" option
    await paymentService.cancelSubscription(
      id: subscription.id,
      immediate: false, // Cancel at period end
    );
  }
}
```

### Plan Changes

```dart
// Upgrade/downgrade plan
await paymentService.changePlan(
  subscriptionId: subscription.id,
  newPriceId: 'new_plan_id',
);

// Paddle automatically handles:
// - Proration
// - Immediate vs end-of-period changes
// - Invoice generation
```

## Common Issues

### "Invalid Vendor ID"

**Cause**: Wrong vendor ID or environment mismatch

**Solution**:
- Verify vendor ID in Paddle Dashboard
- Ensure you're using correct environment (sandbox/production)
- Check for typos or extra characters

### "Auth Code Expired"

**Cause**: Auth code was regenerated or revoked

**Solution**:
- Generate new auth code in Paddle Dashboard
- Update your app configuration
- Store securely

### "Product Not Found"

**Cause**: Invalid price/plan ID or wrong environment

**Solution**:
- Verify plan ID in Paddle Dashboard
- Check that plan is active
- Ensure using correct environment's plan ID

### "Webhook Signature Verification Failed"

**Cause**: Wrong public key or tampered payload

**Solution**:
- Verify public key matches dashboard
- Ensure using raw request body
- Check Paddle's webhook documentation

## Resources

- [Paddle API Documentation](https://developer.paddle.com/api-reference)
- [Paddle Webhooks Guide](https://developer.paddle.com/webhooks/overview)
- [Paddle Testing Guide](https://developer.paddle.com/guides/how-tos/testing)
- [Paddle Billing Guide](https://developer.paddle.com/build/billing)
- [Paddle Support](https://paddle.com/support)

## Support

- **Email**: developers@paddle.com
- **Community**: [Paddle Developer Community](https://developer.paddle.com/community)
- **Status**: [status.paddle.com](https://status.paddle.com)

---

Ready to sell globally with Paddle! 🌍
