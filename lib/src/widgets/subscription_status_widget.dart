import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/subscription.dart';
import '../models/payment_method.dart';
import '../models/enums.dart';

/// A comprehensive widget for displaying subscription status and management
class SubscriptionStatusWidget extends StatelessWidget {
  /// Creates a [SubscriptionStatusWidget].
  const SubscriptionStatusWidget({
    super.key,
    required this.subscription,
    this.planName,
    this.paymentMethod,
    this.onCancel,
    this.onChangePlan,
    this.onUpdatePayment,
    this.onViewBillingHistory,
    this.onResume,
    this.showPaymentMethod = true,
    this.showActions = true,
    this.showBillingHistory = true,
    this.backgroundColor,
    this.borderRadius = 12.0,
    this.padding,
    this.spacing = 16.0,
  });

  /// Subscription to display
  final Subscription subscription;

  /// Display name of the subscription plan
  final String? planName;

  /// Payment method for the subscription
  final PaymentMethod? paymentMethod;

  /// Callback when cancel button is tapped
  final VoidCallback? onCancel;

  /// Callback when change plan button is tapped
  final VoidCallback? onChangePlan;

  /// Callback when update payment method is tapped
  final VoidCallback? onUpdatePayment;

  /// Callback when view billing history is tapped
  final VoidCallback? onViewBillingHistory;

  /// Callback when resume subscription is tapped
  final VoidCallback? onResume;

  /// Whether to show payment method section
  final bool showPaymentMethod;

  /// Whether to show action buttons
  final bool showActions;

  /// Whether to show billing history link
  final bool showBillingHistory;

  /// Background color
  final Color? backgroundColor;

  /// Border radius
  final double borderRadius;

  /// Padding
  final EdgeInsetsGeometry? padding;

  /// Spacing between elements
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: backgroundColor ?? colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Header
            _buildStatusHeader(context),

            SizedBox(height: spacing),
            const Divider(),
            SizedBox(height: spacing),

            // Plan Information
            _buildPlanInfo(context),

            SizedBox(height: spacing),

            // Next Billing Date
            _buildBillingInfo(context),

            // Payment Method
            if (showPaymentMethod && paymentMethod != null) ...[
              SizedBox(height: spacing),
              _buildPaymentMethodSection(context),
            ],

            // Trial/Grace Period Info
            if (subscription.isOnTrial || subscription.isOnGracePeriod) ...[
              SizedBox(height: spacing),
              _buildNoticeSection(context),
            ],

            // Actions
            if (showActions) ...[
              SizedBox(height: spacing * 1.5),
              _buildActions(context),
            ],

