# Payment Logger

Comprehensive logging and analytics infrastructure for the Flutter Payment Kit.

## Features

- **Multiple Log Levels**: Debug, Info, Warning, Error
- **Privacy-First**: Automatic masking of sensitive payment data (card numbers, CVV, etc.)
- **GDPR Compliant**: Built-in privacy features and opt-out mechanisms
- **Analytics Integration**: Support for Firebase Analytics, Crashlytics, Sentry, and custom providers
- **Event Tracking**: Pre-defined payment events for consistent analytics
- **Structured Logging**: JSON-formatted logs with timestamps and context
- **Configurable**: Easy to enable/disable and configure per environment

## Quick Start

### Basic Configuration

```dart
import 'package:flutter_pay_kit/src/utils/logger.dart';

// Configure on app startup
void main() {
  PaymentLogger.configure(
    enabled: true,
    logLevel: LogLevel.info,
    maskSensitiveData: true,
    gdprCompliant: true,
  );

  runApp(MyApp());
}
```

### Basic Logging

```dart
// Log different levels
PaymentLogger.debug('Debug message', data: {'key': 'value'});
PaymentLogger.info('Info message', data: {'userId': '12345'});
PaymentLogger.warning('Warning message', data: {'latency': 3500});
PaymentLogger.error('Error message', error: exception, stackTrace: stackTrace);
```

### Payment Event Logging

```dart
// Log payment success
PaymentLogger.logPaymentSuccess('stripe', 2999, 'USD');

// Log payment failure
PaymentLogger.logPaymentFailure('stripe', 'Card declined');

// Log subscription events
PaymentLogger.logSubscriptionCreated('stripe', 'price_123');
PaymentLogger.logSubscriptionCanceled('sub_123');

// Log plan changes
PaymentLogger.logPlanChanged(
  oldPlanId: 'basic',
  newPlanId: 'premium',
  processorType: 'stripe',
);

// Log checkout events
PaymentLogger.logCheckoutStarted(
  processorType: 'stripe',
  amount: 4999,
  currency: 'USD',
);
```

### Custom Events

```dart
PaymentLogger.logEvent(PaymentEvents.checkoutCompleted, parameters: {
  'processor_type': 'stripe',
  'amount': 4999,
  'currency': 'USD',
  'items_count': 3,
});
```

## Privacy & Security

### Automatic Data Masking

The logger automatically masks sensitive payment data:

```dart
PaymentLogger.info('Processing payment', data: {
  'amount': 2999,
  'card_number': '4242424242424242', // Masked to ****4242
  'cvv': '123',                       // Masked to ***
  'user_id': '12345',                 // Not masked
});
```

### Sensitive Fields

The following fields are automatically masked:
- card_number / cardNumber
- cvv / cvc
- card_cvv / card_cvc
- pin
- password
- secret
- token / api_key / apiKey
- access_token / accessToken
- refresh_token / refreshToken
- private_key / privateKey

### Add Custom Sensitive Fields

```dart
PaymentLogger.addSensitiveField('custom_secret');
```

### Disable Masking (Not Recommended)

```dart
PaymentLogger.configure(maskSensitiveData: false);
```

## Analytics Integration

### Console Provider (Development)

```dart
import 'package:flutter_pay_kit/src/utils/analytics_integrations.dart';

PaymentLogger.registerAnalyticsProvider(
  ConsoleAnalyticsProvider(verbose: true),
);
```

### Firebase Analytics

```dart
import 'package:firebase_analytics/firebase_analytics.dart';

class FirebaseAnalyticsProvider implements AnalyticsProvider {
  final FirebaseAnalytics _analytics;

  FirebaseAnalyticsProvider(this._analytics);

  @override
  void logEvent(String event, {Map<String, dynamic>? parameters}) {
    _analytics.logEvent(
      name: event,
      parameters: parameters?.map(
        (key, value) => MapEntry(key, value?.toString()),
      ),
    );
  }

  @override
  void setUserProperties(Map<String, dynamic> properties) {
    properties.forEach((key, value) {
      _analytics.setUserProperty(name: key, value: value?.toString());
    });
  }

  @override
  void logError(String message, {dynamic error, StackTrace? stackTrace}) {
    _analytics.logEvent(
      name: 'error',
      parameters: {
        'message': message,
        'error': error?.toString(),
      },
    );
  }
}

// Register the provider
PaymentLogger.registerAnalyticsProvider(
  FirebaseAnalyticsProvider(FirebaseAnalytics.instance),
);
```

### Custom Analytics Provider

