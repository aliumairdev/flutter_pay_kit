import 'payment_exception.dart';

/// Exception thrown when there's an error processing a webhook.
///
/// This exception is used for webhook-related errors such as signature
/// verification failures, invalid payload formats, unrecognized event types,
/// or errors during webhook event processing.
class WebhookException extends PaymentException {
  /// The webhook event type (e.g., 'payment.succeeded', 'subscription.updated').
  final String? eventType;

  /// The webhook ID, if available.
  final String? webhookId;

  /// Creates a new [WebhookException] with the given [message].
  ///
  /// Optionally includes:
  /// - [code]: Error code for the webhook issue
  /// - [eventType]: The type of webhook event that caused the error
  /// - [webhookId]: The ID of the webhook event
  /// - [originalError]: The original error object
  /// - [stackTrace]: Stack trace for debugging
  WebhookException(
    super.message, {
    super.code,
    this.eventType,
    this.webhookId,
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() {
    final eventStr = eventType != null ? ' (event: $eventType)' : '';
    final idStr = webhookId != null ? ' (id: $webhookId)' : '';
    final codeStr = code != null ? ' (code: $code)' : '';
    return 'WebhookException: $message$eventStr$idStr$codeStr';
  }
}
