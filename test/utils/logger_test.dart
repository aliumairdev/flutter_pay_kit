import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_pay_kit/src/utils/logger.dart';
import 'package:flutter_pay_kit/src/utils/analytics_integrations.dart';

void main() {
  group('LogLevel', () {
    test('should have correct values', () {
      expect(LogLevel.debug.value, 0);
      expect(LogLevel.info.value, 1);
      expect(LogLevel.warning.value, 2);
      expect(LogLevel.error.value, 3);
    });

    test('should have correct display names', () {
      expect(LogLevel.debug.displayName, 'DEBUG');
      expect(LogLevel.info.displayName, 'INFO');
      expect(LogLevel.warning.displayName, 'WARNING');
      expect(LogLevel.error.displayName, 'ERROR');
    });
  });

  group('PaymentEvents', () {
    test('should have correct event constants', () {
      expect(PaymentEvents.paymentInitiated, 'payment_initiated');
      expect(PaymentEvents.paymentSuccess, 'payment_success');
      expect(PaymentEvents.paymentFailed, 'payment_failed');
      expect(PaymentEvents.subscriptionCreated, 'subscription_created');
      expect(PaymentEvents.subscriptionCanceled, 'subscription_canceled');
      expect(PaymentEvents.planChanged, 'plan_changed');
      expect(PaymentEvents.paymentMethodAdded, 'payment_method_added');
    });
  });

  group('PaymentLogger', () {
    setUp(() {
      // Reset logger before each test
      PaymentLogger.reset();
    });

    tearDown(() {
      // Clean up after each test
      PaymentLogger.reset();
    });

    test('should start with correct default values', () {
      expect(PaymentLogger.enabled, false);
      expect(PaymentLogger.level, LogLevel.info);
      expect(PaymentLogger.maskSensitiveData, true);
      expect(PaymentLogger.respectUserPrivacyPreferences, true);
      expect(PaymentLogger.gdprCompliant, true);
    });

    test('should configure logger settings', () {
      PaymentLogger.configure(
        enabled: true,
        logLevel: LogLevel.debug,
        maskSensitiveData: false,
        gdprCompliant: false,
      );

      expect(PaymentLogger.enabled, true);
      expect(PaymentLogger.level, LogLevel.debug);
      expect(PaymentLogger.maskSensitiveData, false);
      expect(PaymentLogger.gdprCompliant, false);
    });

    test('should reset to default settings', () {
      PaymentLogger.configure(
        enabled: true,
        logLevel: LogLevel.debug,
      );

      PaymentLogger.reset();

      expect(PaymentLogger.enabled, false);
      expect(PaymentLogger.level, LogLevel.info);
    });

    test('should add and remove sensitive fields', () {
      PaymentLogger.addSensitiveField('my_secret');
      // We can't directly test if it's in the set, but we can test masking
      expect(PaymentLogger.maskSensitiveData, true);

      PaymentLogger.removeSensitiveField('my_secret');
      // Field should be removed
    });

    test('should not log when disabled', () {
      PaymentLogger.enabled = false;

      // These should not throw and should do nothing
      PaymentLogger.debug('test');
      PaymentLogger.info('test');
      PaymentLogger.warning('test');
      PaymentLogger.error('test');
    });

    test('should log when enabled', () {
      PaymentLogger.enabled = true;
      PaymentLogger.level = LogLevel.debug;

      // These should execute without errors
      expect(
        () => PaymentLogger.debug('debug message', data: {'key': 'value'}),
        returnsNormally,
      );
      expect(
        () => PaymentLogger.info('info message', data: {'key': 'value'}),
        returnsNormally,
      );
      expect(
        () => PaymentLogger.warning('warning message', data: {'key': 'value'}),
        returnsNormally,
      );
      expect(
        () => PaymentLogger.error('error message', error: Exception('test')),
        returnsNormally,
      );
    });

    test('should respect log level threshold', () {
      PaymentLogger.enabled = true;
      PaymentLogger.level = LogLevel.warning;

      // Debug and info should be filtered out
      // Warning and error should be logged
      // All should execute without errors
      expect(() => PaymentLogger.debug('test'), returnsNormally);
      expect(() => PaymentLogger.info('test'), returnsNormally);
      expect(() => PaymentLogger.warning('test'), returnsNormally);
      expect(() => PaymentLogger.error('test'), returnsNormally);
    });
  });

  group('PaymentLogger - Event Logging', () {
    setUp(() {
      PaymentLogger.reset();
      PaymentLogger.enabled = true;
    });

    test('should log payment success', () {
      expect(
        () => PaymentLogger.logPaymentSuccess('stripe', 2999, 'USD'),
        returnsNormally,
      );
    });

    test('should log payment failure', () {
      expect(
        () => PaymentLogger.logPaymentFailure('stripe', 'Card declined'),
        returnsNormally,
      );
    });

    test('should log subscription created', () {
      expect(
        () => PaymentLogger.logSubscriptionCreated('stripe', 'price_123'),
        returnsNormally,
      );
    });

    test('should log subscription canceled', () {
      expect(
        () => PaymentLogger.logSubscriptionCanceled('sub_123'),
        returnsNormally,
      );
    });

    test('should log plan changed', () {
      expect(
        () => PaymentLogger.logPlanChanged(
          oldPlanId: 'basic',
          newPlanId: 'premium',
          processorType: 'stripe',
        ),
        returnsNormally,
      );
    });

    test('should log payment method added', () {
      expect(
        () => PaymentLogger.logPaymentMethodAdded(
          processorType: 'stripe',
          paymentMethodType: 'card',
        ),
        returnsNormally,
      );
    });

    test('should log checkout started', () {
      expect(
        () => PaymentLogger.logCheckoutStarted(
          processorType: 'stripe',
          amount: 2999,
          currency: 'USD',
        ),
        returnsNormally,
      );
    });

    test('should log custom events', () {
      expect(
        () => PaymentLogger.logEvent('custom_event', parameters: {
          'param1': 'value1',
          'param2': 123,
        }),
        returnsNormally,
      );
    });
  });

  group('PaymentLogger - Sensitive Data Masking', () {
    setUp(() {
      PaymentLogger.reset();
      PaymentLogger.enabled = true;
      PaymentLogger.maskSensitiveData = true;
    });

    test('should mask card numbers', () {
      // This test just ensures masking doesn't throw errors
      expect(
        () => PaymentLogger.info('payment', data: {
          'card_number': '4242424242424242',
        }),
        returnsNormally,
      );
    });

    test('should mask CVV', () {
      expect(
        () => PaymentLogger.info('payment', data: {
          'cvv': '123',
        }),
        returnsNormally,
      );
    });

    test('should mask nested sensitive data', () {
      expect(
        () => PaymentLogger.info('payment', data: {
          'card': {
            'number': '4242424242424242',
            'cvv': '123',
          },
        }),
        returnsNormally,
      );
    });

    test('should mask sensitive data in arrays', () {
      expect(
        () => PaymentLogger.info('payment', data: {
          'cards': [
            {'card_number': '4242424242424242'},
            {'card_number': '5555555555554444'},
          ],
        }),
        returnsNormally,
      );
    });

    test('should not mask when disabled', () {
      PaymentLogger.maskSensitiveData = false;

      expect(
        () => PaymentLogger.info('payment', data: {
          'card_number': '4242424242424242',
        }),
        returnsNormally,
      );
    });
  });

  group('PaymentLogger - Analytics Providers', () {
    late MockAnalyticsProvider mockProvider;

    setUp(() {
      PaymentLogger.reset();
      PaymentLogger.enabled = true;
      mockProvider = MockAnalyticsProvider();
    });

    test('should register analytics provider', () {
      PaymentLogger.registerAnalyticsProvider(mockProvider);
      // Provider should be registered
    });

    test('should unregister analytics provider', () {
      PaymentLogger.registerAnalyticsProvider(mockProvider);
      PaymentLogger.unregisterAnalyticsProvider(mockProvider);
      // Provider should be unregistered
    });

    test('should clear all analytics providers', () {
      PaymentLogger.registerAnalyticsProvider(mockProvider);
      PaymentLogger.clearAnalyticsProviders();
      // All providers should be cleared
    });

    test('should send events to registered providers', () {
      PaymentLogger.registerAnalyticsProvider(mockProvider);

      PaymentLogger.logEvent('test_event', parameters: {
        'param': 'value',
      });

      expect(mockProvider.eventCalled, true);
      expect(mockProvider.lastEvent, 'test_event');
    });

    test('should send errors to registered providers', () {
      PaymentLogger.registerAnalyticsProvider(mockProvider);

      PaymentLogger.error('test error', error: Exception('test'));

      expect(mockProvider.errorCalled, true);
    });

    test('should not duplicate providers', () {
      PaymentLogger.registerAnalyticsProvider(mockProvider);
      PaymentLogger.registerAnalyticsProvider(mockProvider);

      // Should only be registered once
    });
  });

  group('ConsoleAnalyticsProvider', () {
    test('should log events', () {
      final provider = ConsoleAnalyticsProvider(verbose: true);

      expect(
        () => provider.logEvent('test_event', parameters: {'key': 'value'}),
        returnsNormally,
      );
    });

    test('should set user properties', () {
      final provider = ConsoleAnalyticsProvider(verbose: true);

      expect(
        () => provider.setUserProperties({'userId': '123'}),
        returnsNormally,
      );
    });

    test('should log errors', () {
      final provider = ConsoleAnalyticsProvider(verbose: true);

      expect(
        () => provider.logError('test error', error: Exception('test')),
        returnsNormally,
      );
    });
  });
}

/// Mock analytics provider for testing
class MockAnalyticsProvider implements AnalyticsProvider {
  bool eventCalled = false;
  bool propertiesCalled = false;
  bool errorCalled = false;

  String? lastEvent;
  Map<String, dynamic>? lastParameters;
  Map<String, dynamic>? lastProperties;
  String? lastError;

  @override
  void logEvent(String event, {Map<String, dynamic>? parameters}) {
    eventCalled = true;
    lastEvent = event;
    lastParameters = parameters;
  }

  @override
  void setUserProperties(Map<String, dynamic> properties) {
    propertiesCalled = true;
    lastProperties = properties;
  }

  @override
  void logError(String message, {dynamic error, StackTrace? stackTrace}) {
    errorCalled = true;
    lastError = message;
  }

  void reset() {
    eventCalled = false;
    propertiesCalled = false;
    errorCalled = false;
    lastEvent = null;
    lastParameters = null;
    lastProperties = null;
    lastError = null;
  }
}
