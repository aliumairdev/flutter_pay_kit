# Getting Started with Flutter Universal Payments

This guide will walk you through setting up Flutter Universal Payments in your Flutter app and creating your first subscription.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Basic Setup](#basic-setup)
- [Processor Setup](#processor-setup)
  - [Stripe](#stripe-setup)
  - [Paddle](#paddle-setup)
  - [Braintree](#braintree-setup)
  - [Lemon Squeezy](#lemon-squeezy-setup)
  - [Totalpay](#totalpay-setup)
  - [Fake (Testing)](#fake-processor-setup)
- [Storage Implementation](#storage-implementation)
- [First Subscription](#first-subscription)
- [Testing with Sandbox](#testing-with-sandbox)
- [Next Steps](#next-steps)

## Prerequisites

Before you begin, ensure you have:

- Flutter SDK 3.10.0 or higher
- Dart SDK 3.0.0 or higher
- An account with at least one payment processor (or use Fake processor for testing)
- Basic understanding of Flutter and Dart

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_universal_payments: ^0.1.0
  flutter_riverpod: ^2.5.0  # For state management
  flutter_secure_storage: ^9.0.0  # For secure storage
```

Run:

```bash
flutter pub get
```

## Basic Setup

### 1. Import the Package

```dart
import 'package:flutter_universal_payments/flutter_universal_payments.dart';
```

### 2. Create a Storage Implementation

You need to provide a `Storage` implementation. Here's a simple example using `SharedPreferences`:

```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_universal_payments/flutter_universal_payments.dart';

class SharedPreferencesStorage implements Storage {
  final SharedPreferences _prefs;

  SharedPreferencesStorage(this._prefs);

  static Future<SharedPreferencesStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesStorage(prefs);
  }

  @override
  Future<String?> getString(String key) async {
    return _prefs.getString(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  Future<int?> getInt(String key) async {
    return _prefs.getInt(key);
  }

  @override
  Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  @override
  Future<bool?> getBool(String key) async {
    return _prefs.getBool(key);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  @override
  Future<T?> getObject<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return null;
    return fromJson(json.decode(jsonString));
  }

  @override
  Future<void> setObject<T>(
    String key,
    T value,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    await _prefs.setString(key, json.encode(toJson(value)));
  }

  @override
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  @override
  Future<bool> containsKey(String key) async {
    return _prefs.containsKey(key);
  }

  @override
  Future<void> clear() async {
    await _prefs.clear();
  }
}
```

See [Storage Implementation](#storage-implementation) section below for more details.

### 3. Initialize the Package

In your app's initialization (typically in `main.dart`):

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create storage
  final storage = await SharedPreferencesStorage.create();

  // Configure payment processor
  final config = PaymentConfigurationBuilder()
    .useStripe(
      publishableKey: 'pk_test_...',
      secretKey: 'sk_test_...',
      webhookSecret: 'whsec_...',
    )
    .enableLogging()
    .setTimeout(Duration(seconds: 30))
    .build();

  // Initialize
  await FlutterUniversalPayments.initialize(
    config: config,
    storage: storage,
  );

  runApp(
    ProviderScope(  // Riverpod provider scope
      child: MyApp(),
    ),
  );
}
```

## Processor Setup

### Stripe Setup

**1. Get Your API Keys**

1. Sign up at [stripe.com](https://stripe.com)
2. Go to Developers → API keys
3. Copy your Publishable key (starts with `pk_test_` for test mode)
4. Copy your Secret key (starts with `sk_test_` for test mode)

**2. Get Webhook Secret (Optional but Recommended)**

1. Go to Developers → Webhooks
2. Click "Add endpoint"
3. Enter your endpoint URL (e.g., `https://yourapp.com/webhooks/stripe`)
4. Select events to listen for
5. Copy the webhook signing secret (starts with `whsec_`)

**3. Configure in Your App**

```dart
final config = PaymentConfigurationBuilder()
  .useStripe(
    publishableKey: 'pk_test_51ABC...',
    secretKey: 'sk_test_51ABC...',
    webhookSecret: 'whsec_...', // Optional
  )
  .enableLogging()
  .build();
```

**4. Create Products and Prices**

1. Go to Products in your Stripe Dashboard
2. Click "Add product"
3. Set up pricing (one-time or recurring)
4. Copy the Price ID (starts with `price_`)

See [stripe.md](processors/stripe.md) for detailed Stripe documentation.

### Paddle Setup

**1. Get Your Credentials**

1. Sign up at [paddle.com](https://paddle.com)
2. Go to Developer Tools → Authentication
3. Copy your Vendor ID
4. Generate an Auth Code
5. Copy your Public Key

**2. Choose Environment**

- Use `PaddleEnvironment.sandbox` for testing
- Use `PaddleEnvironment.production` for live

**3. Configure in Your App**

```dart
final config = PaymentConfigurationBuilder()
  .usePaddle(
    vendorId: '12345',
    authCode: 'your_auth_code',
    publicKey: 'your_public_key',
    environment: PaddleEnvironment.sandbox,
  )
  .enableLogging()
  .build();
```

**4. Set Up Products**

1. Go to Catalog → Products
2. Create a subscription plan
3. Copy the Plan ID

See [paddle.md](processors/paddle.md) for detailed Paddle documentation.

### Braintree Setup

**1. Get Your Credentials**

1. Sign up at [braintreepayments.com](https://www.braintreepayments.com/)
2. Go to Settings → API
3. Copy your Merchant ID
4. Generate API credentials (Public Key and Private Key)

**2. Choose Environment**

- Use `BraintreeEnvironment.sandbox` for testing
- Use `BraintreeEnvironment.production` for live

**3. Configure in Your App**

```dart
final config = PaymentConfigurationBuilder()
  .useBraintree(
    merchantId: 'your_merchant_id',
    publicKey: 'your_public_key',
    privateKey: 'your_private_key',
    environment: BraintreeEnvironment.sandbox,
  )
  .enableLogging()
  .build();
```

See [braintree.md](processors/braintree.md) for detailed Braintree documentation.

### Lemon Squeezy Setup

**1. Get Your API Key**

1. Sign up at [lemonsqueezy.com](https://www.lemonsqueezy.com/)
2. Go to Settings → API
3. Create a new API key
4. Copy your API Key and Store ID

**2. Get Webhook Secret (Optional)**

1. Go to Settings → Webhooks
2. Create a new webhook
3. Copy the signing secret

**3. Configure in Your App**

```dart
final config = PaymentConfigurationBuilder()
  .useLemonSqueezy(
    apiKey: 'your_api_key',
    storeId: 'your_store_id',
    webhookSecret: 'your_webhook_secret', // Optional
  )
  .enableLogging()
  .build();
```

See [lemon_squeezy.md](processors/lemon_squeezy.md) for detailed Lemon Squeezy documentation.

### Totalpay Setup

**1. Get Your Credentials**

1. Contact Totalpay for an account
2. Get your Merchant ID
3. Get your API Key and Secret Key

**2. Choose Environment**

- Use `TotalpayEnvironment.sandbox` for testing
- Use `TotalpayEnvironment.production` for live

**3. Configure in Your App**

```dart
final config = PaymentConfigurationBuilder()
  .useTotalpay(
    merchantId: 'your_merchant_id',
    apiKey: 'your_api_key',
    secretKey: 'your_secret_key',
    environment: TotalpayEnvironment.sandbox,
  )
  .enableLogging()
  .build();
```

See [totalpay.md](processors/totalpay.md) for detailed Totalpay documentation.

### Fake Processor Setup

Perfect for development and testing without real payment processors:

```dart
final config = PaymentConfigurationBuilder()
  .useFake(
    simulateDelays: true,
    delayDuration: Duration(seconds: 2),
    failureRate: 0.1, // 10% of operations will fail
  )
  .enableLogging()
  .build();
```

The Fake processor:
- Simulates all payment operations
- Can simulate delays for realistic testing
- Supports configurable failure rates
- Generates fake IDs and tokens
- No real API calls or charges

## Storage Implementation

The package requires a `Storage` implementation for caching payment data. Here are examples for different storage backends:

### SharedPreferences Storage (Simple)

```dart
class SharedPreferencesStorage implements Storage {
  final SharedPreferences _prefs;

  SharedPreferencesStorage(this._prefs);

  static Future<SharedPreferencesStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesStorage(prefs);
  }

  // Implement all Storage methods (see Basic Setup above)
}
```

### Secure Storage (Recommended for Production)

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageImpl implements Storage {
  final FlutterSecureStorage _storage;

  SecureStorageImpl(this._storage);

  static SecureStorageImpl create() {
    return SecureStorageImpl(
      const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      ),
    );
  }

  @override
  Future<String?> getString(String key) async {
    return await _storage.read(key: key);
  }

  @override
  Future<void> setString(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  @override
  Future<int?> getInt(String key) async {
    final value = await _storage.read(key: key);
    return value != null ? int.tryParse(value) : null;
  }

  @override
  Future<void> setInt(String key, int value) async {
    await _storage.write(key: key, value: value.toString());
  }

  // ... implement other methods
}
```

### In-Memory Storage (Testing Only)

```dart
class InMemoryStorage implements Storage {
  final Map<String, dynamic> _data = {};

  @override
  Future<String?> getString(String key) async => _data[key] as String?;

  @override
  Future<void> setString(String key, String value) async {
    _data[key] = value;
  }

  // ... implement other methods
}
```

## First Subscription

Now that you're set up, let's create your first subscription:

### 1. Initialize Customer

```dart
final paymentService = FlutterUniversalPayments.instance;

await paymentService.initialize(
  email: 'customer@example.com',
  name: 'John Doe',
  phone: '+1234567890', // Optional
);
```

### 2. Add Payment Method (If Required)

Some processors require a payment method before creating a subscription:

```dart
// In a real app, you'd collect this from the user via PaymentCardInput widget
final paymentMethodToken = 'pm_card_visa'; // From your processor

await paymentService.setDefaultPaymentMethod(paymentMethodToken);
```

### 3. Create Subscription

```dart
try {
  final subscription = await paymentService.subscribe(
    priceId: 'price_monthly_999', // Your price ID from the processor
    trialDays: 14, // Optional trial period
  );

  print('Subscription created!');
  print('Status: ${subscription.status}');
  print('Trial ends: ${subscription.trialEnd}');
  print('Next billing: ${subscription.currentPeriodEnd}');

} on ProcessorException catch (e) {
  print('Processor error: ${e.message}');
} on ValidationException catch (e) {
  print('Validation error: ${e.message}');
} on PaymentException catch (e) {
  print('Payment error: ${e.message}');
}
```

### 4. Check Subscription Status

```dart
// Check if user has active subscription
final hasActive = await paymentService.hasActiveSubscription('product_id');

// Check if on trial
final isOnTrial = await paymentService.isOnTrial('product_id');

// Get active subscription
final subscription = await paymentService.getActiveSubscription('product_id');

if (subscription != null) {
  print('Active until: ${subscription.currentPeriodEnd}');
  print('Days until due: ${subscription.daysUntilDue()}');
}
```

### 5. Using Riverpod Providers

```dart
class MySubscriptionScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync = ref.watch(activeSubscriptionProvider);

    return subscriptionAsync.when(
      data: (subscription) {
        if (subscription == null) {
          return Text('No active subscription');
        }

        return Column(
          children: [
            Text('Status: ${subscription.status}'),
            if (subscription.isOnTrial)
              Text('Trial ends: ${subscription.trialEnd}'),
            SubscriptionStatusWidget(subscription: subscription),
          ],
        );
      },
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

## Testing with Sandbox

### Stripe Test Cards

```dart
// Successful payment
'4242424242424242'

// Requires authentication (3D Secure)
'4000002500003155'

// Declined
'4000000000000002'

// Insufficient funds
'4000000000009995'
```

### Paddle Sandbox Mode

When using `PaddleEnvironment.sandbox`:
- No real charges are made
- Use test credit cards
- Webhooks work the same way

### Braintree Sandbox

When using `BraintreeEnvironment.sandbox`:
- Test credit card: `4111111111111111`
- CVV: any 3 digits
- Expiry: any future date

### Testing Webhooks Locally

Use tools like ngrok to expose your local server:

```bash
ngrok http 3000
```

Then use the ngrok URL as your webhook endpoint.

## Next Steps

Now that you have the basics working, explore more features:

- **[Widgets Documentation](widgets.md)** - Pre-built UI components
- **[Advanced Usage](advanced.md)** - Webhooks, custom processors, optimization
- **[Processor Guides](processors/)** - Detailed docs for each processor
- **[Example App](../example/)** - Complete working example

### Common Tasks

**Cancel Subscription**
```dart
await paymentService.cancelSubscription(
  id: subscription.id,
  immediate: false, // Keep active until period ends
);
```

**Change Plan**
```dart
await paymentService.changePlan(
  subscriptionId: subscription.id,
  newPriceId: 'price_annual_9999',
);
```

**One-Time Payment**
```dart
final charge = await paymentService.makePayment(
  amount: 2999, // $29.99
  currency: 'USD',
  description: 'Premium feature unlock',
);
```

**Get Payment History**
```dart
final charges = await paymentService.getPaymentHistory(limit: 10);
```

## Troubleshooting

### Common Issues

**1. "Invalid API key" error**
- Double-check your API credentials
- Ensure you're using the correct keys for sandbox/production
- Check for extra spaces or hidden characters

**2. "Customer not found" error**
- Make sure you called `paymentService.initialize()` first
- Check that the customer was created successfully

**3. "Payment method required" error**
- Some subscriptions require a payment method
- Call `setDefaultPaymentMethod()` before subscribing

**4. Storage errors**
- Ensure your Storage implementation is working
- Check device permissions for secure storage
- Test with InMemoryStorage first

### Getting Help

- Check the [Advanced documentation](advanced.md)
- Review the [example app](../example/)
- Search [GitHub Issues](https://github.com/aliumairdev/flutter_pay_kit/issues)
- Ask in [GitHub Discussions](https://github.com/aliumairdev/flutter_pay_kit/discussions)

## Best Practices

1. **Always use sandbox/test mode during development**
2. **Implement proper error handling** for all payment operations
3. **Cache subscription status** to reduce API calls
4. **Use secure storage** for sensitive data in production
5. **Enable logging** during development
6. **Test webhook handling** thoroughly
7. **Validate user inputs** before making API calls
8. **Handle network failures** gracefully

---

Ready to build something amazing! 🚀
