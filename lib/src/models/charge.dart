import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'charge.freezed.dart';
part 'charge.g.dart';

/// One-time charge/payment model.
@freezed
class Charge with _$Charge {
  /// Creates a [Charge].
  const factory Charge({
    /// Unique identifier for the charge
    required String id,

    /// ID of the customer who was charged
    @JsonKey(name: 'customer_id') required String customerId,

    /// Amount charged in the smallest currency unit (e.g., cents)
    required int amount,

    /// Three-letter ISO currency code (e.g., 'usd', 'eur')
    required String currency,

    /// Current status of the charge
    required ChargeStatus status,

    /// Description of what the charge was for
    String? description,

    /// URL to the receipt for this charge
    @JsonKey(name: 'receipt_url') String? receiptUrl,

    /// Whether the charge has been refunded
    required bool refunded,

    /// Amount that has been refunded (in smallest currency unit)
    @JsonKey(name: 'refunded_amount') int? refundedAmount,

    /// Charge ID in the payment processor's system
    @JsonKey(name: 'processor_charge_id') required String processorChargeId,

    /// Payment processor that processed this charge
    required ProcessorType processor,

    /// Timestamp when the charge was created
    @JsonKey(name: 'created_at') required DateTime createdAt,

    /// Additional metadata for the charge
    Map<String, dynamic>? metadata,
  }) = _Charge;

  /// Creates a [Charge] from JSON.
  factory Charge.fromJson(Map<String, dynamic> json) =>
      _$ChargeFromJson(json);
}
