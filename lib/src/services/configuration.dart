import 'dart:developer' as developer;

import 'package:riverpod/riverpod.dart';

import '../exceptions/exceptions.dart';
import '../models/enums.dart';
import '../processors/processors.dart';
import 'payment_service.dart';
import 'storage.dart';

/// Configuration for the payment processor.
///
/// This class holds all the necessary configuration for initializing a payment
/// processor. Use [PaymentConfigurationBuilder] for a fluent API to build
/// configurations.
///
/// Example:
/// ```dart
/// final config = PaymentConfiguration(
///   processor: ProcessorType.stripe,
///   stripePublishableKey: 'pk_test_...',
///   stripeSecretKey: 'sk_test_...',
///   enableLogging: true,
/// );
/// ```
class PaymentConfiguration {
  /// The payment processor to use
  final ProcessorType processor;

  // Stripe configuration
  final String? stripePublishableKey;
  final String? stripeSecretKey;
  final String? stripeWebhookSecret;

  // Paddle configuration
  final String? paddleVendorId;
  final String? paddleAuthCode;
  final String? paddlePublicKey;
  final PaddleEnvironment? paddleEnvironment;

  // Braintree configuration
  final String? braintreeMerchantId;
  final String? braintreePublicKey;
  final String? braintreePrivateKey;
  final BraintreeEnvironment? braintreeEnvironment;

  // Lemon Squeezy configuration
  final String? lemonSqueezyApiKey;
  final String? lemonSqueezyStoreId;
  final String? lemonSqueezyWebhookSecret;

  // Totalpay configuration
  final String? totalpayMerchantId;
  final String? totalpayApiKey;
  final String? totalpaySecretKey;
  final TotalpayEnvironment? totalpayEnvironment;

  // Fake processor configuration
  final bool? fakeSimulateDelays;
  final Duration? fakeDelayDuration;
  final double? fakeFailureRate;

  // General configuration
  final bool enableLogging;
  final Duration requestTimeout;

  /// Creates a new [PaymentConfiguration] instance.
  ///
  /// The [processor] parameter is required. Other parameters are required
  /// based on the selected processor type.
  ///
  /// Throws [InvalidConfigurationException] if required fields are missing.
  const PaymentConfiguration({
    required this.processor,
    this.stripePublishableKey,
    this.stripeSecretKey,
    this.stripeWebhookSecret,
    this.paddleVendorId,
    this.paddleAuthCode,
    this.paddlePublicKey,
    this.paddleEnvironment,
    this.braintreeMerchantId,
    this.braintreePublicKey,
    this.braintreePrivateKey,
    this.braintreeEnvironment,
    this.lemonSqueezyApiKey,
    this.lemonSqueezyStoreId,
    this.lemonSqueezyWebhookSecret,
    this.totalpayMerchantId,
    this.totalpayApiKey,
    this.totalpaySecretKey,
    this.totalpayEnvironment,
    this.fakeSimulateDelays,
    this.fakeDelayDuration,
    this.fakeFailureRate,
    this.enableLogging = false,
    this.requestTimeout = const Duration(seconds: 30),
  });

  /// Validates the configuration based on the selected processor.
  ///
  /// Throws [InvalidConfigurationException] if the configuration is invalid.
  void validate() {
    switch (processor) {
      case ProcessorType.stripe:
        _validateStripeConfig();
        break;
      case ProcessorType.paddle:
        _validatePaddleConfig();
        break;
      case ProcessorType.braintree:
        _validateBraintreeConfig();
        break;
      case ProcessorType.lemonSqueezy:
        _validateLemonSqueezyConfig();
        break;
      case ProcessorType.totalpayGlobal:
        _validateTotalpayConfig();
        break;
      case ProcessorType.fake:
        _validateFakeConfig();
        break;
    }
  }

  /// Validates Stripe configuration.
  void _validateStripeConfig() {
    if (stripePublishableKey == null || stripePublishableKey!.isEmpty) {
      throw InvalidConfigurationException(
        'Stripe publishable key is required',
        fieldName: 'stripePublishableKey',
      );
    }
    if (stripeSecretKey == null || stripeSecretKey!.isEmpty) {
      throw InvalidConfigurationException(
        'Stripe secret key is required',
        fieldName: 'stripeSecretKey',
      );
    }
    if (!stripePublishableKey!.startsWith('pk_')) {
      throw InvalidConfigurationException(
        'Invalid Stripe publishable key format (must start with pk_)',
        fieldName: 'stripePublishableKey',
      );
    }
    if (!stripeSecretKey!.startsWith('sk_')) {
      throw InvalidConfigurationException(
        'Invalid Stripe secret key format (must start with sk_)',
        fieldName: 'stripeSecretKey',
      );
    }
  }

