import 'payment_exception.dart';

/// Exception thrown when a payment processor returns an error.
///
/// This exception is used to wrap errors returned by payment processors
/// like Stripe, RevenueCat, or PayPal. It preserves the original error
/// details for debugging and provides a consistent interface for error handling.
class ProcessorException extends PaymentException {
  /// The name of the payment processor that generated the error.
  final String? processorName;

  /// Creates a new [ProcessorException] with the given [message].
  ///
  /// Optionally includes:
  /// - [code]: Error code from the payment processor
  /// - [processorName]: Name of the payment processor (e.g., 'Stripe', 'RevenueCat')
  /// - [originalError]: The original error object from the processor
  /// - [stackTrace]: Stack trace for debugging
  ProcessorException(
    super.message, {
    super.code,
    this.processorName,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() {
    final prefix = processorName != null ? '$processorName ' : '';
    final codeStr = code != null ? ' (code: $code)' : '';
    return '${prefix}ProcessorException: $message$codeStr';
  }
}
