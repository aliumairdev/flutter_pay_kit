import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'webhook_event.freezed.dart';
part 'webhook_event.g.dart';

/// Webhook event model for payment processor notifications.
@freezed
class WebhookEvent with _$WebhookEvent {
  /// Creates a [WebhookEvent].
  const factory WebhookEvent({
    /// Unique identifier for the webhook event
    required String id,

    /// Type of event (e.g., 'customer.created', 'subscription.updated')
    required String type,

    /// Payment processor that sent this webhook
    required ProcessorType processor,

    /// Event data payload from the processor
    required Map<String, dynamic> data,

    /// Timestamp when the event was created
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _WebhookEvent;

  /// Creates a [WebhookEvent] from JSON.
  factory WebhookEvent.fromJson(Map<String, dynamic> json) =>
      _$WebhookEventFromJson(json);
}
