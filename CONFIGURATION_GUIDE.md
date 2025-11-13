# Payment Configuration Manager Guide

This guide explains how to use the configuration manager to initialize and configure the Flutter Universal Payments package.

## Table of Contents

- [Quick Start](#quick-start)
- [Configuration Methods](#configuration-methods)
- [Processor-Specific Configuration](#processor-specific-configuration)
- [Advanced Features](#advanced-features)
- [Error Handling](#error-handling)

## Quick Start

### 1. Using the Builder Pattern (Recommended)

```dart
import 'package:flutter_universal_payments/flutter_universal_payments.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Build configuration using fluent API
  final config = PaymentConfigurationBuilder()
    .useStripe(
      publishableKey: 'pk_test_...',
      secretKey: 'sk_test_...',
      webhookSecret: 'whsec_...',
    )
    .enableLogging()
    .setTimeout(Duration(seconds: 60))
    .build();

  // Initialize the payment system
  await FlutterUniversalPayments.initialize(
    config,
    storage: SharedPreferencesStorage(
      getPreferences: () => SharedPreferences.getInstance(),
    ),
  );

  runApp(MyApp());
}

// Access the service anywhere in your app
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PaymentScreen(),
    );
  }
}

class PaymentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final service = FlutterUniversalPayments.instance;

            // Initialize customer
            await service.initialize(
              email: 'user@example.com',
              name: 'John Doe',
            );

            // Subscribe to a plan
            await service.subscribe(priceId: 'price_abc123');
          },
          child: Text('Subscribe'),
        ),
      ),
    );
  }
}
```

### 2. Direct Configuration

```dart
final config = PaymentConfiguration(
  processor: ProcessorType.stripe,
  stripePublishableKey: 'pk_test_...',
  stripeSecretKey: 'sk_test_...',
  enableLogging: true,
);

await FlutterUniversalPayments.initialize(
  config,
  storage: yourStorageImplementation,
);
```

## Configuration Methods

### PaymentConfigurationBuilder

The builder provides a fluent API for configuring payment processors:

```dart
PaymentConfigurationBuilder()
  .useStripe(...)
  .enableLogging()
  .setTimeout(Duration(seconds: 60))
  .build();
```

### Available Builder Methods

- `useStripe()` - Configure Stripe payment processor
- `usePaddle()` - Configure Paddle payment processor
- `useBraintree()` - Configure Braintree payment processor
- `useLemonSqueezy()` - Configure Lemon Squeezy payment processor
- `useTotalpay()` - Configure Totalpay Global payment processor
- `useFake()` - Configure fake processor for testing
- `enableLogging()` - Enable debug logging
- `disableLogging()` - Disable debug logging
- `setTimeout(Duration)` - Set request timeout
- `build()` - Build the configuration

## Processor-Specific Configuration

### Stripe

```dart
final config = PaymentConfigurationBuilder()
  .useStripe(
    publishableKey: 'pk_test_...',  // Required
    secretKey: 'sk_test_...',        // Required
    webhookSecret: 'whsec_...',      // Optional
  )
  .build();
```

**Required Fields:**
- `publishableKey` - Stripe publishable key (starts with `pk_`)
- `secretKey` - Stripe secret key (starts with `sk_`)

**Optional Fields:**
- `webhookSecret` - Webhook signing secret for signature verification

### Paddle

```dart
final config = PaymentConfigurationBuilder()
  .usePaddle(
    vendorId: '12345',              // Required
    authCode: 'auth_code',          // Required
    publicKey: 'public_key',        // Required
    environment: PaddleEnvironment.sandbox,  // Required
  )
  .build();
```

**Required Fields:**
- `vendorId` - Paddle vendor ID
- `authCode` - Paddle vendor auth code
- `publicKey` - Paddle public key
- `environment` - `PaddleEnvironment.sandbox` or `PaddleEnvironment.production`

### Braintree

```dart
final config = PaymentConfigurationBuilder()
  .useBraintree(
    merchantId: 'merchant_id',      // Required
    publicKey: 'public_key',        // Required
    privateKey: 'private_key',      // Required
    environment: BraintreeEnvironment.sandbox,  // Required
  )
  .build();
```

**Required Fields:**
- `merchantId` - Braintree merchant ID
- `publicKey` - Braintree public key
- `privateKey` - Braintree private key
- `environment` - `BraintreeEnvironment.sandbox` or `BraintreeEnvironment.production`

### Lemon Squeezy

```dart
final config = PaymentConfigurationBuilder()
  .useLemonSqueezy(
    apiKey: 'api_key',              // Required
    storeId: 'store_id',            // Required
    webhookSecret: 'webhook_secret', // Optional
  )
  .build();
```

**Required Fields:**
- `apiKey` - Lemon Squeezy API key
- `storeId` - Lemon Squeezy store ID

**Optional Fields:**
- `webhookSecret` - Webhook signing secret

### Totalpay Global

```dart
final config = PaymentConfigurationBuilder()
  .useTotalpay(
    merchantId: 'merchant_id',      // Required
    apiKey: 'api_key',              // Required
    secretKey: 'secret_key',        // Required
    environment: TotalpayEnvironment.sandbox,  // Required
  )
  .build();
```

**Required Fields:**
- `merchantId` - Totalpay merchant ID
- `apiKey` - Totalpay API key
- `secretKey` - Totalpay secret key
- `environment` - `TotalpayEnvironment.sandbox` or `TotalpayEnvironment.production`

### Fake Processor (Testing)

```dart
final config = PaymentConfigurationBuilder()
  .useFake(
    simulateDelays: true,           // Optional (default: true)
    delayDuration: Duration(milliseconds: 500),  // Optional
    failureRate: 0.1,               // Optional (0.0-1.0, default: 0.0)
  )
  .build();
```

**Optional Fields:**
- `simulateDelays` - Simulate network delays (default: `true`)
- `delayDuration` - Duration of simulated delays (default: `500ms`)
- `failureRate` - Rate of random failures from 0.0 (never) to 1.0 (always) (default: `0.0`)

## Advanced Features

### Runtime Processor Switching

You can switch payment processors at runtime using `reinitialize()`:

```dart
// Start with Stripe
final stripeConfig = PaymentConfigurationBuilder()
  .useStripe(publishableKey: '...', secretKey: '...')
  .build();

await FlutterUniversalPayments.initialize(
  stripeConfig,
  storage: storage,
);

// Later, switch to Paddle
final paddleConfig = PaymentConfigurationBuilder()
  .usePaddle(
    vendorId: '...',
    authCode: '...',
    publicKey: '...',
    environment: PaddleEnvironment.production,
  )
  .build();

await FlutterUniversalPayments.reinitialize(
  paddleConfig,
  storage: storage,
);
```

**Note:** Reinitializing clears all cached data.

### Environment-Based Configuration

```dart
// Load config from environment variables
final config = PaymentConfigurationBuilder()
  .useStripe(
    publishableKey: const String.fromEnvironment('STRIPE_PUBLISHABLE_KEY'),
    secretKey: const String.fromEnvironment('STRIPE_SECRET_KEY'),
  )
  .enableLogging()
  .build();
```

### Custom Request Timeout

```dart
final config = PaymentConfigurationBuilder()
  .useStripe(publishableKey: '...', secretKey: '...')
  .setTimeout(Duration(seconds: 120))  // 2 minutes
  .build();
```

### Using with Riverpod

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = PaymentConfigurationBuilder()
    .useStripe(publishableKey: '...', secretKey: '...')
    .build();

  await FlutterUniversalPayments.initialize(config, storage: storage);

  runApp(
    UncontrolledProviderScope(
      container: FlutterUniversalPayments.container,
      child: MyApp(),
    ),
  );
}

// In your widgets
class SubscriptionWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSubscription = ref.watch(activeSubscriptionProvider);

    return activeSubscription.when(
      data: (subscription) => Text(subscription != null ? 'Active' : 'No subscription'),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

## Error Handling

### Configuration Validation Errors

```dart
try {
  final config = PaymentConfigurationBuilder()
    .useStripe(
      publishableKey: 'invalid_key',  // Wrong format
      secretKey: 'sk_test_...',
    )
    .build();

  await FlutterUniversalPayments.initialize(config, storage: storage);
} on InvalidConfigurationException catch (e) {
  print('Configuration error: ${e.message}');
  print('Field: ${e.fieldName}');
}
```

### Initialization Errors

```dart
try {
  await FlutterUniversalPayments.initialize(config, storage: storage);
} catch (e) {
  print('Failed to initialize: $e');
  // Handle initialization failure
}
```

### Access Before Initialization

```dart
try {
  final service = FlutterUniversalPayments.instance;
} on StateError catch (e) {
  print('Not initialized: $e');
  // Call FlutterUniversalPayments.initialize() first
}
```

### Checking Initialization Status

```dart
if (FlutterUniversalPayments.isInitialized) {
  // Safe to use
  final service = FlutterUniversalPayments.instance;
} else {
  // Need to initialize first
  await FlutterUniversalPayments.initialize(config, storage: storage);
}
```

## Common Configuration Errors

### Missing Required Fields

```dart
// ❌ Wrong - Missing required fields
final config = PaymentConfigurationBuilder()
  .useStripe(
    publishableKey: 'pk_test_...',
    // Missing secretKey!
  )
  .build();  // Throws InvalidConfigurationException
```

```dart
// ✅ Correct - All required fields provided
final config = PaymentConfigurationBuilder()
  .useStripe(
    publishableKey: 'pk_test_...',
    secretKey: 'sk_test_...',
  )
  .build();
```

### Invalid Key Format

```dart
// ❌ Wrong - Invalid key format
final config = PaymentConfigurationBuilder()
  .useStripe(
    publishableKey: 'invalid_key',  // Must start with 'pk_'
    secretKey: 'sk_test_...',
  )
  .build();  // Throws InvalidConfigurationException
```

### No Processor Configured

```dart
// ❌ Wrong - No processor configured
final config = PaymentConfigurationBuilder()
  .enableLogging()
  .build();  // Throws InvalidConfigurationException
```

## Best Practices

1. **Use Environment Variables**: Store API keys in environment variables, not in code
2. **Enable Logging in Development**: Use `.enableLogging()` during development
3. **Validate Early**: Configuration validation happens during `build()` and `initialize()`
4. **Use Fake Processor for Tests**: Use the fake processor in automated tests
5. **Handle Initialization Errors**: Always wrap initialization in try-catch
6. **Check isInitialized**: Check before accessing the instance in optional code paths

## Additional Resources

- [Main README](README.md)
- [API Documentation](https://pub.dev/documentation/flutter_universal_payments/latest/)
- [Example App](example/)
- [Stripe Documentation](https://stripe.com/docs)
- [Paddle Documentation](https://developer.paddle.com/)
- [Braintree Documentation](https://developer.paypal.com/braintree/docs)
- [Lemon Squeezy Documentation](https://docs.lemonsqueezy.com/)
- [Totalpay Documentation](https://docs.totalpay.global/)
