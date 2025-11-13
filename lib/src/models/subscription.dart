import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'subscription.freezed.dart';
part 'subscription.g.dart';

/// Subscription model representing a recurring payment subscription.
@freezed
class Subscription with _$Subscription {
  const Subscription._();

  /// Creates a [Subscription].
  const factory Subscription({
    /// Unique identifier for the subscription
    required String id,

    /// ID of the customer who owns this subscription
    @JsonKey(name: 'customer_id') required String customerId,

    /// Current status of the subscription
    required SubscriptionStatus status,

    /// ID of the price/plan for this subscription
    @JsonKey(name: 'price_id') required String priceId,

    /// ID of the product for this subscription
    @JsonKey(name: 'product_id') required String productId,

    /// Start of the current billing period
    @JsonKey(name: 'current_period_start') required DateTime currentPeriodStart,

    /// End of the current billing period
    @JsonKey(name: 'current_period_end') required DateTime currentPeriodEnd,

    /// Start of the trial period
    @JsonKey(name: 'trial_start') DateTime? trialStart,

    /// End of the trial period
    @JsonKey(name: 'trial_end') DateTime? trialEnd,

    /// Timestamp when the subscription was canceled
    @JsonKey(name: 'canceled_at') DateTime? canceledAt,

    /// Whether the subscription will be canceled at the end of the current period
    @JsonKey(name: 'cancel_at_period_end') required bool cancelAtPeriodEnd,

    /// Quantity of the subscription (for per-seat pricing)
    required int quantity,

    /// Payment processor handling this subscription
    required ProcessorType processor,

    /// Subscription ID in the payment processor's system
    @JsonKey(name: 'processor_subscription_id')
    required String processorSubscriptionId,

    /// Additional metadata for the subscription
    Map<String, dynamic>? metadata,
  }) = _Subscription;

  /// Creates a [Subscription] from JSON.
  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);

  /// Whether the subscription is currently active
  bool get isActive => status == SubscriptionStatus.active;

  /// Whether the subscription is currently in a trial period
  bool get isOnTrial {
    if (status != SubscriptionStatus.trialing) return false;
    if (trialEnd == null) return false;
    return DateTime.now().isBefore(trialEnd!);
  }

  /// Whether the subscription has been canceled
  bool get isCanceled => status == SubscriptionStatus.canceled;

  /// Whether the subscription is in a grace period (canceled but still active until period end)
  bool get isOnGracePeriod {
    if (!cancelAtPeriodEnd) return false;
    if (canceledAt == null) return false;
    return DateTime.now().isBefore(currentPeriodEnd);
  }

  /// Days until the subscription is due (for past_due subscriptions)
  /// Returns null if not past due or if unable to calculate
  int? get daysUntilDue {
    if (status != SubscriptionStatus.pastDue) return null;
    final now = DateTime.now();
    final daysOverdue = now.difference(currentPeriodEnd).inDays;
    // Most processors give ~7-14 days grace period for past due subscriptions
    // Return negative number if already overdue, positive if still in grace period
    const gracePeriodDays = 7;
    return gracePeriodDays - daysOverdue;
  }
}