  /// Validates Paddle configuration.
  void _validatePaddleConfig() {
    if (paddleVendorId == null || paddleVendorId!.isEmpty) {
      throw InvalidConfigurationException(
        'Paddle vendor ID is required',
        fieldName: 'paddleVendorId',
      );
    }
    if (paddleAuthCode == null || paddleAuthCode!.isEmpty) {
      throw InvalidConfigurationException(
        'Paddle auth code is required',
        fieldName: 'paddleAuthCode',
      );
    }
    if (paddlePublicKey == null || paddlePublicKey!.isEmpty) {
      throw InvalidConfigurationException(
        'Paddle public key is required',
        fieldName: 'paddlePublicKey',
      );
    }
    if (paddleEnvironment == null) {
      throw InvalidConfigurationException(
        'Paddle environment is required',
        fieldName: 'paddleEnvironment',
      );
    }
  }

  /// Validates Braintree configuration.
  void _validateBraintreeConfig() {
    if (braintreeMerchantId == null || braintreeMerchantId!.isEmpty) {
      throw InvalidConfigurationException(
        'Braintree merchant ID is required',
        fieldName: 'braintreeMerchantId',
      );
    }
    if (braintreePublicKey == null || braintreePublicKey!.isEmpty) {
      throw InvalidConfigurationException(
        'Braintree public key is required',
        fieldName: 'braintreePublicKey',
      );
    }
    if (braintreePrivateKey == null || braintreePrivateKey!.isEmpty) {
      throw InvalidConfigurationException(
        'Braintree private key is required',
        fieldName: 'braintreePrivateKey',
      );
    }
    if (braintreeEnvironment == null) {
      throw InvalidConfigurationException(
        'Braintree environment is required',
        fieldName: 'braintreeEnvironment',
      );
    }
  }

  /// Validates Lemon Squeezy configuration.
  void _validateLemonSqueezyConfig() {
    if (lemonSqueezyApiKey == null || lemonSqueezyApiKey!.isEmpty) {
      throw InvalidConfigurationException(
        'Lemon Squeezy API key is required',
        fieldName: 'lemonSqueezyApiKey',
      );
    }
    if (lemonSqueezyStoreId == null || lemonSqueezyStoreId!.isEmpty) {
      throw InvalidConfigurationException(
        'Lemon Squeezy store ID is required',
        fieldName: 'lemonSqueezyStoreId',
      );
    }
  }

  /// Validates Totalpay configuration.
  void _validateTotalpayConfig() {
    if (totalpayMerchantId == null || totalpayMerchantId!.isEmpty) {
      throw InvalidConfigurationException(
        'Totalpay merchant ID is required',
        fieldName: 'totalpayMerchantId',
      );
    }
    if (totalpayApiKey == null || totalpayApiKey!.isEmpty) {
      throw InvalidConfigurationException(
        'Totalpay API key is required',
        fieldName: 'totalpayApiKey',
      );
    }
    if (totalpaySecretKey == null || totalpaySecretKey!.isEmpty) {
      throw InvalidConfigurationException(
        'Totalpay secret key is required',
        fieldName: 'totalpaySecretKey',
      );
    }
    if (totalpayEnvironment == null) {
      throw InvalidConfigurationException(
        'Totalpay environment is required',
        fieldName: 'totalpayEnvironment',
      );
    }
  }

  /// Validates Fake processor configuration.
  ///
  /// Fake processor has no required fields, but validates optional ones.
  void _validateFakeConfig() {
    if (fakeFailureRate != null &&
        (fakeFailureRate! < 0.0 || fakeFailureRate! > 1.0)) {
      throw InvalidConfigurationException(
        'Fake processor failure rate must be between 0.0 and 1.0',
        fieldName: 'fakeFailureRate',
      );
    }
    // No other required fields for fake processor
  }

