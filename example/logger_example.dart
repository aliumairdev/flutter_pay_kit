// ignore_for_file: avoid_print

import 'package:flutter_pay_kit/src/utils/logger.dart';
import 'package:flutter_pay_kit/src/utils/analytics_integrations.dart';

/// Example showing how to use PaymentLogger
void main() {
  // Example 1: Basic Configuration
  basicConfiguration();

  // Example 2: Logging different levels
  loggingDifferentLevels();

  // Example 3: Logging payment events
  loggingPaymentEvents();

  // Example 4: Privacy and sensitive data masking
  privacyAndMasking();

  // Example 5: Analytics provider integration
  analyticsProviderIntegration();

  // Example 6: Custom analytics provider
  customAnalyticsProvider();
}

/// Example 1: Basic configuration
void basicConfiguration() {
  print('\n=== Example 1: Basic Configuration ===\n');

  // Configure the logger
  PaymentLogger.configure(
    enabled: true,
    logLevel: LogLevel.debug,
    maskSensitiveData: true,
    gdprCompliant: true,
  );

  PaymentLogger.info('Logger configured and ready to use');
}

/// Example 2: Logging different levels
void loggingDifferentLevels() {
  print('\n=== Example 2: Logging Different Levels ===\n');

  PaymentLogger.debug('This is a debug message', data: {
    'userId': '12345',
    'action': 'checkout_started',
  });

  PaymentLogger.info('User initiated payment', data: {
    'amount': 2999,
    'currency': 'USD',
  });

  PaymentLogger.warning('Payment processor latency detected', data: {
    'latency_ms': 3500,
    'threshold_ms': 3000,
  });

  PaymentLogger.error(
    'Payment processing failed',
    error: Exception('Network timeout'),
    // stackTrace: StackTrace.current, // Uncomment to include stack trace
  );
}

/// Example 3: Logging payment events
void loggingPaymentEvents() {
  print('\n=== Example 3: Logging Payment Events ===\n');

  // Log payment success
  PaymentLogger.logPaymentSuccess(
    'stripe',
    2999, // $29.99 in cents
    'USD',
  );

  // Log payment failure
  PaymentLogger.logPaymentFailure(
    'stripe',
    'Card declined',
  );

  // Log subscription created
  PaymentLogger.logSubscriptionCreated(
    'stripe',
    'price_1234567890',
  );

  // Log subscription canceled
  PaymentLogger.logSubscriptionCanceled('sub_1234567890');

  // Log plan changed
  PaymentLogger.logPlanChanged(
    oldPlanId: 'plan_basic',
    newPlanId: 'plan_premium',
    processorType: 'stripe',
  );

  // Log payment method added
  PaymentLogger.logPaymentMethodAdded(
    processorType: 'stripe',
    paymentMethodType: 'card',
  );

  // Log checkout started
  PaymentLogger.logCheckoutStarted(
    processorType: 'stripe',
    amount: 4999,
    currency: 'USD',
  );

  // Log custom events
  PaymentLogger.logEvent(PaymentEvents.checkoutCompleted, parameters: {
    'processor_type': 'stripe',
    'amount': 4999,
    'currency': 'USD',
    'items_count': 3,
  });
}

/// Example 4: Privacy and sensitive data masking
void privacyAndMasking() {
  print('\n=== Example 4: Privacy and Sensitive Data Masking ===\n');

  // This data will be automatically masked
  PaymentLogger.info('Processing payment', data: {
    'amount': 2999,
    'currency': 'USD',
    'card_number': '4242424242424242', // Will be masked to ****4242
    'cvv': '123', // Will be masked to ***
    'user_id': '12345', // Not sensitive, will not be masked
    'card_holder': 'John Doe', // Not sensitive, will not be masked
  });

  // Nested sensitive data is also masked
  PaymentLogger.info('Payment method details', data: {
    'payment_method': {
      'type': 'card',
      'card': {
        'number': '5555555555554444', // Will be masked to ****4444
        'cvv': '456', // Will be masked to ***
        'exp_month': 12,
        'exp_year': 2025,
      },
    },
  });

  // Add custom sensitive field
  PaymentLogger.addSensitiveField('custom_secret');

  PaymentLogger.info('Custom sensitive field', data: {
    'custom_secret': 'my_secret_value', // Will be masked
    'public_info': 'not_secret', // Will not be masked
  });
}

