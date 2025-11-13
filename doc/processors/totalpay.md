# Totalpay Integration Guide

[Totalpay Global](https://totalpay.global/) is an international payment processing platform designed for global businesses requiring multi-currency and cross-border payment capabilities.

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

### 1. Contact Totalpay

Totalpay is a B2B service - you'll need to contact them directly:

1. Visit [totalpay.global](https://totalpay.global/)
2. Click "Contact Sales" or "Get Started"
3. Provide business information
4. Discuss your payment processing needs
5. Sign merchant agreement

### 2. Account Approval Process

- Business verification (1-5 business days)
- Credit check may be required
- Approval depends on business type and volume
- Higher-risk businesses may need additional documentation

### 3. Account Activation

Once approved:
- Receive merchant account details
- Get API credentials
- Access to merchant dashboard
- Sandbox account for testing

## Getting API Credentials

### Merchant ID

Your unique merchant identifier:
- Provided during account setup
- Format: Alphanumeric string
- Same for sandbox and production

### API Key

Your API authentication key:
- Generated in merchant dashboard
- Can create multiple keys for different environments
- Keep secure - treat like a password

### Secret Key

For enhanced security:
- Used for signing requests
- Generated alongside API key
- Required for webhook verification

## Configuration

### Basic Configuration

```dart
import 'package:flutter_universal_payments/flutter_universal_payments.dart';

final config = PaymentConfigurationBuilder()
  .useTotalpay(
    merchantId: 'your_merchant_id',
    apiKey: 'your_api_key',
    secretKey: 'your_secret_key',
    environment: TotalpayEnvironment.sandbox, // or .production
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
  .useTotalpay(
    merchantId: const String.fromEnvironment('TOTALPAY_MERCHANT_ID'),
    apiKey: const String.fromEnvironment('TOTALPAY_API_KEY'),
    secretKey: const String.fromEnvironment('TOTALPAY_SECRET_KEY'),
    environment: TotalpayEnvironment.production,
  )
  .build();
```

## Features

### Supported Features

✅ **Payment Methods**
- Credit/debit cards (Visa, Mastercard, Amex, Discover, JCB, UnionPay)
- Alternative payment methods (varies by region)
- Digital wallets
- Bank transfers (select countries)

✅ **Multi-Currency**
- 150+ currencies supported
- Dynamic currency conversion
- Automatic exchange rate handling
- Settlement in your preferred currency

✅ **Customer Management**
- Customer vault
- Tokenization
- Multiple payment methods per customer
- Custom metadata

✅ **Subscriptions**
- Recurring billing
- Flexible billing cycles
- Trial periods
- Subscription modifications
- Proration support

✅ **Transactions**
- One-time charges
- Refunds (full and partial)
- Voids
- Pre-authorization and capture

✅ **Advanced Features**
- 3D Secure authentication
- Fraud detection tools
- Risk management
- Chargeback handling
- Multi-merchant support
- Batch processing

### Totalpay-Specific Capabilities

**Global Reach**
- Process payments in 200+ countries
- Local acquiring in major markets
- Optimized routing for better approval rates

**Risk Management**
- Real-time fraud screening
- Customizable risk rules
- Velocity controls
- Blacklist/whitelist management

**Reporting**
- Comprehensive transaction reports
- Settlement reports
- Reconciliation tools
- Custom report generation

## Limitations

❌ **Not Supported**
- Cryptocurrency
- Some high-risk business categories
- Direct bank account debits in all regions

⚠️ **Restrictions**
- Requires business verification
- Volume-based pricing (contact for rates)
- Some features region-specific
- Minimum processing volumes may apply

## Testing

### Sandbox Environment

```dart
final config = PaymentConfigurationBuilder()
  .useTotalpay(
    merchantId: 'sandbox_merchant_id',
    apiKey: 'sandbox_api_key',
    secretKey: 'sandbox_secret_key',
    environment: TotalpayEnvironment.sandbox,
  )
  .build();
```

### Test Cards

**Successful Transactions**
```
Card Number: 4111 1111 1111 1111 (Visa)
Card Number: 5500 0000 0000 0004 (Mastercard)
Card Number: 3400 0000 0000 009 (American Express)
CVV: Any 3 digits (4 for Amex)
Expiry: Any future date
```

**Declined Transactions**
```
Card Number: 4000 0000 0000 0002
Reason: Generic decline

Card Number: 4100 0000 0000 0019
Reason: Insufficient funds

Card Number: 4000 0000 0000 0069
Reason: Expired card
```

**3D Secure Testing**
```
Card Number: 4000 0000 0000 3220
Result: Requires 3D Secure authentication
```

### Amount-Based Testing

Totalpay also supports amount-based test scenarios:

```dart
// Amount endings determine response
// X.00 - Approved
// X.05 - Declined
// X.10 - Error
// X.51 - Insufficient funds

await paymentService.makePayment(
  amount: 10005, // $100.05 - Will be declined
  currency: 'USD',
  description: 'Test payment',
);
```

### Testing Subscriptions

```dart
// Create test subscription
final subscription = await paymentService.subscribe(
  priceId: 'plan_sandbox_monthly',
  trialDays: 7,
);

// Test scenarios in sandbox:
// - Successful billing
// - Failed billing
// - Plan upgrades/downgrades
// - Cancellations
```

## Webhooks

### Setting Up Webhooks

**1. Configure Webhook URL**

1. Log in to Totalpay merchant dashboard
2. Go to Settings → Webhooks
3. Add webhook endpoint: `https://yourapp.com/webhooks/totalpay`
4. Select events to receive
5. Save configuration

**2. Handle Webhooks in Backend**

```dart
router.post('/webhooks/totalpay', (Request request) async {
  final signature = request.headers['x-totalpay-signature'];
  final payload = await request.readAsString();

  try {
    final event = await processor.handleWebhook(signature, payload);

    switch (event.type) {
      case 'payment.success':
        // Payment successful
        await handleSuccessfulPayment(event.payload);
        break;

      case 'payment.failed':
        // Payment failed
        await handleFailedPayment(event.payload);
        break;

      case 'subscription.created':
        // New subscription
        await activateSubscription(event.payload);
        break;

      case 'subscription.renewed':
        // Subscription renewed
        await extendSubscription(event.payload);
        break;

      case 'subscription.cancelled':
        // Subscription canceled
        await revokeAccess(event.payload);
        break;

      case 'refund.processed':
        // Refund completed
        await processRefund(event.payload);
        break;

      case 'chargeback.received':
        // Chargeback filed
        await handleChargeback(event.payload);
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
| `payment.success` | Payment approved | Complete order |
| `payment.failed` | Payment declined | Notify customer |
| `payment.pending` | Payment in review | Wait for approval |
| `subscription.created` | New subscription | Activate features |
| `subscription.renewed` | Billing successful | Extend period |
| `subscription.failed` | Billing failed | Send reminder |
| `subscription.cancelled` | Subscription ended | Revoke access |
| `subscription.updated` | Subscription modified | Update plan |
| `refund.processed` | Refund completed | Update records |
| `refund.failed` | Refund failed | Handle manually |
| `chargeback.received` | Chargeback filed | Gather evidence |
| `chargeback.won` | Chargeback won | Update records |
| `chargeback.lost` | Chargeback lost | Process loss |

### Webhook Security

Totalpay signs webhooks for verification:

```dart
// Signature verification handled by package
final event = await processor.handleWebhook(signature, payload);

if (!event.verified) {
  // Log security incident
  logger.error('Invalid webhook signature from Totalpay');
  throw WebhookException('Invalid signature');
}
```

### Testing Webhooks

**1. Local Testing**

```bash
# Use ngrok for local development
ngrok http 3000

# Configure in Totalpay dashboard:
https://<your-id>.ngrok.io/webhooks/totalpay
```

**2. Webhook Simulator**

- Access webhook simulator in sandbox dashboard
- Trigger test events
- View webhook attempts and responses
- Debug webhook issues

## Best Practices

### Security

**1. Protect API Credentials**

```dart
// ❌ NEVER hardcode credentials
final apiKey = 'totalpay_abc123';

// ✅ Use environment variables
final apiKey = const String.fromEnvironment('TOTALPAY_API_KEY');
```

**2. Implement Request Signing**

```dart
// Package handles request signing automatically
// Ensures requests haven't been tampered with
```

**3. Use 3D Secure for High-Value Transactions**

```dart
// Enable 3D Secure for transactions > $500
// Reduces fraud and shifts liability
```

### Multi-Currency Handling

```dart
// Let customer choose currency
final availableCurrencies = ['USD', 'EUR', 'GBP', 'JPY', 'AUD'];

// Create charge in customer's currency
await paymentService.makePayment(
  amount: calculateAmount(selectedCurrency),
  currency: selectedCurrency,
  description: 'Product purchase',
);

// Totalpay handles conversion and settlement
```

### Subscription Management

**Create Plans**

1. Use Totalpay dashboard to create billing plans
2. Set plan details:
   - Billing frequency
   - Amount
   - Currency
   - Trial period
   - Grace period

**Implement in App**

```dart
final subscription = await paymentService.subscribe(
  priceId: 'plan_monthly_premium',  // From Totalpay dashboard
  trialDays: 14,
);
```

### Error Handling

```dart
try {
  final charge = await paymentService.makePayment(
    amount: 5000,
    currency: 'USD',
    description: 'Purchase',
  );
} on ProcessorException catch (e) {
  // Handle Totalpay-specific errors
  switch (e.code) {
    case 'insufficient_funds':
      showError('Insufficient funds. Please use a different card.');
      break;
    case 'card_declined':
      showError('Card declined. Please contact your bank.');
      break;
    case 'fraud_suspected':
      showError('Transaction flagged. Please verify your identity.');
      break;
    case 'currency_not_supported':
      showError('Currency not supported for this card.');
      break;
    default:
      showError('Payment error: ${e.message}');
  }
} on NetworkException catch (e) {
  showError('Network error. Please try again.');
}
```

### Reconciliation

```dart
// Fetch transaction history for reconciliation
final charges = await paymentService.getPaymentHistory(
  limit: 100,
);

// Match with your records
// Totalpay provides detailed transaction IDs
// Use for accounting and reporting
```

## Common Issues

### "Merchant Account Not Activated"

**Cause**: Account pending approval or suspended

**Solution**:
- Contact Totalpay support
- Complete verification requirements
- Check merchant dashboard status

### "Invalid Merchant ID"

**Cause**: Wrong merchant ID or environment mismatch

**Solution**:
- Verify merchant ID in dashboard
- Ensure correct environment (sandbox/production)
- Check for typos

### "Currency Not Supported"

**Cause**: Card doesn't support requested currency

**Solution**:
```dart
// Provide currency selection
// Fall back to USD if preferred currency fails
try {
  await makePayment(currency: 'EUR');
} catch (e) {
  await makePayment(currency: 'USD');
}
```

### "3D Secure Authentication Failed"

**Cause**: Customer failed authentication

**Solution**:
- Advise customer to contact bank
- Verify correct authentication method
- Try alternative payment method

## Resources

- **API Documentation**: Provided by Totalpay account manager
- **Merchant Dashboard**: [merchant.totalpay.global](https://merchant.totalpay.global)
- **Developer Portal**: Access via merchant dashboard
- **Integration Guides**: Available after account approval

## Support

- **Account Manager**: Assigned upon approval
- **Technical Support**: Available via merchant dashboard
- **Email**: support@totalpay.global
- **Phone**: Provided to merchants
- **Status Page**: [status.totalpay.global](https://status.totalpay.global)

## Additional Notes

### Regional Considerations

- Some features vary by region
- Local payment methods differ by country
- Compliance requirements vary
- Contact Totalpay for region-specific details

### Volume Discounts

- Pricing typically volume-based
- Higher volumes = lower rates
- Discuss with account manager
- Custom pricing available

---

Ready for global payment processing with Totalpay! 🌍