  /// Creates a payment processor instance based on this configuration.
  ///
  /// Validates the configuration before creating the processor.
  ///
  /// Returns the appropriate [PaymentProcessor] implementation.
  ///
  /// Throws [InvalidConfigurationException] if the configuration is invalid.
  PaymentProcessor createProcessor() {
    // Validate configuration first
    validate();

    // Create processor based on type
    switch (processor) {
      case ProcessorType.stripe:
        return StripeProcessor(
          publishableKey: stripePublishableKey!,
          secretKey: stripeSecretKey!,
          webhookSecret: stripeWebhookSecret,
        );

      case ProcessorType.paddle:
        return PaddleProcessor(
          vendorId: paddleVendorId!,
          vendorAuthCode: paddleAuthCode!,
          publicKey: paddlePublicKey!,
          environment: paddleEnvironment!,
        );

      case ProcessorType.braintree:
        return BraintreeProcessor(
          merchantId: braintreeMerchantId!,
          publicKey: braintreePublicKey!,
          privateKey: braintreePrivateKey!,
          environment: braintreeEnvironment!,
        );

      case ProcessorType.lemonSqueezy:
        return LemonSqueezyProcessor(
          apiKey: lemonSqueezyApiKey!,
          storeId: lemonSqueezyStoreId!,
          webhookSecret: lemonSqueezyWebhookSecret,
        );

      case ProcessorType.totalpayGlobal:
        return TotalpayProcessor(
          merchantId: totalpayMerchantId!,
          apiKey: totalpayApiKey!,
          secretKey: totalpaySecretKey!,
          environment: totalpayEnvironment!,
        );

      case ProcessorType.fake:
        return FakeProcessor(
          simulateDelays: fakeSimulateDelays ?? true,
          delayDuration: fakeDelayDuration ?? const Duration(milliseconds: 500),
          failureRate: fakeFailureRate ?? 0.0,
          enableLogging: enableLogging,
        );
    }
  }
}

/// Main entry point for initializing Flutter Universal Payments.
///
/// This class provides a centralized way to initialize and access the payment
/// service throughout your application.
///
/// Example:
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///
///   // Initialize payment configuration
///   final config = PaymentConfigurationBuilder()
///     .useStripe(
///       publishableKey: 'pk_test_...',
///       secretKey: 'sk_test_...',
///     )
///     .enableLogging()
///     .build();
///
///   // Initialize the payment system
///   await FlutterUniversalPayments.initialize(
///     config,
///     storage: SharedPreferencesStorage(
///       getPreferences: () => SharedPreferences.getInstance(),
///     ),
///   );
///
///   runApp(MyApp());
/// }
///
/// // Access the service anywhere in your app
/// final service = FlutterUniversalPayments.instance;
/// await service.subscribe(priceId: 'price_abc123');
/// ```
class FlutterUniversalPayments {
  static PaymentConfiguration? _configuration;
  static PaymentService? _service;
  static ProviderContainer? _container;

  /// Initializes the Flutter Universal Payments system.
  ///
  /// This must be called before using [instance] or any payment functionality.
  ///
  /// Parameters:
  /// - [config]: The payment configuration
  /// - [storage]: Storage implementation for caching data
  ///
  /// Throws [InvalidConfigurationException] if the configuration is invalid.
  ///
  /// Example:
  /// ```dart
  /// await FlutterUniversalPayments.initialize(
  ///   PaymentConfiguration(
  ///     processor: ProcessorType.stripe,
  ///     stripePublishableKey: 'pk_test_...',
  ///     stripeSecretKey: 'sk_test_...',
  ///   ),
  ///   storage: SharedPreferencesStorage(
  ///     getPreferences: () => SharedPreferences.getInstance(),
  ///   ),
  /// );
  /// ```
  static Future<void> initialize(
    PaymentConfiguration config, {
    required Storage storage,
  }) async {
    try {
      // Validate configuration
      config.validate();

      // Create processor
      final processor = config.createProcessor();

      // Validate processor configuration
      try {
        await processor.validateConfiguration();
      } catch (e) {
        developer.log(
          'Processor validation warning: $e',
          name: 'FlutterUniversalPayments',
        );
        // Continue even if validation fails - it might be a network issue
      }

      // Create payment service
      _service = PaymentService(
        processor: processor,
        storage: storage,
      );

      // Create Riverpod container with overrides
      _container = ProviderContainer(
        overrides: [
          paymentServiceProvider.overrideWithValue(_service!),
        ],
      );

      // Store configuration
      _configuration = config;

      if (config.enableLogging) {
        developer.log(
          'FlutterUniversalPayments initialized with ${processor.name}',
          name: 'FlutterUniversalPayments',
        );
      }
    } catch (e) {
      developer.log(
        'Failed to initialize FlutterUniversalPayments',
        error: e,
        name: 'FlutterUniversalPayments',
      );
      rethrow;
    }
  }