            // Billing History Link
            if (showBillingHistory) ...[
              SizedBox(height: spacing),
              _buildBillingHistoryLink(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final statusInfo = _getStatusInfo(colorScheme);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusInfo.color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            statusInfo.icon,
            color: statusInfo.color,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                statusInfo.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (statusInfo.subtitle != null)
                Text(
                  statusInfo.subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusInfo.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusInfo.color.withOpacity(0.3)),
          ),
          child: Text(
            statusInfo.badge,
            style: theme.textTheme.labelMedium?.copyWith(
              color: statusInfo.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanInfo(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Plan',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              planName ?? 'Subscription',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (onChangePlan != null)
          TextButton(
            onPressed: onChangePlan,
            child: const Text('Change Plan'),
          ),
      ],
    );
  }

  Widget _buildBillingInfo(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');

    String label;
    DateTime date;

    if (subscription.cancelAtPeriodEnd) {
      label = 'Subscription Ends';
      date = subscription.currentPeriodEnd;
    } else {
      label = 'Next Billing Date';
      date = subscription.currentPeriodEnd;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateFormat.format(date),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection(BuildContext context) {
    final theme = Theme.of(context);

    final brand = paymentMethod!.brand ?? 'Card';
    final last4 = paymentMethod!.last4 ?? '****';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Method',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.credit_card,
                  size: 20,
                  color: theme.iconTheme.color,
                ),
                const SizedBox(width: 8),
                Text(
                  '$brand •••• $last4',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (onUpdatePayment != null)
          TextButton(
            onPressed: onUpdatePayment,
            child: const Text('Update'),
          ),
      ],
    );
  }

  Widget _buildNoticeSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String message;
    Color backgroundColor;
    Color textColor;
    IconData icon;

    if (subscription.isOnTrial) {
      final daysRemaining =
          subscription.trialEnd!.difference(DateTime.now()).inDays;
      message = daysRemaining > 0
          ? 'Your free trial ends in $daysRemaining ${daysRemaining == 1 ? 'day' : 'days'}'
          : 'Your free trial ends today';
      backgroundColor = colorScheme.secondaryContainer.withOpacity(0.5);
      textColor = colorScheme.onSecondaryContainer;
      icon = Icons.card_giftcard;
    } else {
      // Grace period
      final daysRemaining =
          subscription.currentPeriodEnd.difference(DateTime.now()).inDays;
      message = daysRemaining > 0
          ? 'Subscription will be canceled in $daysRemaining ${daysRemaining == 1 ? 'day' : 'days'}'
          : 'Subscription ends today';
      backgroundColor = Colors.orange.withOpacity(0.1);
      textColor = Colors.orange.shade900;
      icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final buttons = <Widget>[];

    if (subscription.cancelAtPeriodEnd && onResume != null) {
      buttons.add(
        FilledButton.icon(
          onPressed: onResume,
          icon: const Icon(Icons.refresh),
          label: const Text('Resume Subscription'),
        ),
      );
    } else if (!subscription.isCanceled && onCancel != null) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: onCancel,
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Cancel Subscription'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
        ),
      );
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: buttons,
    );
  }

  Widget _buildBillingHistoryLink(BuildContext context) {
    final theme = Theme.of(context);

    return TextButton.icon(
      onPressed: onViewBillingHistory,
      icon: const Icon(Icons.history),
      label: const Text('View Billing History'),
      style: TextButton.styleFrom(
        alignment: Alignment.centerLeft,
      ),
    );
  }

  _StatusInfo _getStatusInfo(ColorScheme colorScheme) {
    switch (subscription.status) {
      case SubscriptionStatus.active:
        if (subscription.cancelAtPeriodEnd) {
          return _StatusInfo(
            title: 'Subscription Ending',
            subtitle: 'Active until ${DateFormat('MMM dd').format(subscription.currentPeriodEnd)}',
            badge: 'ENDING',
            color: Colors.orange,
            icon: Icons.warning_amber_rounded,
          );
        }
        return _StatusInfo(
          title: 'Active Subscription',
          subtitle: 'Your subscription is active',
          badge: 'ACTIVE',
          color: Colors.green,
          icon: Icons.check_circle,
        );

      case SubscriptionStatus.trialing:
        return _StatusInfo(
          title: 'Free Trial',
          subtitle: 'Enjoying your trial period',
          badge: 'TRIAL',
          color: colorScheme.secondary,
          icon: Icons.card_giftcard,
        );

      case SubscriptionStatus.pastDue:
        return _StatusInfo(
          title: 'Payment Past Due',
          subtitle: 'Please update your payment method',
          badge: 'PAST DUE',
          color: Colors.orange,
          icon: Icons.error_outline,
        );

      case SubscriptionStatus.canceled:
        return _StatusInfo(
          title: 'Subscription Canceled',
          subtitle: 'Your subscription has ended',
          badge: 'CANCELED',
          color: colorScheme.error,
          icon: Icons.cancel,
        );

      case SubscriptionStatus.incomplete:
        return _StatusInfo(
          title: 'Incomplete Subscription',
          subtitle: 'Payment verification required',
          badge: 'INCOMPLETE',
          color: Colors.orange,
          icon: Icons.warning_amber_rounded,
        );

      case SubscriptionStatus.paused:
        return _StatusInfo(
          title: 'Subscription Paused',
          subtitle: 'Your subscription is temporarily paused',
          badge: 'PAUSED',
          color: Colors.grey,
          icon: Icons.pause_circle_outline,
        );
    }
  }
}

class _StatusInfo {
  const _StatusInfo({
    required this.title,
    this.subtitle,
    required this.badge,
    required this.color,
    required this.icon,
  });

  final String title;
  final String? subtitle;
  final String badge;
  final Color color;
  final IconData icon;
}

/// A compact subscription status indicator
class CompactSubscriptionStatus extends StatelessWidget {
  /// Creates a [CompactSubscriptionStatus].
  const CompactSubscriptionStatus({
    super.key,
    required this.subscription,
    this.planName,
    this.onTap,
    this.showNextBilling = true,
  });

  /// Subscription to display
  final Subscription subscription;

  /// Display name of the plan
  final String? planName;

  /// Callback when tapped
  final VoidCallback? onTap;

  /// Whether to show next billing date
  final bool showNextBilling;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final statusColor = subscription.isActive
        ? Colors.green
        : subscription.status == SubscriptionStatus.trialing
            ? colorScheme.secondary
            : subscription.status == SubscriptionStatus.pastDue
                ? Colors.orange
                : colorScheme.error;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planName ?? 'Subscription',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (showNextBilling)
                      Text(
                        'Next billing: ${DateFormat('MMM dd, yyyy').format(subscription.currentPeriodEnd)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.iconTheme.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
