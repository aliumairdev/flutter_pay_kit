import 'package:flutter/material.dart';
import '../models/payment_method.dart';
import '../models/enums.dart';

/// A tile widget for displaying saved payment methods
class PaymentMethodTile extends StatelessWidget {
  /// Creates a [PaymentMethodTile].
  const PaymentMethodTile({
    super.key,
    required this.paymentMethod,
    this.onTap,
    this.onEdit,
    this.onRemove,
    this.onSetDefault,
    this.isSelected = false,
    this.showDefaultBadge = true,
    this.showEditButton = true,
    this.showRemoveButton = true,
    this.showSetDefaultButton = true,
    this.backgroundColor,
    this.selectedBackgroundColor,
    this.borderColor,
    this.selectedBorderColor,
    this.borderRadius = 12.0,
    this.padding,
    this.contentPadding,
    this.showBrandIcon = true,
    this.showExpiry = true,
  });

  /// Payment method to display
  final PaymentMethod paymentMethod;

  /// Callback when tile is tapped
  final VoidCallback? onTap;

  /// Callback when edit button is tapped
  final VoidCallback? onEdit;

  /// Callback when remove button is tapped
  final VoidCallback? onRemove;

  /// Callback when set as default button is tapped
  final VoidCallback? onSetDefault;

  /// Whether this payment method is currently selected
  final bool isSelected;

  /// Whether to show default badge
  final bool showDefaultBadge;

  /// Whether to show edit button
  final bool showEditButton;

  /// Whether to show remove button
  final bool showRemoveButton;

  /// Whether to show set as default button
  final bool showSetDefaultButton;

  /// Background color
  final Color? backgroundColor;

  /// Background color when selected
  final Color? selectedBackgroundColor;

  /// Border color
  final Color? borderColor;

  /// Border color when selected
  final Color? selectedBorderColor;

  /// Border radius
  final double borderRadius;

  /// Outer padding
  final EdgeInsetsGeometry? padding;

  /// Content padding inside the card
  final EdgeInsetsGeometry? contentPadding;

  /// Whether to show card brand icon
  final bool showBrandIcon;

  /// Whether to show expiry date
  final bool showExpiry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveBackgroundColor = isSelected
        ? (selectedBackgroundColor ?? colorScheme.primaryContainer)
        : (backgroundColor ?? colorScheme.surface);

    final effectiveBorderColor = isSelected
        ? (selectedBorderColor ?? colorScheme.primary)
        : (borderColor ?? colorScheme.outline.withOpacity(0.2));

