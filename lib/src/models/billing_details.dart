import 'package:freezed_annotation/freezed_annotation.dart';

import 'address.dart';

part 'billing_details.freezed.dart';
part 'billing_details.g.dart';

/// Billing details for a payment method or transaction.
@freezed
class BillingDetails with _$BillingDetails {
  /// Creates [BillingDetails].
  const factory BillingDetails({
    /// Customer's full name
    String? name,

    /// Customer's email address
    String? email,

    /// Customer's phone number
    String? phone,

    /// Customer's billing address
    Address? address,
  }) = _BillingDetails;

  /// Creates [BillingDetails] from JSON.
  factory BillingDetails.fromJson(Map<String, dynamic> json) =>
      _$BillingDetailsFromJson(json);
}
