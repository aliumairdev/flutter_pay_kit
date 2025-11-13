# Flutter Universal Payments

A unified API for integrating multiple payment processors in Flutter apps.

## Overview

Flutter Universal Payments provides a consistent, easy-to-use interface for integrating various payment processors into your Flutter applications. Instead of learning and implementing different APIs for each payment provider, you can use a single, unified API that works across all supported processors.

## Supported Payment Processors

- **Stripe** - Industry-leading payment processing
- **Paddle** - SaaS billing and payments
- **Braintree** - PayPal-owned payment gateway
- **Lemon Squeezy** - Merchant of record for digital products
- **Totalpay Global** - International payment processing

## Features

- Unified API across all payment processors
- **Native Apple Pay integration for iOS** (iOS 13.0+)
- Type-safe payment models using Freezed
- State management with Riverpod
- Comprehensive error handling
- Easy switching between processors
- Built-in retry logic
- Local payment method storage
- Support for one-time and recurring payments
- Production-ready architecture

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_universal_payments: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

### Standard Payment Processors

```dart
import 'package:flutter_universal_payments/flutter_universal_payments.dart';

// Initialize a payment processor
final processor = StripeProcessor(
  apiKey: 'your_stripe_api_key',
);

// Process a payment
try {
  final result = await processor.processPayment(
    amount: 1999, // Amount in cents
    currency: 'USD',
    paymentMethod: paymentMethod,
  );

  if (result.isSuccess) {
    print('Payment successful: ${result.transactionId}');
  }
} catch (e) {
  print('Payment failed: $e');
}
```

### Apple Pay Integration (iOS)

```dart
import 'package:flutter_universal_payments/flutter_universal_payments.dart';

// Check if Apple Pay is available
final isAvailable = await ApplePayHandler.isAvailable();
if (isAvailable) {
  // Request payment
  final result = await ApplePayHandler.requestPayment(
    amount: 1999, // $19.99 in cents
    currency: 'USD',
    merchantId: 'merchant.com.yourcompany.yourapp',
    countryCode: 'US',
    label: 'Premium Subscription',
  );

  // Process the payment token with your backend
  final paymentData = result['paymentData'];
  // Send to your payment processor
}
```

For complete Apple Pay setup instructions, see [APPLE_PAY_SETUP.md](APPLE_PAY_SETUP.md).

## Architecture

The package follows a clean architecture pattern with clear separation of concerns:

- **Models**: Data structures for payments, customers, and transactions
- **Processors**: Implementation for each payment provider
- **Services**: Business logic and orchestration
- **Widgets**: Pre-built UI components for payment flows
- **Utils**: Helper functions and utilities
- **Exceptions**: Custom error types

## Requirements

- Dart SDK: `>=3.0.0 <4.0.0`
- Flutter SDK: `>=3.10.0`

## Development Status

This package is currently in active development (v0.1.0). APIs may change between releases until v1.0.0.

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues, feature requests, or questions, please file an issue on our GitHub repository.