```dart
class MyCustomProvider extends CustomAnalyticsProvider {
  @override
  void logEvent(String event, {Map<String, dynamic>? parameters}) {
    // Send to your analytics backend
  }

  @override
  void setUserProperties(Map<String, dynamic> properties) {
    // Update user properties
  }

  @override
  void logError(String message, {dynamic error, StackTrace? stackTrace}) {
    // Send errors to your error tracking system
  }
}

PaymentLogger.registerAnalyticsProvider(MyCustomProvider());
```

## Pre-defined Events

The `PaymentEvents` class provides constants for common payment events:

- `paymentInitiated` - Payment process started
- `paymentSuccess` - Payment completed successfully
- `paymentFailed` - Payment failed
- `subscriptionCreated` - New subscription created
- `subscriptionCanceled` - Subscription canceled
- `planChanged` - Subscription plan changed
- `paymentMethodAdded` - Payment method added
- `paymentMethodRemoved` - Payment method removed
- `refundProcessed` - Refund completed
- `checkoutStarted` - Checkout process started
- `checkoutCompleted` - Checkout completed
- `checkoutAbandoned` - Checkout abandoned

## Configuration Options

```dart
PaymentLogger.configure(
  enabled: true,                          // Enable/disable logging
  logLevel: LogLevel.info,                // Minimum log level to output
  maskSensitiveData: true,                // Mask sensitive payment data
  respectUserPrivacyPreferences: true,    // Respect user privacy settings
  gdprCompliant: true,                    // GDPR compliance mode
);
```

## Log Levels

| Level   | Value | Use Case |
|---------|-------|----------|
| debug   | 0     | Detailed debugging information |
| info    | 1     | General informational messages |
| warning | 2     | Warning messages |
| error   | 3     | Error messages |

Only logs at or above the configured level will be output.

## Best Practices

1. **Enable in Production**: Set `enabled: true` but use `LogLevel.info` or higher
2. **Always Mask Sensitive Data**: Never disable `maskSensitiveData` in production
3. **GDPR Compliance**: Keep `gdprCompliant: true` to respect user privacy
4. **Use Predefined Events**: Prefer `PaymentEvents` constants for consistency
5. **Context Data**: Include relevant context in the `data` parameter
6. **Error Logging**: Always include error and stackTrace when logging errors

## Environment-Specific Configuration

### Development

```dart
PaymentLogger.configure(
  enabled: true,
  logLevel: LogLevel.debug,
  maskSensitiveData: true,
);
```

### Production

```dart
PaymentLogger.configure(
  enabled: true,
  logLevel: LogLevel.info,  // Less verbose
  maskSensitiveData: true,
  gdprCompliant: true,
);
```

## Complete Example

```dart
import 'package:flutter_pay_kit/src/utils/logger.dart';
import 'package:flutter_pay_kit/src/utils/analytics_integrations.dart';

class PaymentService {
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

      // Process payment
      final result = await _processPaymentWithProcessor(
        processorType,
        amount,
        currency,
      );

      if (result.success) {
        PaymentLogger.logPaymentSuccess(processorType, amount, currency);
        PaymentLogger.logEvent(PaymentEvents.checkoutCompleted);
      } else {
        PaymentLogger.logPaymentFailure(processorType, result.error);
      }

      return result;
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
```

## Testing

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_pay_kit/src/utils/logger.dart';

void main() {
  setUp(() {
    PaymentLogger.reset();
  });

  test('should log events', () {
    PaymentLogger.configure(enabled: true);

    expect(
      () => PaymentLogger.logPaymentSuccess('stripe', 2999, 'USD'),
      returnsNormally,
    );
  });
}
```

## FAQ

### Q: How do I disable logging in tests?

```dart
setUp(() {
  PaymentLogger.enabled = false;
});
```

### Q: Can I use multiple analytics providers?

Yes! Register as many as you need:

```dart
PaymentLogger.registerAnalyticsProvider(firebaseProvider);
PaymentLogger.registerAnalyticsProvider(sentryProvider);
PaymentLogger.registerAnalyticsProvider(customProvider);
```

### Q: How do I temporarily disable a provider?

```dart
PaymentLogger.unregisterAnalyticsProvider(provider);
```

### Q: Is card data ever logged?

No. All sensitive fields are automatically masked when `maskSensitiveData: true` (default).

### Q: How do I log custom events?

```dart
PaymentLogger.logEvent('my_custom_event', parameters: {
  'custom_param': 'value',
});
```

## License

This is part of the Flutter Pay Kit package. See the main package LICENSE for details.
