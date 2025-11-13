import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'price.freezed.dart';
part 'price.g.dart';

/// Product price model representing a pricing plan.
@freezed
class Price with _$Price {
  /// Creates a [Price].
  const factory Price({
    /// Unique identifier for the price
    required String id,

    /// ID of the product this price is for
    @JsonKey(name: 'product_id') required String productId,

    /// Price amount in the smallest currency unit (e.g., cents)
    required int amount,

    /// Three-letter ISO currency code (e.g., 'usd', 'eur')
    required String currency,

    /// Billing interval for recurring prices
    required BillingInterval interval,

    /// Number of intervals between billings (e.g., 3 for every 3 months)
    @JsonKey(name: 'interval_count') required int intervalCount,

    /// Number of trial days before billing starts
    @JsonKey(name: 'trial_days') int? trialDays,

    /// Whether this price is currently active
    required bool active,

    /// Price ID in the payment processor's system
    @JsonKey(name: 'processor_price_id') required String processorPriceId,

    /// Payment processor handling this price
    required ProcessorType processor,

    /// Additional metadata for the price
    Map<String, dynamic>? metadata,
  }) = _Price;

  /// Creates a [Price] from JSON.
  factory Price.fromJson(Map<String, dynamic> json) => _$PriceFromJson(json);
}
