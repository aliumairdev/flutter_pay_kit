# Braintree Integration Guide

[Braintree](https://www.braintreepayments.com/) is a PayPal-owned payment gateway that offers a comprehensive payment solution with support for multiple payment methods.

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

### 1. Create a Braintree Account

1. Go to [braintreepayments.com](https://www.braintreepayments.com/)
2. Click "Get Started" or "Sign Up"
3. Complete the registration process
4. Link to PayPal account (required)
5. Complete business verification

### 2. Account Approval

- Braintree reviews your application
- May require additional documentation
- Business verification can take 1-3 days
- Sandbox access is immediate

### 3. Dashboard Access

Once approved:
- Access production dashboard
- Sandbox dashboard available immediately
- Separate credentials for each environment

## Getting API Credentials

### Merchant ID

1. Log in to Braintree Dashboard
2. Go to **Settings → Business**
3. Find your Merchant ID
4. Format: alphanumeric string (e.g., `abc123def456`)

### API Keys

1. Go to **Settings → API**
2. Click "Generate New API Key"
3. You'll receive:
   - **Public Key**: For client-side operations
   - **Private Key**: For server-side operations (keep secure!)

### Separate Keys for Environments

- **Sandbox**: Different keys for testing
- **Production**: Real keys for live transactions
- Never mix sandbox and production keys

## Configuration

### Basic Configuration

```dart
import 'package:flutter_universal_payments/flutter_universal_payments.dart';

final config = PaymentConfigurationBuilder()
  .useBraintree(
    merchantId: 'your_merchant_id',
    publicKey: 'your_public_key',
    privateKey: 'your_private_key',
    environment: BraintreeEnvironment.sandbox, // or .production
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
  .useBraintree(
    merchantId: const String.fromEnvironment('BRAINTREE_MERCHANT_ID'),
    publicKey: const String.fromEnvironment('BRAINTREE_PUBLIC_KEY'),
    privateKey: const String.fromEnvironment('BRAINTREE_PRIVATE_KEY'),
    environment: BraintreeEnvironment.production,
  )
  .build();
```

## Features

### Supported Features

✅ **Payment Methods**
- Credit/debit cards (Visa, Mastercard, Amex, Discover, JCB, Diners Club)
- PayPal
- Venmo (US only)
- Apple Pay
- Google Pay

✅ **Customer Management**
- Create and manage customer vault
- Store payment methods securely
- Customer metadata

✅ **Subscriptions**
- Recurring billing
- Multiple billing frequencies
- Trial periods
- Add-ons and discounts
- Proration

✅ **Transactions**
- One-time charges
- Partial refunds
- Full refunds
- Voids

✅ **Advanced Features**
- Fraud protection tools
- PCI compliance (Level 1)
- 3D Secure authentication
- Settlement reporting
- Batch processing

### Braintree-Specific Capabilities

**Vault**
- Securely store payment methods
- Tokenization for repeat charges
- Reduces PCI scope

**PayPal Integration**
- Native PayPal support
- Seamless customer experience
- Automatic PayPal account linking

**Fraud Tools**
- Kount fraud protection
- Custom risk rules
- AVS and CVV verification

## Limitations

❌ **Not Supported in This Package**
- Drop-in UI (use package widgets instead)
- Android/iOS native SDKs (API-based implementation)
- Bank transfers (ACH)
- Cryptocurrency

⚠️ **Restrictions**
- Requires PayPal business account
- Approval process for production
- Geographic restrictions apply
- Subscription plans must be created in dashboard

## Testing

### Sandbox Environment

```dart
final config = PaymentConfigurationBuilder()
  .useBraintree(
    merchantId: 'sandbox_merchant_id',
    publicKey: 'sandbox_public_key',
    privateKey: 'sandbox_private_key',
    environment: BraintreeEnvironment.sandbox,
  )
  .build();
```

### Test Credit Cards

**Successful Transactions**
```
Card Number: 4111 1111 1111 1111 (Visa)
Card Number: 5555 5555 5555 4444 (Mastercard)
Card Number: 3782 822463 10005 (American Express)
Card Number: 6011 1111 1111 1117 (Discover)

CVV: Any 3 digits (4 for Amex)
Expiry: Any future date
ZIP: Any 5 digits
```

**Failed Transactions**
```
Amount: $2000.00 - Processor declined
Amount: $2001.00 - Processor declined with message
Amount: $2010.00 - Gateway rejected (CVV)
Amount: $2020.00 - Gateway rejected (AVS)
```

### Test PayPal

1. Use PayPal Sandbox accounts
2. Create test accounts at [developer.paypal.com](https://developer.paypal.com)
3. Link to Braintree sandbox

### Testing Subscriptions

```dart
// Create subscription in sandbox
final subscription = await paymentService.subscribe(
  priceId: 'monthly_plan',  // Created in Braintree Dashboard
  paymentMethodToken: 'payment_method_token',
  trialDays: 14,
);

// Test scenarios:
// - Successful subscription creation
// - Failed payment
// - Subscription updates
// - Cancellations
```

### Sandbox Dashboard

Access sandbox at: https://sandbox.braintreegateway.com

Features:
- View all test transactions
- Manage test subscriptions
- Simulate webhook events
- Test settlement

## Webhooks

### Setting Up Webhooks

**1. Configure Webhook in Dashboard**

1. Go to **Settings → Webhooks**
2. Enter your webhook URL: `https://yourapp.com/webhooks/braintree`
3. Select webhook events:
   - `subscription_charged_successfully`
   - `subscription_charged_unsuccessfully`
   - `subscription_canceled`
   - `subscription_expired`
   - `subscription_went_active`
   - `subscription_went_past_due`

**2. Handle Webhooks in Backend**

```dart
router.post('/webhooks/braintree', (Request request) async {
  final signature = request.url.queryParameters['bt_signature'];
  final payload = request.url.queryParameters['bt_payload'];

  try {
    final event = await processor.handleWebhook(signature, payload);

    switch (event.type) {
      case 'subscription_charged_successfully':
        // Payment successful
        await extendSubscription(event.payload['subscription']);
        break;

      case 'subscription_charged_unsuccessfully':
        // Payment failed
        await notifyPaymentFailed(event.payload['subscription']);
        break;

      case 'subscription_canceled':
        // Subscription canceled
        await revokeAccess(event.payload['subscription']);
        break;

      case 'subscription_went_past_due':
        // Subscription past due
        await sendDunningEmail(event.payload['subscription']);
        break;

      case 'subscription_went_active':
        // Subscription became active
        await grantAccess(event.payload['subscription']);
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
| `subscription_charged_successfully` | Payment succeeded | Extend subscription |
| `subscription_charged_unsuccessfully` | Payment failed | Send reminder |
| `subscription_canceled` | Subscription ended | Revoke access |
| `subscription_expired` | Trial/grace period ended | Handle expiration |
| `subscription_went_active` | Subscription activated | Grant access |
| `subscription_went_past_due` | Payment overdue | Dunning process |
| `subscription_trial_ended` | Trial ended | Charge customer |

### Testing Webhooks

1. **Local Testing with ngrok**:
   ```bash
   ngrok http 3000
   # Use ngrok URL in Braintree Dashboard
   ```

2. **Trigger Test Webhooks**:
   - Go to sandbox dashboard
   - Navigate to webhook settings
   - Click "Send Sample Notification"

## Best Practices

### Security

**1. Never Expose Private Keys**

```dart
// ❌ BAD - Hardcoded
final privateKey = 'abc123';

// ✅ GOOD - Environment variable
final privateKey = const String.fromEnvironment('BRAINTREE_PRIVATE_KEY');
```

**2. Use Client Tokens for Mobile**

```dart
// Generate client token server-side
// Use it client-side for payment method creation
// Never use private key in mobile app
```

**3. Implement 3D Secure**

```dart
// Enable 3D Secure for European customers
// Reduces fraud and meets SCA requirements
// Braintree handles the flow automatically
```

### Payment Flow

**1. Tokenize Payment Method**

```dart
// Collect card details via PaymentCardInput widget
// Create payment method nonce (token)
final nonce = await createPaymentMethodNonce(cardData);

// Use nonce for subscription
await paymentService.setDefaultPaymentMethod(nonce);
```

**2. Create Customer First**

```dart
// Always create customer before subscription
await paymentService.initialize(
  email: 'customer@example.com',
  name: 'John Doe',
);
```

**3. Handle Payment Failures**

```dart
try {
  await paymentService.subscribe(priceId: 'plan_id');
} on ProcessorException catch (e) {
  if (e.code == 'processor_declined') {
    // Card issuer declined
    showError('Your bank declined the payment. Please try another card.');
  } else if (e.code == 'gateway_rejected_cvv') {
    // CVV mismatch
    showError('Invalid security code. Please check your card details.');
  }
}
```

### Subscription Management

**Create Plans in Dashboard**

1. Go to **Recurring Billing → Plans**
2. Click "Create New Plan"
3. Set:
   - Plan ID (e.g., `monthly_premium`)
   - Billing frequency
   - Price
   - Trial period
   - Grace period for failed payments

**Use Plan IDs in App**

```dart
final subscription = await paymentService.subscribe(
  priceId: 'monthly_premium', // From Braintree Dashboard
  trialDays: 7,
);
```

### Performance

**1. Cache Customer Data**

```dart
// Package handles caching automatically
final customer = await paymentService.getCurrentCustomer();
```

**2. Batch Operations**

```dart
// For multiple operations, batch them
// Braintree supports batch processing
```

**3. Async Processing**

```dart
// Use webhooks for async operations
// Don't wait for slow payment operations in UI
Future<void> processPayment() async {
  // Show loading indicator
  final subscription = await paymentService.subscribe(priceId: priceId);
  // Update UI
}
```

## Common Issues

### "Authentication Error"

**Cause**: Invalid API credentials

**Solution**:
- Verify merchant ID, public key, private key
- Check environment (sandbox vs production)
- Ensure keys are from same environment
- Regenerate keys if necessary

### "Payment Method Required"

**Cause**: Trying to create subscription without payment method

**Solution**:
```dart
// Add payment method first
await paymentService.setDefaultPaymentMethod(paymentMethodToken);

// Then create subscription
await paymentService.subscribe(priceId: priceId);
```

### "Plan Not Found"

**Cause**: Invalid plan ID or plan not created in dashboard

**Solution**:
- Verify plan exists in Braintree Dashboard
- Check plan ID spelling
- Ensure plan is active
- Check correct environment (sandbox/production)

### "Gateway Rejected"

**Cause**: CVV or AVS mismatch

**Solution**:
```dart
// Provide clear error messages
if (e.code == 'gateway_rejected_cvv') {
  showError('Security code (CVV) is incorrect');
} else if (e.code == 'gateway_rejected_avs') {
  showError('Billing address doesn\'t match');
}
```

## Resources

- [Braintree Developer Docs](https://developer.paypal.com/braintree/docs)
- [Braintree API Reference](https://developer.paypal.com/braintree/docs/reference/overview)
- [Braintree Testing Guide](https://developer.paypal.com/braintree/docs/guides/testing)
- [Webhook Documentation](https://developer.paypal.com/braintree/docs/guides/webhooks)
- [PCI Compliance Guide](https://developer.paypal.com/braintree/docs/guides/pci-compliance)

## Support

- **Email**: support@braintreepayments.com
- **Phone**: Available in dashboard
- **Help Center**: [articles.braintreepayments.com](https://articles.braintreepayments.com)
- **Status**: [status.braintreepayments.com](https://status.braintreepayments.com)

---

Ready to accept payments with Braintree! 💰
