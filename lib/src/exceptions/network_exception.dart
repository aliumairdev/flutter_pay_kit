import 'payment_exception.dart';

/// Exception thrown when a network-related error occurs.
///
/// This exception is used for network connectivity issues, timeouts,
/// DNS failures, and other network-related problems when communicating
/// with payment processors or APIs.
class NetworkException extends PaymentException {
  /// The HTTP status code, if applicable.
  final int? statusCode;

  /// The URL that was being accessed when the error occurred.
  final String? url;

  /// Creates a new [NetworkException] with the given [message].
  ///
  /// Optionally includes:
  /// - [code]: Error code for the network issue
  /// - [statusCode]: HTTP status code (e.g., 404, 500, 503)
  /// - [url]: The URL that was being accessed
  /// - [originalError]: The original error object (e.g., from http package)
  /// - [stackTrace]: Stack trace for debugging
  NetworkException(
    super.message, {
    super.code,
    this.statusCode,
    this.url,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() {
    final statusStr = statusCode != null ? ' (status: $statusCode)' : '';
    final codeStr = code != null ? ' (code: $code)' : '';
    final urlStr = url != null ? ' at $url' : '';
    return 'NetworkException: $message$statusStr$codeStr$urlStr';
  }
}
