import 'package:flutter/material.dart';
import '../models/enums.dart';

/// Data class representing a subscription plan for display
class SubscriptionPlanData {
  /// Creates a [SubscriptionPlanData].
  const SubscriptionPlanData({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.interval,
    this.intervalCount = 1,
    this.description,
    this.features = const [],
    this.trialDays,
    this.isBestValue = false,
    this.isPopular = false,
    this.metadata,
  });

  /// Unique identifier for the plan
  final String id;

  /// Display name of the plan
  final String name;

  /// Price amount (e.g., 999 for $9.99)
  final int price;

  /// Currency code (e.g., 'USD')
  final String currency;

  /// Billing interval
  final BillingInterval interval;

  /// Number of intervals between billings
  final int intervalCount;

  /// Short description of the plan
  final String? description;

  /// List of feature descriptions
  final List<String> features;

  /// Number of trial days
  final int? trialDays;

  /// Whether this is marked as the best value
  final bool isBestValue;

  /// Whether this is a popular plan
  final bool isPopular;

  /// Additional metadata
  final Map<String, dynamic>? metadata;

  /// Get formatted price string
  String get formattedPrice {
    final amount = price / 100;
    return amount.toStringAsFixed(2);
  }

  /// Get billing interval display text
  String get intervalText {
    final intervalName = interval == BillingInterval.month
        ? 'month'
        : interval == BillingInterval.year
            ? 'year'
            : interval == BillingInterval.week
                ? 'week'
                : interval == BillingInterval.day
                    ? 'day'
                    : 'payment';

    if (intervalCount > 1) {
      return 'every $intervalCount ${intervalName}s';
    }
    return 'per $intervalName';
  }
}

/// A card widget for displaying subscription plan information
class SubscriptionCard extends StatelessWidget {
  /// Creates a [SubscriptionCard].
  const SubscriptionCard({
    super.key,
    required this.plan,
    this.isSelected = false,
    this.onTap,
    this.onSelectTap,
    this.showBadge = true,
    this.showFeatures = true,
    this.showTrialInfo = true,
    this.ctaText = 'Select Plan',
    this.selectedText = 'Current Plan',
    this.backgroundColor,
    this.selectedBackgroundColor,
    this.borderColor,
    this.selectedBorderColor,
    this.priceStyle,
    this.nameStyle,
    this.descriptionStyle,
    this.featureStyle,
    this.ctaButtonStyle,
    this.elevation = 2.0,
    this.borderRadius = 12.0,
    this.padding,
    this.spacing = 12.0,
    this.showCurrencySymbol = true,
  });

  /// Subscription plan data to display
  final SubscriptionPlanData plan;

  /// Whether this plan is currently selected
  final bool isSelected;

  /// Callback when card is tapped
  final VoidCallback? onTap;

  /// Callback when select/CTA button is tapped
  final VoidCallback? onSelectTap;

  /// Whether to show best value/popular badge
  final bool showBadge;

  /// Whether to show features list
  final bool showFeatures;

  /// Whether to show trial information
  final bool showTrialInfo;

  /// Text for call-to-action button
  final String ctaText;

  /// Text to show when plan is selected
  final String selectedText;

  /// Background color for the card
  final Color? backgroundColor;

  /// Background color when selected
  final Color? selectedBackgroundColor;

  /// Border color
  final Color? borderColor;

  /// Border color when selected
  final Color? selectedBorderColor;

  /// Style for price text
  final TextStyle? priceStyle;

  /// Style for plan name
  final TextStyle? nameStyle;

  /// Style for description
  final TextStyle? descriptionStyle;

  /// Style for feature items
  final TextStyle? featureStyle;

  /// Style for CTA button
  final ButtonStyle? ctaButtonStyle;

  /// Card elevation
  final double elevation;

  /// Border radius for the card
  final double borderRadius;

  /// Padding inside the card
  final EdgeInsetsGeometry? padding;

  /// Spacing between elements
  final double spacing;

  /// Whether to show currency symbol
  final bool showCurrencySymbol;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveBackgroundColor = isSelected
        ? (selectedBackgroundColor ??
            colorScheme.primaryContainer.withOpacity(0.1))
        : (backgroundColor ?? colorScheme.surface);

    final effectiveBorderColor = isSelected
        ? (selectedBorderColor ?? colorScheme.primary)
        : (borderColor ?? colorScheme.outline.withOpacity(0.2));

