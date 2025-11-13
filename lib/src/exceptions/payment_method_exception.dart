import 'payment_exception.dart';

/// Exception thrown when there's an error with a payment method.
///
/// This exception is used for payment method-related errors such as
/// invalid card details, expired cards, declined payments, insufficient
/// funds, or issues adding/updating payment methods.
class PaymentMethodException extends PaymentException {
  /// The type of payment method (e.g., 'card', 'bank_account', 'paypal').
  final String? paymentMethodType;

  /// The last 4 digits of the payment method (e.g., card number), if applicable.
  final String? last4;

  /// Creates a new [PaymentMethodException] with the given [message].
  ///
  /// Optionally includes:
  /// - [code]: Error code from the payment processor (e.g., 'card_declined')
  /// - [paymentMethodType]: The type of payment method that caused the error
  /// - [last4]: Last 4 digits of the payment method for identification
  /// - [originalError]: The original error object from the processor
  /// - [stackTrace]: Stack trace for debugging
  PaymentMethodException(
    super.message, {
    super.code,
    this.paymentMethodType,
    this.last4,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() {
    final typeStr = paymentMethodType != null ? ' ($paymentMethodType' : '';
    final last4Str = last4 != null ? ' ending in $last4)' : typeStr.isNotEmpty ? ')' : '';
    final codeStr = code != null ? ' (code: $code)' : '';
    return 'PaymentMethodException: $message$typeStr$last4Str$codeStr';
  }
}