  /// Gets the payment service instance.
  ///
  /// Throws [StateError] if [initialize] hasn't been called yet.
  ///
  /// Example:
  /// ```dart
  /// final service = FlutterUniversalPayments.instance;
  /// await service.initialize(email: 'user@example.com');
  /// ```
  static PaymentService get instance {
    if (_service == null) {
      throw StateError(
        'FlutterUniversalPayments not initialized. '
        'Call FlutterUniversalPayments.initialize() first.',
      );
    }
    return _service!;
  }

  /// Gets the Riverpod container for use in your app.
  ///
  /// This can be used to wrap your app with [UncontrolledProviderScope].
  ///
  /// Example:
  /// ```dart
  /// runApp(
  ///   UncontrolledProviderScope(
  ///     container: FlutterUniversalPayments.container,
  ///     child: MyApp(),
  ///   ),
  /// );
  /// ```
  static ProviderContainer get container {
    if (_container == null) {
      throw StateError(
        'FlutterUniversalPayments not initialized. '
        'Call FlutterUniversalPayments.initialize() first.',
      );
    }
    return _container!;
  }

  /// Gets the current configuration.
  ///
  /// Throws [StateError] if [initialize] hasn't been called yet.
  static PaymentConfiguration get configuration {
    if (_configuration == null) {
      throw StateError(
        'FlutterUniversalPayments not initialized. '
        'Call FlutterUniversalPayments.initialize() first.',
      );
    }
    return _configuration!;
  }

  /// Checks if FlutterUniversalPayments has been initialized.
  ///
  /// Returns true if [initialize] has been called successfully, false otherwise.
  static bool get isInitialized => _service != null;

  /// Reinitializes with a new configuration.
  ///
  /// This is useful for switching processors at runtime (advanced use case).
  ///
  /// **Warning**: This will clear all cached data and reset the payment service.
  ///
  /// Example:
  /// ```dart
  /// // Switch from Stripe to Paddle
  /// await FlutterUniversalPayments.reinitialize(
  ///   PaymentConfigurationBuilder()
  ///     .usePaddle(
  ///       vendorId: '12345',
  ///       authCode: 'auth_code',
  ///       publicKey: 'public_key',
  ///       environment: PaddleEnvironment.production,
  ///     )
  ///     .build(),
  ///   storage: currentStorage,
  /// );
  /// ```
  static Future<void> reinitialize(
    PaymentConfiguration config, {
    required Storage storage,
  }) async {
    // Clear existing service
    if (_service != null) {
      await _service!.clearCache();
    }

    // Dispose container
    _container?.dispose();

    // Reset state
    _service = null;
    _configuration = null;
    _container = null;

    // Initialize with new config
    await initialize(config, storage: storage);
  }

  /// Disposes of all resources.
  ///
  /// This should be called when shutting down the app or when the payment
  /// system is no longer needed.
  static Future<void> dispose() async {
    if (_service != null) {
      await _service!.clearCache();
    }
    _container?.dispose();
    _service = null;
    _configuration = null;
    _container = null;
  }
}

/// Builder for creating [PaymentConfiguration] instances with a fluent API.
///
/// This class provides a convenient way to build payment configurations with
/// method chaining.
///
/// Example:
/// ```dart
/// final config = PaymentConfigurationBuilder()
///   .useStripe(
///     publishableKey: 'pk_test_...',
///     secretKey: 'sk_test_...',
///     webhookSecret: 'whsec_...',
///   )
///   .enableLogging()
///   .setTimeout(Duration(seconds: 60))
///   .build();
/// ```
class PaymentConfigurationBuilder {
  ProcessorType? _processor;

  // Stripe fields
  String? _stripePublishableKey;
  String? _stripeSecretKey;
  String? _stripeWebhookSecret;

  // Paddle fields
  String? _paddleVendorId;
  String? _paddleAuthCode;
  String? _paddlePublicKey;
  PaddleEnvironment? _paddleEnvironment;

  // Braintree fields
  String? _braintreeMerchantId;
  String? _braintreePublicKey;
  String? _braintreePrivateKey;
  BraintreeEnvironment? _braintreeEnvironment;

  // Lemon Squeezy fields
  String? _lemonSqueezyApiKey;
  String? _lemonSqueezyStoreId;
  String? _lemonSqueezyWebhookSecret;

  // Totalpay fields
  String? _totalpayMerchantId;
  String? _totalpayApiKey;
  String? _totalpaySecretKey;
  TotalpayEnvironment? _totalpayEnvironment;

