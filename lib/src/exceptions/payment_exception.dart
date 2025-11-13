/// Base exception class for all payment-related errors.
///
/// This abstract class serves as the foundation for all payment exceptions
/// in the flutter_universal_payments package. It provides common properties
/// for error handling and debugging.
abstract class PaymentException implements Exception {
  /// A human-readable description of the error.
  final String message;

  /// An optional error code from the payment processor or internal system.
  final String? code;

  /// The original error object, if any, for debugging purposes.
  final dynamic originalError;

  /// The stack trace associated with this exception, if available.
  final StackTrace? stackTrace;

  /// Creates a new [PaymentException] with the given [message].
  ///
  /// Optionally includes an error [code], [originalError] for debugging,
  /// and a [stackTrace] for error tracking.
  PaymentException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'PaymentException: $message';
}
