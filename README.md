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
- **Native Google Pay integration for Android**
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

### Standard Payment Processing

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

### Google Pay Integration (Android)

```dart
import 'package:flutter_universal_payments/flutter_universal_payments.dart';

// Configure Google Pay
final googlePayConfig = GooglePayConfig(
  merchantId: 'your-merchant-id',
  merchantName: 'Your Store',
  environment: GooglePayEnvironment.production,
);

// Check availability
final isAvailable = await googlePayConfig.isAvailable();

if (isAvailable) {
  // Request payment
  final token = await googlePayConfig.requestPayment(amount: 2500);

  if (token != null) {
    // Process the token with your payment processor
    print('Payment token: $token');
  }
}
```

For detailed Google Pay integration instructions, see [GOOGLE_PAY_INTEGRATION.md](GOOGLE_PAY_INTEGRATION.md).

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