  // Fake processor fields
  bool? _fakeSimulateDelays;
  Duration? _fakeDelayDuration;
  double? _fakeFailureRate;

  // General fields
  bool _enableLogging = false;
  Duration _requestTimeout = const Duration(seconds: 30);

  /// Configures the builder to use Stripe as the payment processor.
  ///
  /// Parameters:
  /// - [publishableKey]: Stripe publishable key (required)
  /// - [secretKey]: Stripe secret key (required)
  /// - [webhookSecret]: Stripe webhook secret (optional)
  ///
  /// Example:
  /// ```dart
  /// builder.useStripe(
  ///   publishableKey: 'pk_test_...',
  ///   secretKey: 'sk_test_...',
  ///   webhookSecret: 'whsec_...',
  /// )
  /// ```
  PaymentConfigurationBuilder useStripe({
    required String publishableKey,
    required String secretKey,
    String? webhookSecret,
  }) {
    _processor = ProcessorType.stripe;
    _stripePublishableKey = publishableKey;
    _stripeSecretKey = secretKey;
    _stripeWebhookSecret = webhookSecret;
    return this;
  }

  /// Configures the builder to use Paddle as the payment processor.
  ///
  /// Parameters:
  /// - [vendorId]: Paddle vendor ID (required)
  /// - [authCode]: Paddle auth code (required)
  /// - [publicKey]: Paddle public key (required)
  /// - [environment]: Paddle environment - sandbox or production (required)
  ///
  /// Example:
  /// ```dart
  /// builder.usePaddle(
  ///   vendorId: '12345',
  ///   authCode: 'auth_code',
  ///   publicKey: 'public_key',
  ///   environment: PaddleEnvironment.sandbox,
  /// )
  /// ```
  PaymentConfigurationBuilder usePaddle({
    required String vendorId,
    required String authCode,
    required String publicKey,
    required PaddleEnvironment environment,
  }) {
    _processor = ProcessorType.paddle;
    _paddleVendorId = vendorId;
    _paddleAuthCode = authCode;
    _paddlePublicKey = publicKey;
    _paddleEnvironment = environment;
    return this;
  }

  /// Configures the builder to use Braintree as the payment processor.
  ///
  /// Parameters:
  /// - [merchantId]: Braintree merchant ID (required)
  /// - [publicKey]: Braintree public key (required)
  /// - [privateKey]: Braintree private key (required)
  /// - [environment]: Braintree environment - sandbox or production (required)
  ///
  /// Example:
  /// ```dart
  /// builder.useBraintree(
  ///   merchantId: 'merchant_id',
  ///   publicKey: 'public_key',
  ///   privateKey: 'private_key',
  ///   environment: BraintreeEnvironment.sandbox,
  /// )
  /// ```
  PaymentConfigurationBuilder useBraintree({
    required String merchantId,
    required String publicKey,
    required String privateKey,
    required BraintreeEnvironment environment,
  }) {
    _processor = ProcessorType.braintree;
    _braintreeMerchantId = merchantId;
    _braintreePublicKey = publicKey;
    _braintreePrivateKey = privateKey;
    _braintreeEnvironment = environment;
    return this;
  }

  /// Configures the builder to use Lemon Squeezy as the payment processor.
  ///
  /// Parameters:
  /// - [apiKey]: Lemon Squeezy API key (required)
  /// - [storeId]: Lemon Squeezy store ID (required)
  /// - [webhookSecret]: Lemon Squeezy webhook secret (optional)
  ///
  /// Example:
  /// ```dart
  /// builder.useLemonSqueezy(
  ///   apiKey: 'api_key',
  ///   storeId: 'store_id',
  ///   webhookSecret: 'webhook_secret',
  /// )
  /// ```
  PaymentConfigurationBuilder useLemonSqueezy({
    required String apiKey,
    required String storeId,
    String? webhookSecret,
  }) {
    _processor = ProcessorType.lemonSqueezy;
    _lemonSqueezyApiKey = apiKey;
    _lemonSqueezyStoreId = storeId;
    _lemonSqueezyWebhookSecret = webhookSecret;
    return this;
  }