    final effectivePadding =
        padding ?? EdgeInsets.all(spacing * 1.5);

    return Semantics(
      label: 'Subscription plan: ${plan.name}',
      button: true,
      selected: isSelected,
      child: Card(
        elevation: elevation,
        color: effectiveBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(
            color: effectiveBorderColor,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: effectivePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge (Best Value / Popular)
                if (showBadge && (plan.isBestValue || plan.isPopular))
                  _buildBadge(context),

                if (showBadge && (plan.isBestValue || plan.isPopular))
                  SizedBox(height: spacing),

                // Plan Name
                Text(
                  plan.name,
                  style: nameStyle ??
                      theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),

                if (plan.description != null) SizedBox(height: spacing / 2),

                // Description
                if (plan.description != null)
                  Text(
                    plan.description!,
                    style: descriptionStyle ??
                        theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                    textAlign: TextAlign.center,
                  ),

                SizedBox(height: spacing),

                // Price
                _buildPrice(context),

                // Trial Info
                if (showTrialInfo && plan.trialDays != null) ...[
                  SizedBox(height: spacing / 2),
                  _buildTrialInfo(context),
                ],

                // Features
                if (showFeatures && plan.features.isNotEmpty) ...[
                  SizedBox(height: spacing * 1.5),
                  _buildFeatures(context),
                ],

                SizedBox(height: spacing * 1.5),

                // CTA Button
                _buildCtaButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final badgeText = plan.isBestValue ? 'BEST VALUE' : 'POPULAR';
    final badgeColor =
        plan.isBestValue ? colorScheme.primary : colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        badgeText,
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPrice(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final currencySymbol = _getCurrencySymbol(plan.currency);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showCurrencySymbol)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              currencySymbol,
              style: priceStyle ??
                  theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
            ),
          ),
        Text(
          plan.formattedPrice,
          style: priceStyle ??
              theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 4),
          child: Text(
            plan.intervalText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrialInfo(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${plan.trialDays}-day free trial',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFeatures(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: plan.features.map((feature) {
        return Padding(
          padding: EdgeInsets.only(bottom: spacing / 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.check_circle,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  feature,
                  style: featureStyle ?? theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCtaButton(BuildContext context) {
    final theme = Theme.of(context);

    if (isSelected) {
      return OutlinedButton(
        onPressed: null,
        style: ctaButtonStyle,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(selectedText),
          ],
        ),
      );
    }

    return FilledButton(
      onPressed: onSelectTap,
      style: ctaButtonStyle,
      child: Text(ctaText),
    );
  }

  String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'INR':
        return '₹';
      case 'AUD':
      case 'CAD':
        return '\$';
      default:
        return currency.toUpperCase();
    }
  }
}

/// A compact version of subscription card for list views
class CompactSubscriptionCard extends StatelessWidget {
  /// Creates a [CompactSubscriptionCard].
  const CompactSubscriptionCard({
    super.key,
    required this.plan,
    this.isSelected = false,
    this.onTap,
    this.showBadge = true,
    this.backgroundColor,
    this.selectedBackgroundColor,
    this.borderRadius = 8.0,
  });

  /// Subscription plan data to display
  final SubscriptionPlanData plan;

  /// Whether this plan is currently selected
  final bool isSelected;

  /// Callback when card is tapped
  final VoidCallback? onTap;

  /// Whether to show best value/popular badge
  final bool showBadge;

  /// Background color for the card
  final Color? backgroundColor;

  /// Background color when selected
  final Color? selectedBackgroundColor;

  /// Border radius for the card
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveBackgroundColor = isSelected
        ? (selectedBackgroundColor ?? colorScheme.primaryContainer)
        : (backgroundColor ?? colorScheme.surface);

    return Semantics(
      label: 'Subscription plan: ${plan.name}',
      button: true,
      selected: isSelected,
      child: Card(
        color: effectiveBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Radio indicator
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 12),

                // Plan info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            plan.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (showBadge && plan.isBestValue) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'BEST',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (plan.trialDays != null)
                        Text(
                          '${plan.trialDays}-day free trial',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.secondary,
                          ),
                        ),
                    ],
                  ),
                ),

                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${plan.formattedPrice}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    Text(
                      plan.intervalText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
