import 'payment_exception.dart';

/// Exception thrown when API authentication fails.
///
/// This exception is used when there are issues authenticating with payment
/// processor APIs, such as invalid API keys, expired tokens, insufficient
/// permissions, or unauthorized access attempts.
class AuthenticationException extends PaymentException {
  /// The type of authentication that failed (e.g., 'api_key', 'oauth', 'jwt').
  final String? authenticationType;

  /// Creates a new [AuthenticationException] with the given [message].
  ///
  /// Optionally includes:
  /// - [code]: Error code from the payment processor
  /// - [authenticationType]: The type of authentication that failed
  /// - [originalError]: The original error object from the processor
  /// - [stackTrace]: Stack trace for debugging
  AuthenticationException(
    super.message, {
    super.code,
    this.authenticationType,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() {
    final typeStr = authenticationType != null ? ' ($authenticationType)' : '';
    final codeStr = code != null ? ' (code: $code)' : '';
    return 'AuthenticationException: $message$typeStr$codeStr';
  }
}