  /// Configures the builder to use Totalpay Global as the payment processor.
  ///
  /// Parameters:
  /// - [merchantId]: Totalpay merchant ID (required)
  /// - [apiKey]: Totalpay API key (required)
  /// - [secretKey]: Totalpay secret key (required)
  /// - [environment]: Totalpay environment - sandbox or production (required)
  ///
  /// Example:
  /// ```dart
  /// builder.useTotalpay(
  ///   merchantId: 'merchant_id',
  ///   apiKey: 'api_key',
  ///   secretKey: 'secret_key',
  ///   environment: TotalpayEnvironment.sandbox,
  /// )
  /// ```
  PaymentConfigurationBuilder useTotalpay({
    required String merchantId,
    required String apiKey,
    required String secretKey,
    required TotalpayEnvironment environment,
  }) {
    _processor = ProcessorType.totalpayGlobal;
    _totalpayMerchantId = merchantId;
    _totalpayApiKey = apiKey;
    _totalpaySecretKey = secretKey;
    _totalpayEnvironment = environment;
    return this;
  }

  /// Configures the builder to use the fake processor for testing.
  ///
  /// Parameters:
  /// - [simulateDelays]: Whether to simulate network delays (defaults to true)
  /// - [delayDuration]: Duration of simulated delays (defaults to 500ms)
  /// - [failureRate]: Rate of random failures 0.0-1.0 (defaults to 0.0)
  ///
  /// Example:
  /// ```dart
  /// builder.useFake(
  ///   simulateDelays: true,
  ///   delayDuration: Duration(milliseconds: 200),
  ///   failureRate: 0.1, // 10% failure rate
  /// )
  /// ```
  PaymentConfigurationBuilder useFake({
    bool simulateDelays = true,
    Duration delayDuration = const Duration(milliseconds: 500),
    double failureRate = 0.0,
  }) {
    _processor = ProcessorType.fake;
    _fakeSimulateDelays = simulateDelays;
    _fakeDelayDuration = delayDuration;
    _fakeFailureRate = failureRate;
    return this;
  }

  /// Enables logging for debugging and development.
  ///
  /// Example:
  /// ```dart
  /// builder.enableLogging()
  /// ```
  PaymentConfigurationBuilder enableLogging() {
    _enableLogging = true;
    return this;
  }

  /// Disables logging.
  ///
  /// Example:
  /// ```dart
  /// builder.disableLogging()
  /// ```
  PaymentConfigurationBuilder disableLogging() {
    _enableLogging = false;
    return this;
  }

  /// Sets the request timeout duration.
  ///
  /// Parameters:
  /// - [timeout]: The timeout duration (defaults to 30 seconds)
  ///
  /// Example:
  /// ```dart
  /// builder.setTimeout(Duration(seconds: 60))
  /// ```
  PaymentConfigurationBuilder setTimeout(Duration timeout) {
    _requestTimeout = timeout;
    return this;
  }

  /// Builds and returns the [PaymentConfiguration].
  ///
  /// Throws [InvalidConfigurationException] if no processor is configured.
  ///
  /// Example:
  /// ```dart
  /// final config = builder.build();
  /// ```
  PaymentConfiguration build() {
    if (_processor == null) {
      throw InvalidConfigurationException(
        'No payment processor configured. '
        'Call useStripe(), usePaddle(), useBraintree(), useLemonSqueezy(), useTotalpay(), or useFake() first.',
        fieldName: 'processor',
      );
    }

    return PaymentConfiguration(
      processor: _processor!,
      stripePublishableKey: _stripePublishableKey,
      stripeSecretKey: _stripeSecretKey,
      stripeWebhookSecret: _stripeWebhookSecret,
      paddleVendorId: _paddleVendorId,
      paddleAuthCode: _paddleAuthCode,
      paddlePublicKey: _paddlePublicKey,
      paddleEnvironment: _paddleEnvironment,
      braintreeMerchantId: _braintreeMerchantId,
      braintreePublicKey: _braintreePublicKey,
      braintreePrivateKey: _braintreePrivateKey,
      braintreeEnvironment: _braintreeEnvironment,
      lemonSqueezyApiKey: _lemonSqueezyApiKey,
      lemonSqueezyStoreId: _lemonSqueezyStoreId,
      lemonSqueezyWebhookSecret: _lemonSqueezyWebhookSecret,
      totalpayMerchantId: _totalpayMerchantId,
      totalpayApiKey: _totalpayApiKey,
      totalpaySecretKey: _totalpaySecretKey,
      totalpayEnvironment: _totalpayEnvironment,
      fakeSimulateDelays: _fakeSimulateDelays,
      fakeDelayDuration: _fakeDelayDuration,
      fakeFailureRate: _fakeFailureRate,
      enableLogging: _enableLogging,
      requestTimeout: _requestTimeout,
    );
  }
}
