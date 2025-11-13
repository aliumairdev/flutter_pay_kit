import 'dart:convert';
import 'dart:developer' as developer;

/// Log levels for payment logging
enum LogLevel {
  debug,
  info,
  warning,
  error;

  /// Get numeric value for comparison
  int get value {
    switch (this) {
      case LogLevel.debug:
        return 0;
      case LogLevel.info:
        return 1;
      case LogLevel.warning:
        return 2;
      case LogLevel.error:
        return 3;
    }
  }

  /// Get display name
  String get displayName {
    switch (this) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARNING';
      case LogLevel.error:
        return 'ERROR';
    }
  }
}

/// Payment event constants for analytics tracking
class PaymentEvents {
  PaymentEvents._();

  static const String paymentInitiated = 'payment_initiated';
  static const String paymentSuccess = 'payment_success';
  static const String paymentFailed = 'payment_failed';
  static const String subscriptionCreated = 'subscription_created';
  static const String subscriptionCanceled = 'subscription_canceled';
  static const String planChanged = 'plan_changed';
  static const String paymentMethodAdded = 'payment_method_added';
  static const String paymentMethodRemoved = 'payment_method_removed';
  static const String refundProcessed = 'refund_processed';
  static const String checkoutStarted = 'checkout_started';
  static const String checkoutCompleted = 'checkout_completed';
  static const String checkoutAbandoned = 'checkout_abandoned';
}

/// Abstract analytics provider interface for integration
abstract class AnalyticsProvider {
  /// Log an event with optional parameters
  void logEvent(String event, {Map<String, dynamic>? parameters});

  /// Set user properties
  void setUserProperties(Map<String, dynamic> properties);

  /// Log an error
  void logError(String message, {dynamic error, StackTrace? stackTrace});
}

/// Main payment logger class for logging and analytics
class PaymentLogger {
  PaymentLogger._();

  /// Enable or disable logging globally
  static bool enabled = false;

  /// Current log level threshold
  static LogLevel level = LogLevel.info;

  /// List of registered analytics providers
  static final List<AnalyticsProvider> _analyticsProviders = [];

  /// Privacy settings
  static bool maskSensitiveData = true;
  static bool respectUserPrivacyPreferences = true;
  static bool gdprCompliant = true;

  /// Sensitive field patterns to mask
  static final Set<String> _sensitiveFields = {
    'card_number',
    'cardNumber',
    'cvv',
    'cvc',
    'card_cvv',
    'card_cvc',
    'pin',
    'password',
    'secret',
    'token',
    'api_key',
    'apiKey',
    'access_token',
    'accessToken',
    'refresh_token',
    'refreshToken',
    'private_key',
    'privateKey',
  };

  /// Register an analytics provider
  static void registerAnalyticsProvider(AnalyticsProvider provider) {
    if (!_analyticsProviders.contains(provider)) {
      _analyticsProviders.add(provider);
    }
  }

  /// Unregister an analytics provider
  static void unregisterAnalyticsProvider(AnalyticsProvider provider) {
    _analyticsProviders.remove(provider);
  }

  /// Clear all analytics providers
  static void clearAnalyticsProviders() {
    _analyticsProviders.clear();
  }

  /// Log a debug message
  static void debug(String message, {Map<String, dynamic>? data}) {
    _log(LogLevel.debug, message, data: data);
  }

  /// Log an info message
  static void info(String message, {Map<String, dynamic>? data}) {
    _log(LogLevel.info, message, data: data);
  }

  /// Log a warning message
  static void warning(String message, {Map<String, dynamic>? data}) {
    _log(LogLevel.warning, message, data: data);
  }

