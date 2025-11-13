import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/services.dart';

import '../exceptions/exceptions.dart';

/// Handler for Google Pay integration on Android.
///
/// This class provides a bridge to the native Android Google Pay implementation,
/// allowing Flutter apps to:
/// - Check Google Pay availability
/// - Request payments using Google Pay
/// - Handle payment tokens
///
/// Example usage:
/// ```dart
/// // Check if Google Pay is available
/// final isAvailable = await GooglePayHandler.isAvailable();
///
/// if (isAvailable) {
///   // Request a payment
///   final token = await GooglePayHandler.requestPayment(
///     amount: 2500, // $25.00
///     currency: 'USD',
///     merchantId: 'your-merchant-id',
///     countryCode: 'US',
///     environment: GooglePayEnvironment.test,
///   );
///
///   if (token != null) {
///     // Process the payment token with your payment processor
///     print('Payment token: $token');
///   }
/// }
/// ```
class GooglePayHandler {
  static const MethodChannel _channel =
      MethodChannel('flutter_universal_payments/google_pay');

  /// Checks if Google Pay is available on the current device.
  ///
  /// This method verifies:
  /// - Google Play Services is installed and up to date
  /// - User has a valid payment method configured in Google Pay
  /// - Device supports Google Pay
  ///
  /// Returns `true` if Google Pay is available and ready to use,
  /// `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// final canUseGooglePay = await GooglePayHandler.isAvailable();
  /// if (canUseGooglePay) {
  ///   // Show Google Pay button
  /// } else {
  ///   // Show alternative payment method
  /// }
  /// ```
  static Future<bool> isAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } on PlatformException catch (e) {
      developer.log(
        'Failed to check Google Pay availability',
        error: e,
        name: 'GooglePayHandler',
      );
      return false;
    } catch (e) {
      developer.log(
        'Unexpected error checking Google Pay availability',
        error: e,
        name: 'GooglePayHandler',
      );
      return false;
    }
  }

  /// Requests a payment from Google Pay.
  ///
  /// This method presents the Google Pay payment sheet to the user and
  /// returns a payment token that can be used with your payment processor.
  ///
  /// Parameters:
  /// - [amount]: Payment amount in smallest currency unit (e.g., cents for USD)
  /// - [currency]: Three-letter ISO 4217 currency code (e.g., 'USD', 'EUR')
  /// - [merchantId]: Your Google Pay merchant ID
  /// - [countryCode]: Two-letter ISO 3166-1 alpha-2 country code (defaults to 'US')
  /// - [environment]: Google Pay environment (defaults to [GooglePayEnvironment.test])
  ///
  /// Returns the payment token as a String if successful, null if cancelled.
  ///
  /// Throws:
  /// - [PaymentException] if the payment request fails
  /// - [ValidationException] if the parameters are invalid
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   final token = await GooglePayHandler.requestPayment(
  ///     amount: 1999, // $19.99
  ///     currency: 'USD',
  ///     merchantId: '01234567890123456789',
  ///     countryCode: 'US',
  ///     environment: GooglePayEnvironment.production,
  ///   );
  ///
  ///   if (token != null) {
  ///     // Send token to your server for processing
  ///     await processPayment(token);
  ///   } else {
  ///     // User cancelled
  ///     print('Payment cancelled by user');
  ///   }
  /// } on PaymentException catch (e) {
  ///   print('Payment failed: ${e.message}');
  /// }
  /// ```
  static Future<String?> requestPayment({
    required int amount,
    required String currency,
    required String merchantId,
    String? countryCode,
    GooglePayEnvironment environment = GooglePayEnvironment.test,
  }) async {
    // Validate parameters
    if (amount <= 0) {
      throw ValidationException('Amount must be greater than 0');
    }

    if (currency.isEmpty || currency.length != 3) {
      throw ValidationException(
        'Currency must be a valid 3-letter ISO 4217 code',
      );
    }

    if (merchantId.isEmpty) {
      throw ValidationException('Merchant ID is required');
    }

    try {
      final result = await _channel.invokeMethod<String>(
        'requestPayment',
        {
          'amount': amount,
          'currency': currency.toUpperCase(),
          'merchantId': merchantId,
          'countryCode': countryCode?.toUpperCase() ?? 'US',
          'environment': environment.value,
        },
      );

      developer.log(
        'Google Pay payment ${result != null ? "succeeded" : "cancelled"}',
        name: 'GooglePayHandler',
      );

      return result;
    } on PlatformException catch (e) {
      developer.log(
        'Google Pay payment failed',
        error: e,
        name: 'GooglePayHandler',
      );

      // Map platform exceptions to appropriate exception types
      switch (e.code) {
        case 'PAYMENT_CANCELLED':
          // User cancelled - return null instead of throwing
          return null;
        case 'NO_ACTIVITY':
          throw PaymentException(
            'Payment UI not available',
            code: 'no_activity',
            details: e.message,
          );
        case 'INITIALIZATION_ERROR':
          throw PaymentException(
            'Failed to initialize Google Pay',
            code: 'initialization_error',
            details: e.message,
          );
        case 'INVALID_ARGUMENTS':
          throw ValidationException(
            e.message ?? 'Invalid payment parameters',
          );
        default:
          throw PaymentException(
            e.message ?? 'Google Pay payment failed',
            code: e.code,
            details: e.details?.toString(),
          );
      }
    } catch (e) {
      developer.log(
        'Unexpected error during Google Pay payment',
        error: e,
        name: 'GooglePayHandler',
      );
      throw PaymentException(
        'Unexpected error: ${e.toString()}',
        code: 'unexpected_error',
      );
    }
  }
}

/// Google Pay environment configuration.
///
/// Use [test] for development and testing.
/// Use [production] for live transactions.
enum GooglePayEnvironment {
  /// Test environment for development and testing.
  ///
  /// - No real transactions are processed
  /// - Uses test payment methods
  /// - Safe for development
  test('TEST'),

  /// Production environment for live transactions.
  ///
  /// - Real transactions are processed
  /// - Requires valid merchant account
  /// - Use only in production builds
  production('PRODUCTION');

  const GooglePayEnvironment(this.value);

  /// The string value used in the platform channel
  final String value;
}