    final effectiveContentPadding =
        contentPadding ?? const EdgeInsets.all(16);

    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 4),
      child: Semantics(
        label: _getSemanticLabel(),
        button: true,
        selected: isSelected,
        child: Card(
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
              padding: effectiveContentPadding,
              child: Row(
                children: [
                  // Card Brand Icon
                  if (showBrandIcon) ...[
                    _buildBrandIcon(context),
                    const SizedBox(width: 16),
                  ],

                  // Card Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildCardInfo(context),
                            ),
                            if (showDefaultBadge && paymentMethod.isDefault)
                              _buildDefaultBadge(context),
                          ],
                        ),
                        if (showExpiry &&
                            paymentMethod.expiryMonth != null &&
                            paymentMethod.expiryYear != null)
                          _buildExpiryInfo(context),
                      ],
                    ),
                  ),

                  // Actions
                  if (showEditButton ||
                      showRemoveButton ||
                      showSetDefaultButton)
                    _buildActions(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandIcon(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    IconData iconData;
    Color? iconColor;

    switch (paymentMethod.type) {
      case PaymentMethodType.card:
        iconData = _getCardBrandIcon(paymentMethod.brand);
        iconColor = colorScheme.primary;
        break;
      case PaymentMethodType.bankAccount:
        iconData = Icons.account_balance;
        iconColor = colorScheme.secondary;
        break;
      case PaymentMethodType.paypal:
        iconData = Icons.payment;
        iconColor = const Color(0xFF0070BA); // PayPal blue
        break;
      case PaymentMethodType.applePay:
        iconData = Icons.apple;
        iconColor = Colors.black;
        break;
      case PaymentMethodType.googlePay:
        iconData = Icons.payment;
        iconColor = const Color(0xFF4285F4); // Google blue
        break;
    }

    return Container(
      width: 48,
      height: 32,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  IconData _getCardBrandIcon(String? brand) {
    if (brand == null) return Icons.credit_card;

    switch (brand.toLowerCase()) {
      case 'visa':
      case 'mastercard':
      case 'amex':
      case 'american express':
      case 'discover':
      case 'diners':
      case 'diners club':
      case 'jcb':
      case 'unionpay':
        return Icons.credit_card;
      default:
        return Icons.credit_card_outlined;
    }
  }

  Widget _buildCardInfo(BuildContext context) {
    final theme = Theme.of(context);

    String title;
    String subtitle;

    switch (paymentMethod.type) {
      case PaymentMethodType.card:
        final brand = paymentMethod.brand ?? 'Card';
        final last4 = paymentMethod.last4 ?? '****';
        title = '$brand •••• $last4';
        subtitle = _getPaymentMethodTypeLabel(paymentMethod.type);
        break;
      case PaymentMethodType.bankAccount:
        final last4 = paymentMethod.last4 ?? '****';
        title = 'Bank Account •••• $last4';
        subtitle = _getPaymentMethodTypeLabel(paymentMethod.type);
        break;
      case PaymentMethodType.paypal:
        title = 'PayPal';
        subtitle = paymentMethod.billingDetails?.email ?? 'PayPal Account';
        break;
      case PaymentMethodType.applePay:
        title = 'Apple Pay';
        subtitle = paymentMethod.last4 != null
            ? '•••• ${paymentMethod.last4}'
            : 'Apple Pay';
        break;
      case PaymentMethodType.googlePay:
        title = 'Google Pay';
        subtitle = paymentMethod.last4 != null
            ? '•••• ${paymentMethod.last4}'
            : 'Google Pay';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildExpiryInfo(BuildContext context) {
    final theme = Theme.of(context);
    final month = paymentMethod.expiryMonth!;
    final year = paymentMethod.expiryYear! % 100;
    final expiryText =
        'Expires ${month.toString().padLeft(2, '0')}/${year.toString().padLeft(2, '0')}';

    final isExpired = _isExpired();
    final isExpiringSoon = _isExpiringSoon();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          if (isExpired || isExpiringSoon)
            Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: isExpired ? theme.colorScheme.error : Colors.orange,
            ),
          if (isExpired || isExpiringSoon) const SizedBox(width: 4),
          Text(
            expiryText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isExpired
                  ? theme.colorScheme.error
                  : isExpiringSoon
                      ? Colors.orange
                      : theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  bool _isExpired() {
    if (paymentMethod.expiryMonth == null ||
        paymentMethod.expiryYear == null) {
      return false;
    }

    final now = DateTime.now();
    final expiry = DateTime(
      paymentMethod.expiryYear!,
      paymentMethod.expiryMonth! + 1,
      0,
    );

    return expiry.isBefore(now);
  }

  bool _isExpiringSoon() {
    if (paymentMethod.expiryMonth == null ||
        paymentMethod.expiryYear == null) {
      return false;
    }

    final now = DateTime.now();
    final expiry = DateTime(
      paymentMethod.expiryYear!,
      paymentMethod.expiryMonth! + 1,
      0,
    );

    final threeMonthsFromNow = DateTime(now.year, now.month + 3, now.day);

    return expiry.isAfter(now) && expiry.isBefore(threeMonthsFromNow);
  }

  Widget _buildDefaultBadge(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'DEFAULT',
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: theme.iconTheme.color,
      ),
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];

        if (showSetDefaultButton && !paymentMethod.isDefault) {
          items.add(
            const PopupMenuItem(
              value: 'set_default',
              child: Row(
                children: [
                  Icon(Icons.star_outline),
                  SizedBox(width: 12),
                  Text('Set as Default'),
                ],
              ),
            ),
          );
        }

        if (showEditButton) {
          items.add(
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined),
                  SizedBox(width: 12),
                  Text('Edit'),
                ],
              ),
            ),
          );
        }

        if (showRemoveButton) {
          if (items.isNotEmpty) {
            items.add(const PopupMenuDivider());
          }
          items.add(
            PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: theme.colorScheme.error),
                  const SizedBox(width: 12),
                  Text(
                    'Remove',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
              ),
            ),
          );
        }

        return items;
      },
      onSelected: (value) {
        switch (value) {
          case 'set_default':
            onSetDefault?.call();
            break;
          case 'edit':
            onEdit?.call();
            break;
          case 'remove':
            onRemove?.call();
            break;
        }
      },
    );
  }

  String _getPaymentMethodTypeLabel(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.card:
        return 'Credit/Debit Card';
      case PaymentMethodType.bankAccount:
        return 'Bank Account';
      case PaymentMethodType.paypal:
        return 'PayPal';
      case PaymentMethodType.applePay:
        return 'Apple Pay';
      case PaymentMethodType.googlePay:
        return 'Google Pay';
    }
  }

  String _getSemanticLabel() {
    final type = _getPaymentMethodTypeLabel(paymentMethod.type);
    final last4 = paymentMethod.last4 != null
        ? 'ending in ${paymentMethod.last4}'
        : '';
    final defaultText = paymentMethod.isDefault ? ', default payment method' : '';
    return '$type $last4$defaultText';
  }
}

/// A compact payment method tile for use in lists or selectors
class CompactPaymentMethodTile extends StatelessWidget {
  /// Creates a [CompactPaymentMethodTile].
  const CompactPaymentMethodTile({
    super.key,
    required this.paymentMethod,
    this.onTap,
    this.isSelected = false,
    this.showRadio = true,
    this.showDefaultBadge = true,
  });

  /// Payment method to display
  final PaymentMethod paymentMethod;

  /// Callback when tile is tapped
  final VoidCallback? onTap;

  /// Whether this payment method is currently selected
  final bool isSelected;

  /// Whether to show radio button
  final bool showRadio;

  /// Whether to show default badge
  final bool showDefaultBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final brand = paymentMethod.brand ?? 'Card';
    final last4 = paymentMethod.last4 ?? '****';

    return Semantics(
      label: '$brand ending in $last4',
      button: true,
      selected: isSelected,
      child: ListTile(
        onTap: onTap,
        leading: showRadio
            ? Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.5),
              )
            : Icon(
                Icons.credit_card,
                color: colorScheme.primary,
              ),
        title: Row(
          children: [
            Expanded(
              child: Text('$brand •••• $last4'),
            ),
            if (showDefaultBadge && paymentMethod.isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'DEFAULT',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ),
          ],
        ),
        subtitle: paymentMethod.expiryMonth != null &&
                paymentMethod.expiryYear != null
            ? Text(
                'Expires ${paymentMethod.expiryMonth!.toString().padLeft(2, '0')}/${(paymentMethod.expiryYear! % 100).toString().padLeft(2, '0')}',
              )
            : null,
        selected: isSelected,
      ),
    );
  }
}
