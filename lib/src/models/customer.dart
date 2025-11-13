import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'customer.freezed.dart';
part 'customer.g.dart';

/// Customer/User model representing a payment customer.
@freezed
class Customer with _$Customer {
  /// Creates a [Customer].
  const factory Customer({
    /// Unique identifier for the customer
    required String id,

    /// Customer's email address
    required String email,

    /// Customer's full name
    String? name,

    /// Customer's phone number
    String? phone,

    /// Payment processor handling this customer
    required ProcessorType processor,

    /// Customer ID in the payment processor's system
    @JsonKey(name: 'processor_customer_id') required String processorCustomerId,

    /// Additional metadata for the customer
    Map<String, dynamic>? metadata,

    /// Timestamp when the customer was created
    @JsonKey(name: 'created_at') required DateTime createdAt,

    /// Timestamp when the customer was last updated
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _Customer;

  /// Creates a [Customer] from JSON.
  factory Customer.fromJson(Map<String, dynamic> json) =>
      _$CustomerFromJson(json);
}
