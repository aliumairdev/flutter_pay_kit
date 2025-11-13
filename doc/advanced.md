# Advanced Usage Guide

This guide covers advanced topics for Flutter Universal Payments including webhooks, custom processors, performance optimization, and security best practices.

## Table of Contents

- [Webhook Handling](#webhook-handling)
- [Custom Processor Implementation](#custom-processor-implementation)
- [Error Handling Strategies](#error-handling-strategies)
- [Performance Optimization](#performance-optimization)
- [Security Best Practices](#security-best-practices)
- [Analytics Integration](#analytics-integration)
- [Logging Configuration](#logging-configuration)
- [Storage Patterns](#storage-patterns)
- [Testing Strategies](#testing-strategies)
- [Migration Guides](#migration-guides)

---

## Webhook Handling

Webhooks allow payment processors to notify your backend about payment events asynchronously.

### Setting Up a Webhook Endpoint

Create a backend endpoint to receive webhooks:

```dart
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

final router = Router();

router.post('/webhooks/<processor>', (Request request, String processor) async {
  final signature = request.headers['x-webhook-signature'] ?? '';
  final payload = await request.readAsString();

  try {
    // Verify webhook signature
    final event = await processWebhook(processor, signature, payload);

    // Process event
    await handleWebhookEvent(event);

    return Response.ok('Webhook processed');
  } on WebhookException catch (e) {
    return Response(400, body: 'Invalid webhook: ${e.message}');
  } catch (e) {
    return Response(500, body: 'Internal error: $e');
  }
});
```

### Verifying Webhook Signatures

Always verify webhook signatures to ensure authenticity:

```dart
Future<WebhookEvent> processWebhook(
  String processor,
  String signature,
  String payload,
) async {
  final config = getProcessorConfig(processor);
  final processorInstance = PaymentConfiguration.createProcessor(config);

  // Signature verification is handled by the processor
  final event = await processorInstance.handleWebhook(signature, payload);

  if (!event.verified) {
    throw WebhookException('Invalid webhook signature');
  }

  return event;
}
```

### Processing Webhook Events

Handle different event types:

```dart
Future<void> handleWebhookEvent(WebhookEvent event) async {
  switch (event.type) {
    case 'subscription_created':
      await handleSubscriptionCreated(event.payload);
      break;

    case 'subscription_updated':
      await handleSubscriptionUpdated(event.payload);
      break;

    case 'subscription_canceled':
      await handleSubscriptionCanceled(event.payload);
      break;

    case 'payment_succeeded':
      await handlePaymentSucceeded(event.payload);
      break;

    case 'payment_failed':
      await handlePaymentFailed(event.payload);
      break;

    case 'payment_refunded':
      await handlePaymentRefunded(event.payload);
      break;

    default:
      PaymentLogger.warning('Unhandled webhook event: ${event.type}');
  }
}

Future<void> handleSubscriptionCreated(Map<String, dynamic> payload) async {
  final subscriptionId = payload['subscription_id'];
  final customerId = payload['customer_id'];

  // Update database
  await database.updateUserSubscription(
    customerId: customerId,
    subscriptionId: subscriptionId,
    status: 'active',
  );

  // Send confirmation email
  await emailService.sendSubscriptionConfirmation(customerId);

  // Grant access
  await accessControl.grantPremiumAccess(customerId);

  PaymentLogger.logEvent('subscription_activated', {
    'subscription_id': subscriptionId,
    'customer_id': customerId,
  });
}

Future<void> handlePaymentFailed(Map<String, dynamic> payload) async {
  final customerId = payload['customer_id'];
  final attemptCount = payload['attempt_count'] ?? 1;

  // Send notification
  await notificationService.sendPaymentFailureNotification(
    customerId: customerId,
    attemptCount: attemptCount,
  );

  // After multiple failures, suspend access
  if (attemptCount >= 3) {
    await accessControl.suspendAccess(customerId);
  }
}
```

### Webhook Retry Logic

Implement idempotency to handle duplicate webhooks:

```dart
class WebhookProcessor {
  final Database database;
  final Set<String> _processedWebhooks = {};

  Future<void> processWebhook(WebhookEvent event) async {
    // Check if already processed
    if (_processedWebhooks.contains(event.id)) {
      PaymentLogger.info('Webhook already processed: ${event.id}');
      return;
    }

    // Check database for idempotency
    final exists = await database.webhookExists(event.id);
    if (exists) {
      PaymentLogger.info('Webhook already in database: ${event.id}');
      return;
    }

    // Process webhook
    await handleWebhookEvent(event);

    // Mark as processed
    _processedWebhooks.add(event.id);
    await database.saveWebhook(event.id, event.type, event.timestamp);
  }
}
```

### Testing Webhooks

Test webhooks locally using ngrok:

```bash
# Start your local server
dart run bin/server.dart

# Expose with ngrok
ngrok http 3000

# Update webhook URL in processor dashboard
# https://abc123.ngrok.io/webhooks/stripe
```

---

## Custom Processor Implementation

Create your own payment processor implementation.

### Implementing the PaymentProcessor Interface

```dart
import 'package:flutter_universal_payments/flutter_universal_payments.dart';

class CustomProcessor extends PaymentProcessor {
  final String apiKey;
  final String endpoint;

  CustomProcessor({
    required this.apiKey,
    required this.endpoint,
  });

  @override
  String get name => 'CustomProcessor';

  @override
  bool get supportsPlanSwapping => true;

  @override
  bool get supportsProration => true;

  @override
  Future<Customer> createCustomer({
    required String email,
    String? name,
    String? phone,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _apiCall('POST', '/customers', {
        'email': email,
        'name': name,
        'phone': phone,
        'metadata': metadata,
      });

      return Customer(
        id: _generateId(),
        email: email,
        name: name,
        phone: phone,
        processor: ProcessorType.custom,
        processorCustomerId: response['id'],
        metadata: metadata,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      throw ProcessorException(
        'Failed to create customer',
        code: 'create_customer_failed',
        originalError: e,
      );
    }
  }

  @override
  Future<Subscription> createSubscription({
    required String customerId,
    required String priceId,
    String? paymentMethodId,
    int? trialDays,
  }) async {
    try {
      final response = await _apiCall('POST', '/subscriptions', {
        'customer_id': customerId,
        'price_id': priceId,
        'payment_method_id': paymentMethodId,
        'trial_days': trialDays,
      });

      return _mapToSubscription(response);
    } catch (e) {
      throw ProcessorException(
        'Failed to create subscription',
        code: 'subscription_creation_failed',
        originalError: e,
      );
    }
  }

  @override
  Future<Charge> createCharge({
    required String customerId,
    required int amount,
    required String currency,
    String? description,
    String? paymentMethodId,
  }) async {
    try {
      final response = await _apiCall('POST', '/charges', {
        'customer_id': customerId,
        'amount': amount,
        'currency': currency,
        'description': description,
        'payment_method_id': paymentMethodId,
      });

      return _mapToCharge(response);
    } catch (e) {
      throw ProcessorException(
        'Failed to create charge',
        code: 'charge_failed',
        originalError: e,
      );
    }
  }

  @override
  Future<WebhookEvent> handleWebhook(String? signature, String payload) async {
    // Verify signature
    final isValid = _verifySignature(signature, payload);

    if (!isValid) {
      throw WebhookException('Invalid webhook signature');
    }

    final data = jsonDecode(payload);

    return WebhookEvent(
      id: data['id'],
      type: data['type'],
      processor: ProcessorType.custom,
      payload: data,
      signature: signature,
      timestamp: DateTime.now(),
      verified: true,
    );
  }

  @override
  Future<void> validateConfiguration() async {
    try {
      await _apiCall('GET', '/ping');
    } catch (e) {
      throw InvalidConfigurationException(
        'Invalid API configuration: $e',
      );
    }
  }

  // Helper methods

  Future<Map<String, dynamic>> _apiCall(
    String method,
    String path,
    Map<String, dynamic>? body,
  ) async {
    final url = '$endpoint$path';
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    // Implement HTTP call logic
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode >= 400) {
      throw ProcessorException(
        'API call failed',
        code: 'api_error',
        details: {'status': response.statusCode, 'body': response.body},
      );
    }

    return jsonDecode(response.body);
  }

  bool _verifySignature(String? signature, String payload) {
    // Implement signature verification
    // This is processor-specific
    return true;
  }

  Subscription _mapToSubscription(Map<String, dynamic> data) {
    // Map API response to Subscription model
    return Subscription(
      id: _generateId(),
      customerId: data['customer_id'],
      status: _mapStatus(data['status']),
      priceId: data['price_id'],
      productId: data['product_id'],
      currentPeriodStart: DateTime.parse(data['current_period_start']),
      currentPeriodEnd: DateTime.parse(data['current_period_end']),
      processor: ProcessorType.custom,
      processorSubscriptionId: data['id'],
    );
  }

  Charge _mapToCharge(Map<String, dynamic> data) {
    return Charge(
      id: _generateId(),
      customerId: data['customer_id'],
      amount: data['amount'],
      currency: data['currency'],
      status: _mapChargeStatus(data['status']),
      description: data['description'],
      processorChargeId: data['id'],
      processor: ProcessorType.custom,
      createdAt: DateTime.parse(data['created_at']),
    );
  }

  String _generateId() => const Uuid().v4();

  SubscriptionStatus _mapStatus(String status) {
    switch (status) {
      case 'active':
        return SubscriptionStatus.active;
      case 'trialing':
        return SubscriptionStatus.trialing;
      case 'past_due':
        return SubscriptionStatus.pastDue;
      case 'canceled':
        return SubscriptionStatus.canceled;
      default:
        return SubscriptionStatus.incomplete;
    }
  }

  ChargeStatus _mapChargeStatus(String status) {
    switch (status) {
      case 'succeeded':
        return ChargeStatus.succeeded;
      case 'failed':
        return ChargeStatus.failed;
      case 'pending':
        return ChargeStatus.pending;
      default:
        return ChargeStatus.failed;
    }
  }

  // Implement other required methods...
}
```

### Registering Custom Processor

```dart
// Add to ProcessorType enum (if modifying package)
enum ProcessorType {
  stripe,
  paddle,
  braintree,
  lemonSqueezy,
  totalpayGlobal,
  fake,
  custom, // Add your processor
}

// Use custom processor
final config = PaymentConfiguration(
  processor: ProcessorType.custom,
  credentials: {
    'apiKey': 'your_api_key',
    'endpoint': 'https://api.yourprocessor.com',
  },
);

// Or extend PaymentConfigurationBuilder
extension CustomProcessorBuilder on PaymentConfigurationBuilder {
  PaymentConfigurationBuilder useCustomProcessor({
    required String apiKey,
    required String endpoint,
  }) {
    return this
      ..processor = ProcessorType.custom
      ..credentials = {
        'apiKey': apiKey,
        'endpoint': endpoint,
      };
  }
}
```

---

## Error Handling Strategies

### Comprehensive Error Handling

```dart
Future<Subscription> subscribeWithRetry(String priceId) async {
  int attempts = 0;
  const maxAttempts = 3;

  while (attempts < maxAttempts) {
    try {
      return await paymentService.subscribe(priceId: priceId);
    } on NetworkException catch (e) {
      attempts++;
      if (attempts >= maxAttempts) rethrow;

      // Exponential backoff
      await Future.delayed(Duration(seconds: pow(2, attempts).toInt()));

      PaymentLogger.warning('Network error, retrying... (attempt $attempts)');
    } on ProcessorException catch (e) {
      // Don't retry processor errors
      _handleProcessorError(e);
      rethrow;
    } on ValidationException catch (e) {
      // Don't retry validation errors
      _showValidationError(e.message);
      rethrow;
    }
  }

  throw PaymentException('Max retry attempts reached');
}

void _handleProcessorError(ProcessorException e) {
  switch (e.code) {
    case 'card_declined':
      _showError('Your card was declined. Please try another payment method.');
      break;
    case 'insufficient_funds':
      _showError('Insufficient funds. Please use a different card.');
      break;
    case 'expired_card':
      _showError('Your card has expired. Please update your payment method.');
      break;
    case 'invalid_cvc':
      _showError('Invalid security code. Please check and try again.');
      break;
    case 'processing_error':
      _showError('Payment processor error. Please try again.');
      break;
    default:
      _showError('Payment failed: ${e.message}');
  }
}
```

### Global Error Handler

```dart
class PaymentErrorHandler {
  static void handleError(
    Object error,
    StackTrace stackTrace,
    BuildContext context,
  ) {
    PaymentLogger.error('Payment error', error, stackTrace);

    String message;
    String? actionLabel;
    VoidCallback? action;

    if (error is AuthenticationException) {
      message = 'Authentication error. Please check your credentials.';
    } else if (error is NetworkException) {
      message = 'Network error. Please check your connection.';
      actionLabel = 'Retry';
      action = () => retryLastOperation();
    } else if (error is ProcessorException) {
      message = _getProcessorErrorMessage(error);
      if (error.code == 'card_declined') {
        actionLabel = 'Update Card';
        action = () => navigateToPaymentMethods(context);
      }
    } else if (error is ValidationException) {
      message = error.message;
    } else {
      message = 'An unexpected error occurred. Please try again.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: actionLabel != null
            ? SnackBarAction(label: actionLabel, onPressed: action!)
            : null,
      ),
    );
  }

  static String _getProcessorErrorMessage(ProcessorException e) {
    // Customize messages based on error codes
    return e.message;
  }
}
```

---

## Performance Optimization

### Caching Strategies

```dart
class OptimizedPaymentService {
  final PaymentService _service;
  final Cache _cache;

  Customer? _cachedCustomer;
  DateTime? _customerCacheTime;
  List<Subscription>? _cachedSubscriptions;
  DateTime? _subscriptionsCacheTime;

  static const cacheDuration = Duration(minutes: 5);

  Future<Customer?> getCustomer({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedCustomer != null &&
        _customerCacheTime != null &&
        DateTime.now().difference(_customerCacheTime!) < cacheDuration) {
      return _cachedCustomer;
    }

    _cachedCustomer = await _service.getCurrentCustomer();
    _customerCacheTime = DateTime.now();
    return _cachedCustomer;
  }

  Future<List<Subscription>> getSubscriptions({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _cachedSubscriptions != null &&
        _subscriptionsCacheTime != null &&
        DateTime.now().difference(_subscriptionsCacheTime!) < cacheDuration) {
      return _cachedSubscriptions!;
    }

    _cachedSubscriptions = await _service.getSubscriptions();
    _subscriptionsCacheTime = DateTime.now();
    return _cachedSubscriptions!;
  }

  void invalidateCache() {
    _cachedCustomer = null;
    _customerCacheTime = null;
    _cachedSubscriptions = null;
    _subscriptionsCacheTime = null;
  }
}
```

### Batch Operations

```dart
Future<List<Result>> batchOperations(
  List<Future<dynamic> Function()> operations,
) async {
  // Execute operations in parallel
  final futures = operations.map((op) => op()).toList();

  // Wait for all with error handling
  final results = await Future.wait(
    futures,
    eagerError: false,
  ).then((results) => results.map((r) => Result.success(r)).toList())
      .catchError((e) => [Result.failure(e)]);

  return results;
}

// Usage
final results = await batchOperations([
  () => paymentService.getCustomer(),
  () => paymentService.getSubscriptions(),
  () => paymentService.getPaymentMethods(),
]);
```

### Lazy Loading

```dart
class LazyPaymentData {
  Future<Customer>? _customerFuture;
  Future<List<Subscription>>? _subscriptionsFuture;

  Future<Customer> get customer {
    _customerFuture ??= paymentService.getCurrentCustomer();
    return _customerFuture!;
  }

  Future<List<Subscription>> get subscriptions {
    _subscriptionsFuture ??= paymentService.getSubscriptions();
    return _subscriptionsFuture!;
  }

  void reset() {
    _customerFuture = null;
    _subscriptionsFuture = null;
  }
}
```

---

## Security Best Practices

### Credential Management

```dart
// ❌ NEVER DO THIS
const apiKey = 'sk_live_abc123';

// ✅ Use environment variables
final apiKey = const String.fromEnvironment('PAYMENT_API_KEY');

// ✅ Or use secure storage
class SecureConfig {
  final FlutterSecureStorage _storage;

  Future<String?> getApiKey() async {
    return await _storage.read(key: 'payment_api_key');
  }

  Future<void> setApiKey(String key) async {
    await _storage.write(key: 'payment_api_key', value: key);
  }
}
```

### PCI Compliance

```dart
// ❌ NEVER store card data directly
class BadExample {
  String cardNumber = '4242424242424242';
  String cvv = '123';
}

// ✅ Always tokenize
class GoodExample {
  Future<String> tokenizeCard(PaymentCardData cardData) async {
    // Send to processor to tokenize
    final token = await processor.createPaymentMethodToken(cardData);
    // Store only the token
    return token;
  }
}
```

### Request Validation

```dart
class PaymentValidator {
  static bool validateAmount(int amount) {
    // Minimum charge amount
    if (amount < 50) return false;

    // Maximum charge amount (prevent mistakes)
    if (amount > 100000000) return false;

    return true;
  }

  static bool validateEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool validatePriceId(String priceId) {
    // Ensure it matches expected format
    return priceId.isNotEmpty && priceId.length < 100;
  }
}
```

### Rate Limiting

```dart
class RateLimiter {
  final Map<String, List<DateTime>> _requests = {};
  final int maxRequests;
  final Duration window;

  RateLimiter({
    this.maxRequests = 10,
    this.window = const Duration(minutes: 1),
  });

  Future<T> execute<T>(
    String key,
    Future<T> Function() operation,
  ) async {
    _cleanOldRequests(key);

    final requests = _requests[key] ?? [];
    if (requests.length >= maxRequests) {
      throw PaymentException('Rate limit exceeded. Please try again later.');
    }

    requests.add(DateTime.now());
    _requests[key] = requests;

    return await operation();
  }

  void _cleanOldRequests(String key) {
    final requests = _requests[key] ?? [];
    final cutoff = DateTime.now().subtract(window);
    requests.removeWhere((time) => time.isBefore(cutoff));
  }
}
```

---

## Analytics Integration

### Firebase Analytics

```dart
import 'package:firebase_analytics/firebase_analytics.dart';

class FirebasePaymentAnalytics implements AnalyticsProvider {
  final FirebaseAnalytics analytics;

  FirebasePaymentAnalytics(this.analytics);

  @override
  Future<void> logEvent(String event, Map<String, dynamic>? parameters) async {
    await analytics.logEvent(
      name: event,
      parameters: parameters,
    );
  }

  @override
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    for (final entry in properties.entries) {
      await analytics.setUserProperty(
        name: entry.key,
        value: entry.value?.toString(),
      );
    }
  }

  @override
  Future<void> logError(
    String message,
    Object? error,
    StackTrace? stackTrace,
  ) async {
    // Firebase Analytics doesn't directly log errors
    // Use Firebase Crashlytics instead
    await FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }
}

// Register with PaymentLogger
PaymentLogger.registerAnalyticsProvider(
  FirebasePaymentAnalytics(FirebaseAnalytics.instance),
);
```

### Custom Analytics

```dart
class CustomAnalytics implements AnalyticsProvider {
  final AnalyticsBackend backend;

  @override
  Future<void> logEvent(String event, Map<String, dynamic>? parameters) async {
    await backend.track(
      event: event,
      properties: {
        ...?parameters,
        'timestamp': DateTime.now().toIso8601String(),
        'app_version': await getAppVersion(),
      },
    );
  }

  @override
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    await backend.identify(properties);
  }
}
```

### Event Tracking Best Practices

```dart
// Track complete payment funnel
class PaymentFunnelTracker {
  void trackCheckoutStarted({
    required String planId,
    required int amount,
    required String currency,
  }) {
    PaymentLogger.logEvent('checkout_started', {
      'plan_id': planId,
      'amount': amount,
      'currency': currency,
    });
  }

  void trackPaymentMethodEntered() {
    PaymentLogger.logEvent('payment_method_entered', {});
  }

  void trackPaymentSubmitted({
    required String planId,
    required int amount,
  }) {
    PaymentLogger.logEvent('payment_submitted', {
      'plan_id': planId,
      'amount': amount,
    });
  }

  void trackPaymentSuccess({
    required String subscriptionId,
    required String planId,
    required int amount,
  }) {
    PaymentLogger.logEvent('payment_success', {
      'subscription_id': subscriptionId,
      'plan_id': planId,
      'amount': amount,
      'revenue': amount / 100, // For revenue tracking
    });
  }

  void trackPaymentFailure({
    required String planId,
    required String errorCode,
    required String errorMessage,
  }) {
    PaymentLogger.logEvent('payment_failed', {
      'plan_id': planId,
      'error_code': errorCode,
      'error_message': errorMessage,
    });
  }
}
```

---

## Logging Configuration

### Advanced Logging Setup

```dart
void setupPaymentLogging() {
  // Enable logging
  PaymentLogger.enable();

  // Set log level
  PaymentLogger.setLogLevel(LogLevel.info);

  // Enable sensitive data masking
  PaymentLogger.respectPrivacy = true;

  // Register analytics
  PaymentLogger.registerAnalyticsProvider(
    FirebasePaymentAnalytics(FirebaseAnalytics.instance),
  );

  PaymentLogger.registerAnalyticsProvider(
    SentryPaymentAnalytics(Sentry.instance),
  );
}
```

### Custom Log Formatting

```dart
class FormattedPaymentLogger {
  static void log(String message, {
    LogLevel level = LogLevel.info,
    Map<String, dynamic>? data,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final formattedMessage = '[$timestamp] [${level.name.toUpperCase()}] $message';

    if (data != null) {
      print('$formattedMessage\nData: ${jsonEncode(data)}');
    } else {
      print(formattedMessage);
    }

    // Forward to PaymentLogger
    switch (level) {
      case LogLevel.debug:
        PaymentLogger.debug(message, data);
        break;
      case LogLevel.info:
        PaymentLogger.info(message, data);
        break;
      case LogLevel.warning:
        PaymentLogger.warning(message, data);
        break;
      case LogLevel.error:
        PaymentLogger.error(message, data);
        break;
    }
  }
}
```

---

## Storage Patterns

### Encrypted Storage

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart';

class EncryptedPaymentStorage implements Storage {
  final FlutterSecureStorage _secureStorage;
  final Encrypter _encrypter;

  EncryptedPaymentStorage()
      : _secureStorage = const FlutterSecureStorage(),
        _encrypter = Encrypter(AES(Key.fromSecureRandom(32)));

  @override
  Future<String?> getString(String key) async {
    final encrypted = await _secureStorage.read(key: key);
    if (encrypted == null) return null;

    try {
      return _encrypter.decrypt64(encrypted);
    } catch (e) {
      PaymentLogger.error('Decryption failed for key: $key', e);
      return null;
    }
  }

  @override
  Future<void> setString(String key, String value) async {
    final encrypted = _encrypter.encrypt(value).base64;
    await _secureStorage.write(key: key, value: encrypted);
  }

  // Implement other methods...
}
```

### Multi-Layer Storage

```dart
class MultiLayerStorage implements Storage {
  final Storage memoryCache;
  final Storage persistentStorage;

  MultiLayerStorage({
    required this.memoryCache,
    required this.persistentStorage,
  });

  @override
  Future<String?> getString(String key) async {
    // Try memory cache first
    var value = await memoryCache.getString(key);
    if (value != null) return value;

    // Fall back to persistent storage
    value = await persistentStorage.getString(key);
    if (value != null) {
      // Update cache
      await memoryCache.setString(key, value);
    }

    return value;
  }

  @override
  Future<void> setString(String key, String value) async {
    // Write to both layers
    await Future.wait([
      memoryCache.setString(key, value),
      persistentStorage.setString(key, value),
    ]);
  }

  // Implement other methods...
}
```

---

## Testing Strategies

### Unit Testing

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPaymentProcessor extends Mock implements PaymentProcessor {}

void main() {
  group('PaymentService', () {
    late PaymentService service;
    late MockPaymentProcessor mockProcessor;
    late Storage storage;

    setUp(() {
      mockProcessor = MockPaymentProcessor();
      storage = InMemoryStorage();
      service = PaymentService(
        processor: mockProcessor,
        storage: storage,
      );
    });

    test('subscribe creates subscription', () async {
      // Arrange
      final subscription = Subscription(
        id: 'sub_123',
        customerId: 'cus_123',
        status: SubscriptionStatus.active,
        priceId: 'price_123',
        productId: 'prod_123',
        currentPeriodStart: DateTime.now(),
        currentPeriodEnd: DateTime.now().add(Duration(days: 30)),
        processor: ProcessorType.fake,
        processorSubscriptionId: 'sub_proc_123',
      );

      when(() => mockProcessor.createSubscription(
            customerId: any(named: 'customerId'),
            priceId: any(named: 'priceId'),
          )).thenAnswer((_) async => subscription);

      // Act
      final result = await service.subscribe(priceId: 'price_123');

      // Assert
      expect(result.id, subscription.id);
      expect(result.status, SubscriptionStatus.active);
      verify(() => mockProcessor.createSubscription(
            customerId: any(named: 'customerId'),
            priceId: 'price_123',
          )).called(1);
    });

    test('subscribe handles errors', () async {
      // Arrange
      when(() => mockProcessor.createSubscription(
            customerId: any(named: 'customerId'),
            priceId: any(named: 'priceId'),
          )).thenThrow(ProcessorException('Card declined'));

      // Act & Assert
      expect(
        () => service.subscribe(priceId: 'price_123'),
        throwsA(isA<ProcessorException>()),
      );
    });
  });
}
```

### Widget Testing

```dart
testWidgets('PaymentCardInput validates card number', (tester) async {
  PaymentCardData? cardData;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PaymentCardInput(
          onCardChanged: (data) => cardData = data,
        ),
      ),
    ),
  );

  // Enter invalid card number
  final cardField = find.byType(TextField).first;
  await tester.enterText(cardField, '1234');
  await tester.pump();

  expect(cardData?.isValid, false);
  expect(cardData?.cardNumberError, isNotNull);

  // Enter valid card number
  await tester.enterText(cardField, '4242424242424242');
  await tester.pump();

  expect(cardData?.cardNumber, '4242424242424242');
  expect(cardData?.cardBrand, CardBrand.visa);
});
```

### Integration Testing

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete payment flow', (tester) async {
    // Initialize with fake processor
    final config = PaymentConfigurationBuilder()
        .useFake()
        .build();

    await FlutterUniversalPayments.initialize(
      config: config,
      storage: InMemoryStorage(),
    );

    await tester.pumpWidget(MyApp());

    // Navigate to pricing
    await tester.tap(find.text('Subscribe'));
    await tester.pumpAndSettle();

    // Select plan
    await tester.tap(find.text('Pro Plan'));
    await tester.pumpAndSettle();

    // Enter card details
    await tester.enterText(
      find.byType(TextField).first,
      '4242424242424242',
    );
    await tester.enterText(
      find.byType(TextField).at(1),
      '12/25',
    );
    await tester.enterText(
      find.byType(TextField).at(2),
      '123',
    );

    // Submit
    await tester.tap(find.text('Subscribe Now'));
    await tester.pumpAndSettle();

    // Verify success
    expect(find.text('Subscription Active'), findsOneWidget);
  });
}
```

---

## Migration Guides

### From Direct Processor to Universal Payments

**Before:**
```dart
// Direct Stripe usage
final stripe = Stripe(apiKey: 'sk_...');
final customer = await stripe.customers.create(email: 'user@example.com');
final subscription = await stripe.subscriptions.create(
  customer: customer.id,
  items: [{'price': 'price_123'}],
);
```

**After:**
```dart
// Universal Payments
final config = PaymentConfigurationBuilder()
    .useStripe(...)
    .build();

await FlutterUniversalPayments.initialize(config: config, storage: storage);

final service = FlutterUniversalPayments.instance;
await service.initialize(email: 'user@example.com');
final subscription = await service.subscribe(priceId: 'price_123');
```

### Switching Processors

```dart
// Start with Stripe
await FlutterUniversalPayments.initialize(
  config: PaymentConfigurationBuilder().useStripe(...).build(),
  storage: storage,
);

// Later, switch to Paddle
await FlutterUniversalPayments.reinitialize(
  config: PaymentConfigurationBuilder().usePaddle(...).build(),
  storage: storage,
);

// Your app code doesn't change!
final subscription = await paymentService.subscribe(priceId: 'new_price_id');
```

---

## Best Practices Summary

1. **Always validate configurations** before going live
2. **Implement webhook handling** for asynchronous events
3. **Use proper error handling** with retry logic
4. **Cache data appropriately** to reduce API calls
5. **Never store sensitive payment data** - use tokenization
6. **Enable logging** during development
7. **Test thoroughly** with sandbox environments
8. **Monitor webhook delivery** and handle retries
9. **Implement rate limiting** to prevent abuse
10. **Keep credentials secure** using environment variables

---

For more examples and detailed code, check out the [example app](../example/) or explore the [test suite](../test/).
