import 'logger.dart';

/// Example Firebase Analytics integration
///
/// To use this, add firebase_analytics to your pubspec.yaml and implement:
/// ```dart
/// import 'package:firebase_analytics/firebase_analytics.dart';
///
/// class FirebaseAnalyticsProvider implements AnalyticsProvider {
///   final FirebaseAnalytics _analytics;
///
///   FirebaseAnalyticsProvider(this._analytics);
///
///   @override
///   void logEvent(String event, {Map<String, dynamic>? parameters}) {
///     _analytics.logEvent(
///       name: event,
///       parameters: parameters?.map(
///         (key, value) => MapEntry(key, value?.toString()),
///       ),
///     );
///   }
///
///   @override
///   void setUserProperties(Map<String, dynamic> properties) {
///     properties.forEach((key, value) {
///       _analytics.setUserProperty(name: key, value: value?.toString());
///     });
///   }
///
///   @override
///   void logError(String message, {dynamic error, StackTrace? stackTrace}) {
///     _analytics.logEvent(
///       name: 'error',
///       parameters: {
///         'message': message,
///         'error': error?.toString(),
///       },
///     );
///   }
/// }
/// ```

/// Example Crashlytics integration
///
/// To use this, add firebase_crashlytics to your pubspec.yaml and implement:
/// ```dart
/// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
///
/// class CrashlyticsProvider implements AnalyticsProvider {
///   final FirebaseCrashlytics _crashlytics;
///
///   CrashlyticsProvider(this._crashlytics);
///
///   @override
///   void logEvent(String event, {Map<String, dynamic>? parameters}) {
///     _crashlytics.log('Event: $event, Parameters: $parameters');
///   }
///
///   @override
///   void setUserProperties(Map<String, dynamic> properties) {
///     properties.forEach((key, value) {
///       _crashlytics.setCustomKey(key, value?.toString() ?? '');
///     });
///   }
///
///   @override
///   void logError(String message, {dynamic error, StackTrace? stackTrace}) {
///     _crashlytics.recordError(
///       error ?? message,
///       stackTrace,
///       reason: message,
///     );
///   }
/// }
/// ```

/// Example Sentry integration
///
/// To use this, add sentry_flutter to your pubspec.yaml and implement:
/// ```dart
/// import 'package:sentry_flutter/sentry_flutter.dart';
///
/// class SentryProvider implements AnalyticsProvider {
///   @override
///   void logEvent(String event, {Map<String, dynamic>? parameters}) {
///     Sentry.addBreadcrumb(
///       Breadcrumb(
///         message: event,
///         data: parameters,
///         timestamp: DateTime.now(),
///       ),
///     );
///   }
///
///   @override
///   void setUserProperties(Map<String, dynamic> properties) {
///     Sentry.configureScope((scope) {
///       properties.forEach((key, value) {
///         scope.setContexts(key, value);
///       });
///     });
///   }
///
///   @override
///   void logError(String message, {dynamic error, StackTrace? stackTrace}) {
///     Sentry.captureException(
///       error ?? Exception(message),
///       stackTrace: stackTrace,
///     );
///   }
/// }
/// ```

/// Custom console analytics provider for debugging
class ConsoleAnalyticsProvider implements AnalyticsProvider {
  final bool verbose;

  ConsoleAnalyticsProvider({this.verbose = false});

  @override
  void logEvent(String event, {Map<String, dynamic>? parameters}) {
    print('[Analytics] Event: $event');
    if (verbose && parameters != null) {
      print('[Analytics] Parameters: $parameters');
    }
  }

  @override
  void setUserProperties(Map<String, dynamic> properties) {
    if (verbose) {
      print('[Analytics] User Properties: $properties');
    }
  }

  @override
  void logError(String message, {dynamic error, StackTrace? stackTrace}) {
    print('[Analytics] Error: $message');
    if (verbose) {
      if (error != null) print('[Analytics] Error Details: $error');
      if (stackTrace != null) print('[Analytics] StackTrace: $stackTrace');
    }
  }
}

/// Custom analytics provider that can be extended
abstract class CustomAnalyticsProvider implements AnalyticsProvider {
  /// Override this to handle events in your custom way
  @override
  void logEvent(String event, {Map<String, dynamic>? parameters});

  /// Override this to set user properties in your custom way
  @override
  void setUserProperties(Map<String, dynamic> properties);

  /// Override this to log errors in your custom way
  @override
  void logError(String message, {dynamic error, StackTrace? stackTrace});
}

/// Example of a custom provider that sends logs to a remote server
///
/// ```dart
/// class RemoteAnalyticsProvider extends CustomAnalyticsProvider {
///   final String apiEndpoint;
///   final http.Client httpClient;
///
///   RemoteAnalyticsProvider({
///     required this.apiEndpoint,
///     required this.httpClient,
///   });
///
///   @override
///   void logEvent(String event, {Map<String, dynamic>? parameters}) async {
///     try {
///       await httpClient.post(
///         Uri.parse('$apiEndpoint/events'),
///         headers: {'Content-Type': 'application/json'},
///         body: json.encode({
///           'event': event,
///           'parameters': parameters,
///           'timestamp': DateTime.now().toIso8601String(),
///         }),
///       );
///     } catch (e) {
///       print('Failed to send event to remote server: $e');
///     }
///   }
///
///   @override
///   void setUserProperties(Map<String, dynamic> properties) async {
///     try {
///       await httpClient.post(
///         Uri.parse('$apiEndpoint/user-properties'),
///         headers: {'Content-Type': 'application/json'},
///         body: json.encode(properties),
///       );
///     } catch (e) {
///       print('Failed to send user properties to remote server: $e');
///     }
///   }
///
///   @override
///   void logError(String message, {dynamic error, StackTrace? stackTrace}) async {
///     try {
///       await httpClient.post(
///         Uri.parse('$apiEndpoint/errors'),
///         headers: {'Content-Type': 'application/json'},
///         body: json.encode({
///           'message': message,
///           'error': error?.toString(),
///           'stackTrace': stackTrace?.toString(),
///           'timestamp': DateTime.now().toIso8601String(),
///         }),
///       );
///     } catch (e) {
///       print('Failed to send error to remote server: $e');
///     }
///   }
/// }
/// ```
