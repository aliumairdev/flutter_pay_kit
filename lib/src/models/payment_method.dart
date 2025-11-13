import 'package:freezed_annotation/freezed_annotation.dart';

import 'billing_details.dart';
import 'enums.dart';

part 'payment_method.freezed.dart';
part 'payment_method.g.dart';

/// Payment method model representing a customer's payment instrument.
@freezed
class PaymentMethod with _$PaymentMethod {
  /// Creates a [PaymentMethod].
  const factory PaymentMethod({
    /// Unique identifier for the payment method
    required String id,

    /// ID of the customer who owns this payment method
    @JsonKey(name: 'customer_id') required String customerId,

    /// Type of payment method
    required PaymentMethodType type,

    /// Last 4 digits of the card or account number
    String? last4,

    /// Card brand (e.g., 'visa', 'mastercard', 'amex')
    String? brand,

    /// Card expiry month (1-12)
    @JsonKey(name: 'expiry_month') int? expiryMonth,

    /// Card expiry year (e.g., 2025)
    @JsonKey(name: 'expiry_year') int? expiryYear,

    /// Whether this is the default payment method for the customer
    @JsonKey(name: 'is_default') required bool isDefault,

    /// Billing details associated with this payment method
    @JsonKey(name: 'billing_details') BillingDetails? billingDetails,

    /// Additional metadata for the payment method
    Map<String, dynamic>? metadata,
  }) = _PaymentMethod;

  /// Creates a [PaymentMethod] from JSON.
  factory PaymentMethod.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodFromJson(json);
}
