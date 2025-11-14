import 'dart:async';
import 'package:flutter/services.dart';

/// Handler for Apple Pay integration on iOS
///
/// This class provides a bridge between Flutter and iOS PassKit framework
/// to enable Apple Pay functionality. It must be used on iOS devices only.
///
/// Example usage:
/// ```dart
/// final isAvailable = await ApplePayHandler.isAvailable();
/// if (isAvailable) {
///   final result = await ApplePayHandler.requestPayment(
///     amount: 1000, // Amount in cents
///     currency: 'USD',
///     merchantId: 'merchant.com.example.app',
///     countryCode: 'US',
///     label: 'Product Purchase',
///   );
/// }
/// ```
class ApplePayHandler {
  static const MethodChannel _channel =
      MethodChannel('flutter_universal_payments/apple_pay');

  /// Check if Apple Pay is available on the device
  ///
  /// Returns `true` if the device supports Apple Pay, `false` otherwise.
  /// Note: This only checks if the device supports Apple Pay, not if cards are set up.
  static Future<bool> isAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } on PlatformException catch (e) {
      throw ApplePayException(
        'Failed to check Apple Pay availability: ${e.message}',
        code: e.code,
      );
    }
  }

  /// Check if Apple Pay can make payments with specific card networks
  ///
  /// [networks] List of supported card networks (e.g., ['visa', 'mastercard', 'amex'])
  ///
  /// Returns `true` if the user has cards set up that match the specified networks.
  static Future<bool> canMakePayments({
    List<String> networks = const ['visa', 'mastercard', 'amex'],
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('canMakePayments', {
        'networks': networks,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      throw ApplePayException(
        'Failed to check if can make payments: ${e.message}',
        code: e.code,
      );
    }
  }

  /// Request an Apple Pay payment
  ///
  /// Required parameters:
  /// - [amount]: Amount to charge in smallest currency unit (e.g., cents for USD)
  /// - [currency]: ISO 4217 currency code (e.g., 'USD', 'EUR')
  /// - [merchantId]: Apple Pay merchant identifier (e.g., 'merchant.com.example.app')
  /// - [countryCode]: ISO 3166-1 alpha-2 country code (e.g., 'US', 'GB')
  ///
  /// Optional parameters:
  /// - [label]: Description shown to the user (default: 'Payment')
  /// - [networks]: Supported card networks (default: ['visa', 'mastercard', 'amex'])
  /// - [merchantCapabilities]: Supported capabilities (default: ['3DS'])
  /// - [shippingType]: Type of shipping ('shipping', 'delivery', 'storePickup', 'servicePickup')
  /// - [billingRequired]: Whether billing address is required (default: false)
  /// - [shippingRequired]: Whether shipping address is required (default: false)
  /// - [shippingMethods]: Available shipping methods
  ///
  /// Returns a [Map] containing the payment token and transaction details.
  ///
  /// Throws [ApplePayException] if the payment fails or is cancelled.
  static Future<Map<String, dynamic>> requestPayment({
    required int amount,
    required String currency,
    required String merchantId,
    required String countryCode,
    String? label,
    List<String>? networks,
    List<String>? merchantCapabilities,
    String? shippingType,
    bool? billingRequired,
    bool? shippingRequired,
    List<Map<String, String>>? shippingMethods,
  }) async {
    try {
      final arguments = <String, dynamic>{
        'amount': amount,
        'currency': currency,
        'merchantId': merchantId,
        'countryCode': countryCode,
      };

      if (label != null) arguments['label'] = label;
      if (networks != null) arguments['networks'] = networks;
      if (merchantCapabilities != null) {
        arguments['merchantCapabilities'] = merchantCapabilities;
      }
      if (shippingType != null) arguments['shippingType'] = shippingType;
      if (billingRequired != null) {
        arguments['billingRequired'] = billingRequired;
      }
      if (shippingRequired != null) {
        arguments['shippingRequired'] = shippingRequired;
      }
      if (shippingMethods != null) {
        arguments['shippingMethods'] = shippingMethods;
      }

      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'requestPayment',
        arguments,
      );

      if (result == null) {
        throw ApplePayException(
          'Payment was cancelled or failed',
          code: 'PAYMENT_CANCELLED',
        );
      }

      return _castMap(result);
    } on PlatformException catch (e) {
      throw ApplePayException(
        'Apple Pay request failed: ${e.message}',
        code: e.code,
        details: e.details,
      );
    }
  }

  /// Helper method to safely cast Map<Object?, Object?> to Map<String, dynamic>
  static Map<String, dynamic> _castMap(Map<Object?, Object?> map) {
    return map.map((key, value) {
      if (value is Map) {
        return MapEntry(key.toString(), _castMap(value.cast<Object?, Object?>()));
      } else if (value is List) {
        return MapEntry(key.toString(), value);
      }
      return MapEntry(key.toString(), value);
    });
  }
}

/// Configuration for Apple Pay
///
/// Contains all necessary configuration for Apple Pay integration.
class ApplePayConfig {
  /// Apple Pay merchant identifier
  final String merchantId;

  /// ISO 4217 currency code
  final String currency;

