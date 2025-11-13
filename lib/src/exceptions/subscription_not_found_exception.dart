import 'payment_exception.dart';

/// Exception thrown when a subscription cannot be found in the payment system.
///
/// This exception is used when attempting to retrieve or operate on a
/// subscription that doesn't exist in the payment processor's database.
class SubscriptionNotFoundException extends PaymentException {
  /// The subscription ID that was not found.
  final String? subscriptionId;

  /// Creates a new [SubscriptionNotFoundException] with the given [message].
  ///
  /// Optionally includes:
  /// - [code]: Error code from the payment processor
  /// - [subscriptionId]: The ID of the subscription that was not found
  /// - [originalError]: The original error object from the processor
  /// - [stackTrace]: Stack trace for debugging
  SubscriptionNotFoundException(
    super.message, {
    super.code,
    this.subscriptionId,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() {
    final subStr =
        subscriptionId != null ? ' (subscription: $subscriptionId)' : '';
    final codeStr = code != null ? ' (code: $code)' : '';
    return 'SubscriptionNotFoundException: $message$subStr$codeStr';
  }
}
