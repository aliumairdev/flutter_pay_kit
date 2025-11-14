# Google Pay Integration Guide

This guide explains how to integrate Google Pay into your Flutter app using the `flutter_universal_payments` package.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Android Setup](#android-setup)
- [Configuration](#configuration)
- [Usage](#usage)
- [Testing](#testing)
- [Production Checklist](#production-checklist)
- [Troubleshooting](#troubleshooting)

## Overview

The Google Pay integration allows you to accept payments from Android users using their Google Pay wallet. The integration handles:

- Google Pay availability checking
- Payment sheet presentation
- Payment token generation
- Error handling

## Prerequisites

Before integrating Google Pay, you need:

1. **Google Pay Business Console Account**
   - Sign up at [Google Pay Business Console](https://pay.google.com/business/console)
   - Complete merchant verification

2. **Payment Processor Integration**
   - Have an account with a supported payment processor (Stripe, Braintree, etc.)
   - Obtain your gateway merchant ID

3. **Android Development Environment**
   - Android SDK 21 or higher
   - Google Play Services installed on test devices

## Android Setup

The Android plugin is already configured in this package. The following components are included:

### 1. Dependencies (android/build.gradle)

```gradle
dependencies {
    implementation 'com.google.android.gms:play-services-wallet:19.2.1'
}
```

### 2. Permissions (android/src/main/AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<application>
    <meta-data
        android:name="com.google.android.gms.wallet.api.enabled"
        android:value="true" />
</application>
```

### 3. Plugin Registration

The plugin is automatically registered via the `FlutterUniversalPaymentsPlugin.kt` file.

## Configuration

### Basic Configuration

```dart
import 'package:flutter_universal_payments/flutter_universal_payments.dart';

final googlePayConfig = GooglePayConfig(
  merchantId: 'your-merchant-id',
  merchantName: 'Your Store Name',
  environment: GooglePayEnvironment.test, // Use .production for live
  countryCode: 'US',
  currencyCode: 'USD',
);
```

### Advanced Configuration

```dart
final googlePayConfig = GooglePayConfig(
  merchantId: 'BCR2DN4T2I4VJ4M7',
  merchantName: 'Example Store',
  environment: GooglePayEnvironment.production,
  countryCode: 'US',
  currencyCode: 'USD',
  allowedAuthMethods: [
    CardAuthMethod.panOnly,
    CardAuthMethod.cryptogram3ds,
  ],
  allowedCardNetworks: [
    CardNetwork.visa,
    CardNetwork.mastercard,
    CardNetwork.amex,
  ],
);
```

### Configuration Options

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `merchantId` | `String` | Yes | - | Your Google Pay merchant ID |
| `merchantName` | `String` | Yes | - | Your business name shown to users |
| `environment` | `GooglePayEnvironment` | No | `test` | Use `test` or `production` |
| `countryCode` | `String` | No | `'US'` | ISO 3166-1 alpha-2 country code |
| `currencyCode` | `String` | No | `'USD'` | ISO 4217 currency code |
| `allowedAuthMethods` | `List<CardAuthMethod>` | No | All methods | Card authentication methods |
| `allowedCardNetworks` | `List<CardNetwork>` | No | All networks | Supported card networks |

## Usage

### 1. Check Google Pay Availability

Always check if Google Pay is available before showing the payment button:

```dart
final isAvailable = await googlePayConfig.isAvailable();

if (isAvailable) {
  // Show Google Pay button
  _showGooglePayButton();
} else {
  // Show alternative payment method
  _showCardForm();
}
```

### 2. Request Payment

```dart
try {
  final token = await googlePayConfig.requestPayment(
    amount: 2500, // $25.00 in cents
  );

  if (token != null) {
    // Payment successful - process token on your server
    await _processPaymentToken(token);
  } else {
    // User cancelled the payment
    print('Payment cancelled');
  }
} on PaymentException catch (e) {
  // Handle payment errors
  print('Payment failed: ${e.message}');
}
```

### 3. Process Payment Token

Send the token to your backend server to complete the payment:

```dart
Future<void> _processPaymentToken(String token) async {
  try {
    // Send token to your server
    final response = await http.post(
      Uri.parse('https://your-api.com/payments/google-pay'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
        'amount': 2500,
        'currency': 'USD',
      }),
    );

    if (response.statusCode == 200) {
      // Payment processed successfully
      _showSuccessMessage();
    } else {
      // Payment failed
      _showErrorMessage();
    }
  } catch (e) {
    print('Error processing payment: $e');
  }
}
```

### Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_universal_payments/flutter_universal_payments.dart';

class GooglePayButton extends StatefulWidget {
  final int amountInCents;
  final VoidCallback onSuccess;
  final Function(String) onError;

  const GooglePayButton({
    Key? key,
    required this.amountInCents,
    required this.onSuccess,
    required this.onError,
  }) : super(key: key);

  @override
  State<GooglePayButton> createState() => _GooglePayButtonState();
}

class _GooglePayButtonState extends State<GooglePayButton> {
  late GooglePayConfig _config;
  bool _isAvailable = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _config = GooglePayConfig(
      merchantId: 'your-merchant-id',
      merchantName: 'Your Store',
      environment: GooglePayEnvironment.production,
    );
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final available = await _config.isAvailable();
    setState(() => _isAvailable = available);
  }

  Future<void> _handlePayment() async {
    setState(() => _isLoading = true);

    try {
      final token = await _config.requestPayment(
        amount: widget.amountInCents,
      );

      if (token != null) {
        // Process payment on your server
        await _processPayment(token);
        widget.onSuccess();
      }
    } on PaymentException catch (e) {
      widget.onError(e.message);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processPayment(String token) async {
    // Send to your backend
    // Implementation depends on your backend
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAvailable) {
      return const SizedBox.shrink();
    }

    return ElevatedButton(
      onPressed: _isLoading ? null : _handlePayment,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(16),
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text('Pay with Google Pay'),
    );
  }
}
```

## Testing

### Test Environment

During development, use `GooglePayEnvironment.test`:

```dart
final config = GooglePayConfig(
  merchantId: 'BCR2DN4T2I4VJ4M7', // Example test merchant ID
  merchantName: 'Test Store',
  environment: GooglePayEnvironment.test,
);
```

### Test Cards

In the test environment, you can use test cards configured in your Google Pay account:

1. Open Google Pay app on your test device
2. Add a test card (e.g., 4111 1111 1111 1111 for Visa)
3. Use this card for testing payments

### Testing Checklist

- [ ] Google Pay availability detection works
- [ ] Payment sheet displays correctly
- [ ] Payment succeeds with valid card
- [ ] Payment cancellation is handled
- [ ] Error states are handled gracefully
- [ ] Token is correctly sent to backend
- [ ] Backend processes token successfully

## Production Checklist

Before going live, ensure you have:

### Google Pay Setup
- [ ] Merchant account verified in Google Pay Business Console
- [ ] Production merchant ID obtained
- [ ] Terms of service accepted
- [ ] Privacy policy configured

### Code Configuration
- [ ] Changed environment to `GooglePayEnvironment.production`
- [ ] Updated merchant ID to production value
- [ ] Merchant name accurately represents your business
- [ ] Correct country and currency codes set

### Testing
- [ ] Tested on multiple Android devices
- [ ] Tested with different card types
- [ ] Tested error scenarios (network issues, cancelled payments)
- [ ] Verified payment tokens work with your backend
- [ ] Load tested your backend payment processing

### Compliance
- [ ] Google Pay branding guidelines followed
- [ ] User privacy policy updated
- [ ] Terms of service include payment terms
- [ ] PCI compliance requirements met

### Backend
- [ ] Server validates payment tokens
- [ ] Proper error handling implemented
- [ ] Payment confirmations sent to users
- [ ] Refund process implemented
- [ ] Logging and monitoring set up

## Troubleshooting

### Google Pay Not Available

**Problem**: `isAvailable()` returns `false`

**Solutions**:
1. Ensure Google Play Services is installed and up to date
2. Check that device is running Android 5.0 (API 21) or higher
3. Verify user has added a payment method in Google Pay
4. Confirm device is not rooted (Google Pay disabled on rooted devices)

### Payment Fails Immediately

**Problem**: Payment fails with an error code

**Solutions**:
1. Check merchant ID is correct
2. Verify environment setting (test vs production)
3. Ensure payment amount is valid (> 0)
4. Check internet connectivity

### Token Processing Fails

**Problem**: Backend rejects the payment token

**Solutions**:
1. Verify token format is correct
2. Check gateway merchant ID matches your processor
3. Ensure backend is configured for Google Pay tokens
4. Review payment processor documentation

### Button Not Showing

**Problem**: Google Pay button doesn't appear

**Solutions**:
1. Verify `isAvailable()` is called and returns true
2. Check plugin is properly registered
3. Ensure Android permissions are granted
4. Review logs for initialization errors

### Testing Issues

**Problem**: Can't test Google Pay in emulator

**Solutions**:
1. Use a physical device for testing
2. Ensure Google Play Services is installed in emulator
3. Sign in with a Google account in the emulator
4. Add a test card in Google Pay

## Additional Resources

- [Google Pay API Documentation](https://developers.google.com/pay/api/android/overview)
- [Google Pay Business Console](https://pay.google.com/business/console)
- [Google Pay Branding Guidelines](https://developers.google.com/pay/api/android/guides/brand-guidelines)
- [Payment Processor Integration Guides](https://developers.google.com/pay/api/android/guides/tutorial)

## Support

For issues specific to this package:
- [GitHub Issues](https://github.com/aliumairdev/flutter_pay_kit/issues)

For Google Pay specific issues:
- [Google Pay Support](https://support.google.com/pay/)
- [Google Pay Developer Forum](https://groups.google.com/g/googlepay-api)