  /// Log an error message
  static void error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.error,
      message,
      error: error,
      stackTrace: stackTrace,
    );

    // Send errors to analytics providers
    if (enabled) {
      for (final provider in _analyticsProviders) {
        try {
          provider.logError(message, error: error, stackTrace: stackTrace);
        } catch (e) {
          developer.log(
            'Failed to send error to analytics provider: $e',
            name: 'PaymentLogger',
          );
        }
      }
    }
  }

  /// Log a custom event
  static void logEvent(String event, {Map<String, dynamic>? parameters}) {
    if (!enabled) return;

    final sanitizedParams = maskSensitiveData && parameters != null
        ? _maskSensitiveData(parameters)
        : parameters;

    _log(
      LogLevel.info,
      'Event: $event',
      data: sanitizedParams,
    );

    // Send to analytics providers
    for (final provider in _analyticsProviders) {
      try {
        provider.logEvent(event, parameters: sanitizedParams);
      } catch (e) {
        developer.log(
          'Failed to send event to analytics provider: $e',
          name: 'PaymentLogger',
        );
      }
    }
  }

  /// Log a successful payment
  static void logPaymentSuccess(
    String processorType,
    int amount,
    String currency,
  ) {
    logEvent(PaymentEvents.paymentSuccess, parameters: {
      'processor_type': processorType,
      'amount': amount,
      'currency': currency,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Log a failed payment
  static void logPaymentFailure(String processorType, String error) {
    logEvent(PaymentEvents.paymentFailed, parameters: {
      'processor_type': processorType,
      'error': error,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Log subscription creation
  static void logSubscriptionCreated(String processorType, String priceId) {
    logEvent(PaymentEvents.subscriptionCreated, parameters: {
      'processor_type': processorType,
      'price_id': priceId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Log subscription cancellation
  static void logSubscriptionCanceled(String subscriptionId) {
    logEvent(PaymentEvents.subscriptionCanceled, parameters: {
      'subscription_id': subscriptionId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Log plan change
  static void logPlanChanged({
    required String oldPlanId,
    required String newPlanId,
    String? processorType,
  }) {
    logEvent(PaymentEvents.planChanged, parameters: {
      'old_plan_id': oldPlanId,
      'new_plan_id': newPlanId,
      if (processorType != null) 'processor_type': processorType,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Log payment method addition
  static void logPaymentMethodAdded({
    required String processorType,
    required String paymentMethodType,
  }) {
    logEvent(PaymentEvents.paymentMethodAdded, parameters: {
      'processor_type': processorType,
      'payment_method_type': paymentMethodType,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Log checkout started
  static void logCheckoutStarted({
    required String processorType,
    required int amount,
    required String currency,
  }) {
    logEvent(PaymentEvents.checkoutStarted, parameters: {
      'processor_type': processorType,
      'amount': amount,
      'currency': currency,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Internal logging method
  static void _log(
    LogLevel logLevel,
    String message, {
    Map<String, dynamic>? data,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    if (!enabled) return;
    if (logLevel.value < level.value) return;

    final timestamp = DateTime.now().toIso8601String();
    final sanitizedData = maskSensitiveData && data != null
        ? _maskSensitiveData(data)
        : data;

    final logEntry = _formatLogEntry(
      timestamp: timestamp,
      level: logLevel,
      message: message,
      data: sanitizedData,
      error: error,
      stackTrace: stackTrace,
    );

    // Output to developer console
    developer.log(
      logEntry,
      name: 'PaymentLogger',
      time: DateTime.now(),
      level: _getLogLevelValue(logLevel),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Format log entry with timestamp and context
  static String _formatLogEntry({
    required String timestamp,
    required LogLevel level,
    required String message,
    Map<String, dynamic>? data,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    final buffer = StringBuffer();
    buffer.write('[$timestamp] [${level.displayName}] $message');

    if (data != null && data.isNotEmpty) {
      try {
        final jsonData = json.encode(data);
        buffer.write(' | Data: $jsonData');
      } catch (e) {
        buffer.write(' | Data: ${data.toString()}');
      }
    }

    if (error != null) {
      buffer.write(' | Error: $error');
    }

    if (stackTrace != null) {
      buffer.write(' | StackTrace: $stackTrace');
    }

    return buffer.toString();
  }

  /// Mask sensitive data in maps
  static Map<String, dynamic> _maskSensitiveData(Map<String, dynamic> data) {
    final masked = <String, dynamic>{};

    data.forEach((key, value) {
      if (_isSensitiveField(key)) {
        masked[key] = _maskValue(value);
      } else if (value is Map<String, dynamic>) {
        masked[key] = _maskSensitiveData(value);
      } else if (value is List) {
        masked[key] = value.map((item) {
          if (item is Map<String, dynamic>) {
            return _maskSensitiveData(item);
          }
          return item;
        }).toList();
      } else {
        masked[key] = value;
      }
    });

    return masked;
  }

  /// Check if a field name is sensitive
  static bool _isSensitiveField(String fieldName) {
    final lowerField = fieldName.toLowerCase();
    return _sensitiveFields.any((pattern) =>
      lowerField.contains(pattern.toLowerCase())
    );
  }

  /// Mask a value
  static String _maskValue(dynamic value) {
    if (value == null) return '***';

    final str = value.toString();
    if (str.isEmpty) return '***';

    // For card numbers, show last 4 digits
    if (str.length >= 4 && RegExp(r'^\d+$').hasMatch(str)) {
      return '****${str.substring(str.length - 4)}';
    }

    return '***';
  }

  /// Get numeric log level for dart:developer
  static int _getLogLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500; // Config level
      case LogLevel.info:
        return 800; // Info level
      case LogLevel.warning:
        return 900; // Warning level
      case LogLevel.error:
        return 1000; // Severe level
    }
  }

  /// Add a sensitive field pattern to the mask list
  static void addSensitiveField(String fieldName) {
    _sensitiveFields.add(fieldName);
  }

  /// Remove a sensitive field pattern from the mask list
  static void removeSensitiveField(String fieldName) {
    _sensitiveFields.remove(fieldName);
  }

  /// Configure logger settings
  static void configure({
    bool? enabled,
    LogLevel? logLevel,
    bool? maskSensitiveData,
    bool? respectUserPrivacyPreferences,
    bool? gdprCompliant,
  }) {
    if (enabled != null) PaymentLogger.enabled = enabled;
    if (logLevel != null) PaymentLogger.level = logLevel;
    if (maskSensitiveData != null) {
      PaymentLogger.maskSensitiveData = maskSensitiveData;
    }
    if (respectUserPrivacyPreferences != null) {
      PaymentLogger.respectUserPrivacyPreferences = respectUserPrivacyPreferences;
    }
    if (gdprCompliant != null) PaymentLogger.gdprCompliant = gdprCompliant;
  }

  /// Reset logger to default settings
  static void reset() {
    enabled = false;
    level = LogLevel.info;
    maskSensitiveData = true;
    respectUserPrivacyPreferences = true;
    gdprCompliant = true;
    clearAnalyticsProviders();
  }
}
