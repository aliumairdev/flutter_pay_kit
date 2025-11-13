import 'payment_exception.dart';

/// Exception thrown when a customer cannot be found in the payment system.
///
/// This exception is used when attempting to retrieve or operate on a
/// customer that doesn't exist in the payment processor's database.
class CustomerNotFoundException extends PaymentException {
  /// The customer ID that was not found.
  final String? customerId;

  /// Creates a new [CustomerNotFoundException] with the given [message].
  ///
  /// Optionally includes:
  /// - [code]: Error code from the payment processor
  /// - [customerId]: The ID of the customer that was not found
  /// - [originalError]: The original error object from the processor
  /// - [stackTrace]: Stack trace for debugging
  CustomerNotFoundException(
    super.message, {
    super.code,
    this.customerId,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() {
    final customerStr = customerId != null ? ' (customer: $customerId)' : '';
    final codeStr = code != null ? ' (code: $code)' : '';
    return 'CustomerNotFoundException: $message$customerStr$codeStr';
  }
}