/// Example 5: Analytics provider integration
void analyticsProviderIntegration() {
  print('\n=== Example 5: Analytics Provider Integration ===\n');

  // Register console analytics provider for debugging
  final consoleProvider = ConsoleAnalyticsProvider(verbose: true);
  PaymentLogger.registerAnalyticsProvider(consoleProvider);

  // Now all events will be sent to the console provider
  PaymentLogger.logEvent(PaymentEvents.paymentSuccess, parameters: {
    'processor_type': 'stripe',
    'amount': 2999,
    'currency': 'USD',
  });

  // You can register multiple providers
  // For example (commented out as these require external packages):

  /*
  // Firebase Analytics
  final firebaseProvider = FirebaseAnalyticsProvider(
    FirebaseAnalytics.instance,
  );
  PaymentLogger.registerAnalyticsProvider(firebaseProvider);

  // Crashlytics
  final crashlyticsProvider = CrashlyticsProvider(
    FirebaseCrashlytics.instance,
  );
  PaymentLogger.registerAnalyticsProvider(crashlyticsProvider);

  // Sentry
  final sentryProvider = SentryProvider();
  PaymentLogger.registerAnalyticsProvider(sentryProvider);
  */
}

/// Example 6: Custom analytics provider
void customAnalyticsProvider() {
  print('\n=== Example 6: Custom Analytics Provider ===\n');

  // Create a custom provider
  final customProvider = MyCustomAnalyticsProvider();
  PaymentLogger.registerAnalyticsProvider(customProvider);

  // Log events that will be sent to your custom provider
  PaymentLogger.logEvent('custom_event', parameters: {
    'custom_param': 'value',
  });
}

/// Example custom analytics provider
class MyCustomAnalyticsProvider extends CustomAnalyticsProvider {
  @override
  void logEvent(String event, {Map<String, dynamic>? parameters}) {
    // Send to your custom analytics backend
    print('[Custom Analytics] Event: $event');
    print('[Custom Analytics] Parameters: $parameters');

    // Example: Send to your API
    // await http.post(
    //   Uri.parse('https://your-api.com/analytics'),
    //   body: json.encode({
    //     'event': event,
    //     'parameters': parameters,
    //   }),
    // );
  }

  @override
  void setUserProperties(Map<String, dynamic> properties) {
    print('[Custom Analytics] User Properties: $properties');

    // Example: Update user properties in your system
    // await http.put(
    //   Uri.parse('https://your-api.com/user-properties'),
    //   body: json.encode(properties),
    // );
  }

  @override
  void logError(String message, {dynamic error, StackTrace? stackTrace}) {
    print('[Custom Analytics] Error: $message');

    // Example: Send error to your error tracking system
    // await http.post(
    //   Uri.parse('https://your-api.com/errors'),
    //   body: json.encode({
    //     'message': message,
    //     'error': error?.toString(),
    //     'stackTrace': stackTrace?.toString(),
    //   }),
    // );
  }
}

/// Example: Integration in a real payment flow
class PaymentFlowExample {
  Future<void> processPayment({
    required String processorType,
    required int amount,
    required String currency,
  }) async {
    try {
      // Log checkout started
      PaymentLogger.logCheckoutStarted(
        processorType: processorType,
        amount: amount,
        currency: currency,
      );

      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      // Check if payment succeeded (simulated)
      final succeeded = true;

      if (succeeded) {
        PaymentLogger.logPaymentSuccess(processorType, amount, currency);
        PaymentLogger.logEvent(PaymentEvents.checkoutCompleted, parameters: {
          'processor_type': processorType,
          'amount': amount,
          'currency': currency,
        });
      } else {
        PaymentLogger.logPaymentFailure(processorType, 'Payment declined');
        PaymentLogger.logEvent(PaymentEvents.checkoutAbandoned, parameters: {
          'processor_type': processorType,
          'reason': 'payment_declined',
        });
      }
    } catch (e, stackTrace) {
      PaymentLogger.error(
        'Payment processing error',
        error: e,
        stackTrace: stackTrace,
      );
      PaymentLogger.logPaymentFailure(processorType, e.toString());
      rethrow;
    }
  }
}

/// Example: Logger configuration in app initialization
class AppInitializationExample {
  static void initializeLogger() {
    // Configure logger on app startup
    PaymentLogger.configure(
      enabled: true,
      logLevel: LogLevel.info, // Use debug in development
      maskSensitiveData: true,
      gdprCompliant: true,
      respectUserPrivacyPreferences: true,
    );

    // Register analytics providers
    PaymentLogger.registerAnalyticsProvider(
      ConsoleAnalyticsProvider(verbose: false),
    );

    // In production, you might add:
    // - Firebase Analytics
    // - Crashlytics
    // - Sentry
    // - Your custom analytics backend

    PaymentLogger.info('Payment logger initialized');
  }
}
