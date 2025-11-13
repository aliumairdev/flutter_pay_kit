import 'package:freezed_annotation/freezed_annotation.dart';

part 'address.freezed.dart';
part 'address.g.dart';

/// Address model for billing and shipping information.
@freezed
class Address with _$Address {
  /// Creates an [Address].
  const factory Address({
    /// First line of the address (street address)
    String? line1,

    /// Second line of the address (apartment, suite, etc.)
    String? line2,

    /// City name
    String? city,

    /// State or province
    String? state,

    /// Postal or ZIP code
    @JsonKey(name: 'postal_code') String? postalCode,

    /// Country code (e.g., 'US', 'GB')
    String? country,
  }) = _Address;

  /// Creates an [Address] from JSON.
  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);
}
