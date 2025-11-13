// ignore_for_file: unused_local_variable

import 'package:flutter_universal_payments/flutter_universal_payments.dart';

/// Example demonstrating how to use the Payment Configuration Manager.
///
/// This file shows various ways to configure and initialize the payment system
/// using different payment processors.

void main() async {
  // Example 1: Using Stripe with builder pattern
  await configureStripe();

  // Example 2: Using Paddle with builder pattern
  await configurePaddle();

  // Example 3: Using Braintree with builder pattern
  await configureBraintree();

  // Example 4: Using Lemon Squeezy with builder pattern
  await configureLemonSqueezy();

  // Example 5: Using Totalpay with builder pattern
  await configureTotalpay();

  // Example 6: Using Fake processor for testing
  await configureFake();

  // Example 7: Direct configuration without builder
  await directConfiguration();

  // Example 8: Runtime processor switching
  await runtimeSwitching();
}

/// Configure and initialize Stripe payment processor
Future<void> configureStripe() async {
  print('\n=== Stripe Configuration ===\n');

  final config = PaymentConfigurationBuilder()
      .useStripe(
        publishableKey: 'pk_test_51234567890',
        secretKey: 'sk_test_51234567890',
        webhookSecret: 'whsec_test123',
      )
      .enableLogging()
      .setTimeout(const Duration(seconds: 60))
      .build();

  // Create a simple in-memory storage for testing
  final storage = InMemoryStorage();

  await FlutterUniversalPayments.initialize(
    config,
    storage: storage,
  );

  print('Stripe initialized: ${FlutterUniversalPayments.isInitialized}');
  print('Processor: ${FlutterUniversalPayments.configuration.processor}');

  // Use the service
  final service = FlutterUniversalPayments.instance;
  print('Service ready: ${service != null}');
}

/// Configure and initialize Paddle payment processor
Future<void> configurePaddle() async {
  print('\n=== Paddle Configuration ===\n');

  final config = PaymentConfigurationBuilder()
      .usePaddle(
        vendorId: '12345',
        authCode: 'your_auth_code_here',
        publicKey: 'your_public_key_here',
        environment: PaddleEnvironment.sandbox,
      )
      .enableLogging()
      .build();

  final storage = InMemoryStorage();

  await FlutterUniversalPayments.reinitialize(config, storage: storage);

  print('Paddle initialized: ${FlutterUniversalPayments.isInitialized}');
}

/// Configure and initialize Braintree payment processor
Future<void> configureBraintree() async {
  print('\n=== Braintree Configuration ===\n');

  final config = PaymentConfigurationBuilder()
      .useBraintree(
        merchantId: 'your_merchant_id',
        publicKey: 'your_public_key',
        privateKey: 'your_private_key',
        environment: BraintreeEnvironment.sandbox,
      )
      .enableLogging()
      .build();

  final storage = InMemoryStorage();

  await FlutterUniversalPayments.reinitialize(config, storage: storage);

  print('Braintree initialized: ${FlutterUniversalPayments.isInitialized}');
}

/// Configure and initialize Lemon Squeezy payment processor
Future<void> configureLemonSqueezy() async {
  print('\n=== Lemon Squeezy Configuration ===\n');

  final config = PaymentConfigurationBuilder()
      .useLemonSqueezy(
        apiKey: 'your_api_key',
        storeId: 'your_store_id',
        webhookSecret: 'your_webhook_secret',
      )
      .enableLogging()
      .build();

  final storage = InMemoryStorage();

  await FlutterUniversalPayments.reinitialize(config, storage: storage);

  print('Lemon Squeezy initialized: ${FlutterUniversalPayments.isInitialized}');
}

/// Configure and initialize Totalpay payment processor
Future<void> configureTotalpay() async {
  print('\n=== Totalpay Configuration ===\n');

  final config = PaymentConfigurationBuilder()
      .useTotalpay(
        merchantId: 'your_merchant_id',
        apiKey: 'your_api_key',
        secretKey: 'your_secret_key',
        environment: TotalpayEnvironment.sandbox,
      )
      .enableLogging()
      .build();

  final storage = InMemoryStorage();

  await FlutterUniversalPayments.reinitialize(config, storage: storage);

  print('Totalpay initialized: ${FlutterUniversalPayments.isInitialized}');
}

/// Configure and initialize Fake processor for testing
Future<void> configureFake() async {
  print('\n=== Fake Processor Configuration ===\n');

  final config = PaymentConfigurationBuilder()
      .useFake(
        simulateDelays: true,
        delayDuration: const Duration(milliseconds: 200),
        failureRate: 0.0, // Never fail
      )
      .enableLogging()
      .build();

  final storage = InMemoryStorage();

  await FlutterUniversalPayments.reinitialize(config, storage: storage);

  print('Fake processor initialized: ${FlutterUniversalPayments.isInitialized}');

  // Test basic operations with fake processor
  final service = FlutterUniversalPayments.instance;

  // Initialize with test customer
  await service.initialize(
    email: 'test@example.com',
    name: 'Test User',
  );

  print('Customer initialized');

  // Get current customer
  final customer = await service.getCurrentCustomer();
  print('Customer email: ${customer?.email}');
}

/// Example of direct configuration without builder
Future<void> directConfiguration() async {
  print('\n=== Direct Configuration ===\n');

  final config = PaymentConfiguration(
    processor: ProcessorType.stripe,
    stripePublishableKey: 'pk_test_51234567890',
    stripeSecretKey: 'sk_test_51234567890',
    stripeWebhookSecret: 'whsec_test123',
    enableLogging: true,
    requestTimeout: const Duration(seconds: 45),
  );

  final storage = InMemoryStorage();

  await FlutterUniversalPayments.reinitialize(config, storage: storage);

  print('Direct configuration successful');
}

/// Example of runtime processor switching
Future<void> runtimeSwitching() async {
  print('\n=== Runtime Processor Switching ===\n');

  final storage = InMemoryStorage();

  // Start with Fake processor
  final fakeConfig = PaymentConfigurationBuilder()
      .useFake()
      .enableLogging()
      .build();

  await FlutterUniversalPayments.reinitialize(fakeConfig, storage: storage);
  print('Started with Fake processor');

  // Switch to Stripe
  final stripeConfig = PaymentConfigurationBuilder()
      .useStripe(
        publishableKey: 'pk_test_51234567890',
        secretKey: 'sk_test_51234567890',
      )
      .enableLogging()
      .build();

  await FlutterUniversalPayments.reinitialize(stripeConfig, storage: storage);
  print('Switched to Stripe processor');

  // Dispose when done
  await FlutterUniversalPayments.dispose();
  print('Resources disposed');
}

/// Simple in-memory storage implementation for testing
class InMemoryStorage implements Storage {
  final Map<String, String> _storage = {};

  @override
  Future<String?> getString(String key) async {
    return _storage[key];
  }

  @override
  Future<void> setString(String key, String value) async {
    _storage[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _storage.remove(key);
  }

  @override
  Future<bool> containsKey(String key) async {
    return _storage.containsKey(key);
  }

  @override
  Future<void> clear() async {
    _storage.clear();
  }
}
