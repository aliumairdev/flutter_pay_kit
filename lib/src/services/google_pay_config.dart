import 'google_pay_handler.dart';

/// Configuration for Google Pay integration.
///
/// This class holds the configuration needed to use Google Pay with your
/// Flutter application.
///
/// Example:
/// ```dart
/// final googlePayConfig = GooglePayConfig(
///   merchantId: '01234567890123456789',
///   merchantName: 'My Store',
///   environment: GooglePayEnvironment.test,
///   countryCode: 'US',
///   currencyCode: 'USD',
/// );
///
/// // Check availability
/// final isAvailable = await googlePayConfig.isAvailable();
///
/// // Request payment
/// final token = await googlePayConfig.requestPayment(amount: 2500);
/// ```
class GooglePayConfig {
  /// Your Google Pay merchant ID.
  ///
  /// You can obtain this from the Google Pay Business Console.
  final String merchantId;

  /// Your merchant name as it will appear to users.
  final String merchantName;

  /// The Google Pay environment to use.
  ///
  /// Use [GooglePayEnvironment.test] for development and testing.
  /// Use [GooglePayEnvironment.production] for live transactions.
  final GooglePayEnvironment environment;

  /// Two-letter ISO 3166-1 alpha-2 country code.
  ///
  /// Defaults to 'US'.
  final String countryCode;

  /// Three-letter ISO 4217 currency code.
  ///
  /// Defaults to 'USD'.
  final String currencyCode;

  /// Allowed card authentication methods.
  ///
  /// Defaults to both PAN_ONLY and CRYPTOGRAM_3DS.
  final List<CardAuthMethod> allowedAuthMethods;

  /// Allowed card networks.
  ///
  /// Defaults to all major networks (Visa, Mastercard, Amex, Discover).
  final List<CardNetwork> allowedCardNetworks;

  /// Creates a new [GooglePayConfig] instance.
  ///
  /// Parameters:
  /// - [merchantId]: Your Google Pay merchant ID (required)
  /// - [merchantName]: Your merchant name (required)
  /// - [environment]: Google Pay environment (defaults to test)
  /// - [countryCode]: Two-letter country code (defaults to 'US')
  /// - [currencyCode]: Three-letter currency code (defaults to 'USD')
  /// - [allowedAuthMethods]: Allowed authentication methods
  /// - [allowedCardNetworks]: Allowed card networks
  const GooglePayConfig({
    required this.merchantId,
    required this.merchantName,
    this.environment = GooglePayEnvironment.test,
    this.countryCode = 'US',
    this.currencyCode = 'USD',
    this.allowedAuthMethods = const [
      CardAuthMethod.panOnly,
      CardAuthMethod.cryptogram3ds,
    ],
    this.allowedCardNetworks = const [
      CardNetwork.visa,
      CardNetwork.mastercard,
      CardNetwork.amex,
      CardNetwork.discover,
    ],
  });

  /// Checks if Google Pay is available on the current device.
  ///
  /// Returns `true` if Google Pay is available and ready to use,
  /// `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// final config = GooglePayConfig(
  ///   merchantId: 'your-merchant-id',
  ///   merchantName: 'Your Store',
  /// );
  ///
  /// if (await config.isAvailable()) {
  ///   // Show Google Pay button
  /// }
  /// ```
  Future<bool> isAvailable() async {
    return GooglePayHandler.isAvailable();
  }

  /// Requests a payment using this configuration.
  ///
  /// Parameters:
  /// - [amount]: Payment amount in smallest currency unit (e.g., cents)
  ///
  /// Returns the payment token as a String if successful, null if cancelled.
  ///
  /// Throws [PaymentException] if the payment request fails.
  ///
  /// Example:
  /// ```dart
  /// final config = GooglePayConfig(
  ///   merchantId: 'your-merchant-id',
  ///   merchantName: 'Your Store',
  ///   environment: GooglePayEnvironment.production,
  /// );
  ///
  /// final token = await config.requestPayment(amount: 1999); // $19.99
  /// if (token != null) {
  ///   // Process payment with token
  /// }
  /// ```
  Future<String?> requestPayment({required int amount}) async {
    return GooglePayHandler.requestPayment(
      amount: amount,
      currency: currencyCode,
      merchantId: merchantId,
      countryCode: countryCode,
      environment: environment,
    );
  }

  /// Creates a copy of this configuration with the given fields replaced.
  GooglePayConfig copyWith({
    String? merchantId,
    String? merchantName,
    GooglePayEnvironment? environment,
    String? countryCode,
    String? currencyCode,
    List<CardAuthMethod>? allowedAuthMethods,
    List<CardNetwork>? allowedCardNetworks,
  }) {
    return GooglePayConfig(
      merchantId: merchantId ?? this.merchantId,
      merchantName: merchantName ?? this.merchantName,
      environment: environment ?? this.environment,
      countryCode: countryCode ?? this.countryCode,
      currencyCode: currencyCode ?? this.currencyCode,
      allowedAuthMethods: allowedAuthMethods ?? this.allowedAuthMethods,
      allowedCardNetworks: allowedCardNetworks ?? this.allowedCardNetworks,
    );
  }
}

/// Card authentication methods supported by Google Pay.
enum CardAuthMethod {
  /// PAN (Primary Account Number) only.
  ///
  /// The card details are returned without cryptographic authentication.
  panOnly('PAN_ONLY'),

  /// 3-D Secure cryptogram.
  ///
  /// The payment is authenticated using 3-D Secure.
  cryptogram3ds('CRYPTOGRAM_3DS');

  const CardAuthMethod(this.value);

  /// The string value used in the Google Pay API
  final String value;
}

/// Card networks supported by Google Pay.
enum CardNetwork {
  /// American Express
  amex('AMEX'),

  /// Discover
  discover('DISCOVER'),

  /// Interac (Canada)
  interac('INTERAC'),

  /// JCB
  jcb('JCB'),

  /// Mastercard
  mastercard('MASTERCARD'),

  /// Visa
  visa('VISA');

  const CardNetwork(this.value);

  /// The string value used in the Google Pay API
  final String value;
}