  /// ISO 3166-1 alpha-2 country code
  final String countryCode;

  /// Supported card networks
  final List<String> supportedNetworks;

  /// Merchant capabilities
  final List<String> merchantCapabilities;

  const ApplePayConfig({
    required this.merchantId,
    required this.currency,
    required this.countryCode,
    this.supportedNetworks = const ['visa', 'mastercard', 'amex'],
    this.merchantCapabilities = const ['3DS'],
  });

  Map<String, dynamic> toMap() {
    return {
      'merchantId': merchantId,
      'currency': currency,
      'countryCode': countryCode,
      'networks': supportedNetworks,
      'merchantCapabilities': merchantCapabilities,
    };
  }
}

/// Payment result from Apple Pay
///
/// Contains the payment token and transaction details returned by Apple Pay.
class ApplePayResult {
  /// Base64-encoded payment data (payment token)
  final String paymentData;

  /// Transaction identifier
  final String transactionIdentifier;

  /// Payment method details
  final ApplePaymentMethod? paymentMethod;

  /// Billing contact information
  final Map<String, dynamic>? billingContact;

  /// Shipping contact information
  final Map<String, dynamic>? shippingContact;

  /// Selected shipping method
  final Map<String, dynamic>? shippingMethod;

  const ApplePayResult({
    required this.paymentData,
    required this.transactionIdentifier,
    this.paymentMethod,
    this.billingContact,
    this.shippingContact,
    this.shippingMethod,
  });

  factory ApplePayResult.fromMap(Map<String, dynamic> map) {
    return ApplePayResult(
      paymentData: map['paymentData'] as String,
      transactionIdentifier: map['transactionIdentifier'] as String,
      paymentMethod: map['paymentMethod'] != null
          ? ApplePaymentMethod.fromMap(
              map['paymentMethod'] as Map<String, dynamic>)
          : null,
      billingContact: map['billingContact'] as Map<String, dynamic>?,
      shippingContact: map['shippingContact'] as Map<String, dynamic>?,
      shippingMethod: map['shippingMethod'] as Map<String, dynamic>?,
    );
  }
}

/// Apple Pay payment method details
class ApplePaymentMethod {
  /// Display name of the card (e.g., "Visa •••• 1234")
  final String? displayName;

  /// Card network (e.g., "Visa", "MasterCard")
  final String? network;

  /// Payment method type (0 = unknown, 1 = debit, 2 = credit, 3 = prepaid, 4 = store)
  final int? type;

  const ApplePaymentMethod({
    this.displayName,
    this.network,
    this.type,
  });

  factory ApplePaymentMethod.fromMap(Map<String, dynamic> map) {
    return ApplePaymentMethod(
      displayName: map['displayName'] as String?,
      network: map['network'] as String?,
      type: map['type'] as int?,
    );
  }

  String get typeString {
    switch (type) {
      case 1:
        return 'debit';
      case 2:
        return 'credit';
      case 3:
        return 'prepaid';
      case 4:
        return 'store';
      default:
        return 'unknown';
    }
  }
}

/// Exception thrown when Apple Pay operations fail
class ApplePayException implements Exception {
  /// Error message
  final String message;

  /// Error code
  final String? code;

  /// Additional error details
  final dynamic details;

  const ApplePayException(
    this.message, {
    this.code,
    this.details,
  });

  @override
  String toString() {
    if (code != null) {
      return 'ApplePayException($code): $message';
    }
    return 'ApplePayException: $message';
  }
}

/// Supported card networks for Apple Pay
class ApplePayNetwork {
  static const String visa = 'visa';
  static const String masterCard = 'masterCard';
  static const String amex = 'amex';
  static const String discover = 'discover';
  static const String chinaUnionPay = 'chinaUnionPay';
  static const String interac = 'interac';
  static const String privateLabel = 'privateLabel';
  static const String jcb = 'jcb';
  static const String maestro = 'maestro';
  static const String eftpos = 'eftpos';
  static const String electron = 'electron';
  static const String elo = 'elo';
  static const String mada = 'mada';
  static const String vpay = 'vpay';
  static const String barcode = 'barcode';
  static const String girocard = 'girocard';

  static const List<String> all = [
    visa,
    masterCard,
    amex,
    discover,
    chinaUnionPay,
    interac,
    privateLabel,
    jcb,
    maestro,
    eftpos,
    electron,
    elo,
    mada,
    vpay,
    barcode,
    girocard,
  ];
}

/// Merchant capabilities for Apple Pay
class ApplePayCapability {
  static const String threeDS = '3DS';
  static const String emv = 'EMV';
  static const String credit = 'credit';
  static const String debit = 'debit';

  static const List<String> all = [
    threeDS,
    emv,
    credit,
    debit,
  ];
}

/// Shipping types for Apple Pay
class ApplePayShippingType {
  static const String shipping = 'shipping';
  static const String delivery = 'delivery';
  static const String storePickup = 'storePickup';
  static const String servicePickup = 'servicePickup';

  static const List<String> all = [
    shipping,
    delivery,
    storePickup,
    servicePickup,
  ];
}
