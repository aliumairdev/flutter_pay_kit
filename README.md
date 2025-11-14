# Flutter Universal Payments

[![pub package](https://img.shields.io/pub/v/flutter_universal_payments.svg)](https://pub.dev/packages/flutter_universal_payments)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A unified, production-ready payment API for Flutter that supports multiple payment processors with a single, consistent interface. Switch between payment providers without rewriting your code.

## ✨ Features

- 🔌 **Unified API** - One consistent interface for all payment processors
- 💳 **6 Payment Processors** - Stripe, Paddle, Braintree, Lemon Squeezy, Totalpay, and Fake (for testing)
- 🔄 **Hot-Swappable** - Switch processors at runtime without code changes
- 📱 **Ready-to-Use Widgets** - Pre-built payment UI components
- 🎨 **Highly Customizable** - Customize every aspect to match your brand
- 🔒 **Secure by Design** - PCI-compliant patterns, no card data storage
- 🧪 **Testing Support** - Built-in fake processor for development
- 📊 **Analytics Ready** - Firebase, Sentry, and custom analytics integrations
- 🔐 **Smart Caching** - Automatic data caching with secure storage
- 🚀 **Production Ready** - Comprehensive error handling and retry logic
- 🎯 **Type Safe** - Full Dart type safety with Freezed models
- ⚡ **State Management** - Built-in Riverpod integration

## 📦 Supported Payment Processors

| Processor | Subscriptions | One-time Payments | Plan Swapping | Webhooks | Testing |
|-----------|:-------------:|:-----------------:|:-------------:|:--------:|:-------:|
| **Stripe** | ✅ | ✅ | ✅ | ✅ | Sandbox |
| **Paddle** | ✅ | ✅ | ✅ | ✅ | Sandbox |
| **Braintree** | ✅ | ✅ | ✅ | ✅ | Sandbox |
| **Lemon Squeezy** | ✅ | ✅ | ✅ | ✅ | Test Mode |
| **Totalpay** | 🚧 | 🚧 | 🚧 | 🚧 | Sandbox |
| **Fake** | ✅ | ✅ | ✅ | ❌ | Built-in |

**Note**: 🚧 = Partial implementation (Totalpay pending full API documentation)

## 🚀 Quick Start

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_universal_payments: ^1.0.0
```

Then run:

```bash
flutter pub get
```

### Basic Usage

```dart
import 'package:flutter_universal_payments/flutter_universal_payments.dart';

// 1. Configure your payment processor
final config = PaymentConfigurationBuilder()
  .useStripe(
    publishableKey: 'pk_test_...',
    secretKey: 'sk_test_...',
    webhookSecret: 'whsec_...',
  )
  .enableLogging()
  .build();

// 2. Initialize the payment service
await FlutterUniversalPayments.initialize(
  config: config,
  storage: storage, // Your Storage implementation
);

// 3. Get the service instance
final paymentService = FlutterUniversalPayments.instance;

// 4. Initialize customer
await paymentService.initialize(
  email: 'customer@example.com',
  name: 'John Doe',
);

// 5. Create a subscription
final subscription = await paymentService.subscribe(
  priceId: 'price_monthly_999',
  trialDays: 14,
);

print('Subscription created: ${subscription.id}');
```

### UI Widgets

The package includes ready-to-use payment widgets:

```dart
// Display pricing plans
PricingTable(
  plans: [
    SubscriptionPlanData(
      id: 'basic',
      name: 'Basic',
      price: Price(
        id: 'price_basic',
        amount: 999,
        currency: 'USD',
        interval: BillingInterval.month,
      ),
      features: ['Feature 1', 'Feature 2'],
    ),
  ],
  onPlanSelected: (plan) async {
    await paymentService.subscribe(priceId: plan.price.id);
  },
)

// Payment card input
PaymentCardInput(
  onCardChanged: (cardData) {
    // Handle card data
  },
)

// Subscription status display
SubscriptionStatusWidget(
  subscription: subscription,
)
```

## 📖 Documentation

- **[Getting Started Guide](doc/getting_started.md)** - Detailed setup for each processor
- **[Widgets Documentation](doc/widgets.md)** - UI components and customization
- **[Advanced Usage](doc/advanced.md)** - Webhooks, custom processors, best practices
- **[API Reference](https://pub.dev/documentation/flutter_universal_payments/latest/)** - Complete API docs

### Processor-Specific Guides

- [Stripe Integration](doc/processors/stripe.md)
- [Paddle Integration](doc/processors/paddle.md)
- [Braintree Integration](doc/processors/braintree.md)
- [Lemon Squeezy Integration](doc/processors/lemon_squeezy.md)
- [Totalpay Integration](doc/processors/totalpay.md)

## 🎯 Core Concepts

### Customer Management

```dart
// Initialize a customer
await paymentService.initialize(
  email: 'customer@example.com',
  name: 'John Doe',
  phone: '+1234567890',
);

// Get current customer
final customer = await paymentService.getCurrentCustomer();

// Refresh customer data
await paymentService.refreshCustomer();
```

### Subscriptions

```dart
// Create subscription with trial
final subscription = await paymentService.subscribe(
  priceId: 'price_monthly',
  trialDays: 14,
);

// Check subscription status
final hasActive = await paymentService.hasActiveSubscription('product_id');
final isOnTrial = await paymentService.isOnTrial('product_id');

// Change subscription plan
await paymentService.changePlan(
  subscriptionId: subscription.id,
  newPriceId: 'price_annual',
);

// Cancel subscription
await paymentService.cancelSubscription(
  id: subscription.id,
  immediate: false, // Grace period until end of billing cycle
);

// Resume canceled subscription
await paymentService.resumeSubscription(id: subscription.id);
```

### Payment Methods

```dart
// Add payment method
await paymentService.setDefaultPaymentMethod(paymentMethodToken);

// Get all payment methods
final methods = await paymentService.getPaymentMethods();

// Remove payment method
await paymentService.removePaymentMethod(methodId);
```

### One-Time Payments

```dart
// Create a one-time charge
final charge = await paymentService.makePayment(
  amount: 2999, // $29.99
  currency: 'USD',
  description: 'Premium upgrade',
  paymentMethodToken: token,
);
```

## 🔄 Switching Processors

One of the most powerful features is the ability to switch payment processors without changing your code:

```dart
// Start with Stripe
final stripeConfig = PaymentConfigurationBuilder()
  .useStripe(publishableKey: '...', secretKey: '...')
  .build();

await FlutterUniversalPayments.initialize(config: stripeConfig);

// Later, switch to Paddle
final paddleConfig = PaymentConfigurationBuilder()
  .usePaddle(
    vendorId: '...',
    authCode: '...',
    publicKey: '...',
  )
  .build();

await FlutterUniversalPayments.reinitialize(config: paddleConfig);

// Your app code remains the same!
```

## 🎨 Customization

All widgets are highly customizable:

```dart
PricingTable(
  plans: plans,
  layout: PricingLayout.grid(crossAxisCount: 3),
  cardDecoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Colors.blue, Colors.purple],
    ),
    borderRadius: BorderRadius.circular(20),
  ),
  selectedPlanColor: Colors.green,
  onPlanSelected: (plan) => handlePlanSelection(plan),
  headerBuilder: (context) => CustomHeader(),
)
```

## 📊 Analytics & Logging

Built-in support for analytics and logging:

```dart
// Enable logging
PaymentLogger.enable();
PaymentLogger.setLogLevel(LogLevel.debug);

// Add analytics providers
PaymentLogger.registerAnalyticsProvider(
  FirebaseAnalyticsProvider(analytics),
);

// Automatic event logging
// - Payment success/failure
// - Subscription created/canceled
// - Plan changes
// - Checkout events
```

## 🧪 Testing

Use the built-in fake processor for testing:

```dart
final testConfig = PaymentConfigurationBuilder()
  .useFake(
    simulateDelays: true,
    delayDuration: Duration(seconds: 1),
    failureRate: 0.1, // 10% failure rate
  )
  .build();

await FlutterUniversalPayments.initialize(config: testConfig);
```

## 🏗️ Architecture

The package follows clean architecture principles:

```
lib/
├── src/
│   ├── models/          # Data models (Customer, Subscription, Charge, etc.)
│   ├── processors/      # Payment processor implementations
│   ├── services/        # Business logic (PaymentService)
│   ├── widgets/         # UI components
│   ├── utils/           # Logging, analytics
│   └── exceptions/      # Custom exceptions
└── flutter_universal_payments.dart  # Public API
```

## 🔒 Security Best Practices

- Never store sensitive card data locally
- Use tokenization for payment methods
- Implement webhook signature verification
- Enable logging with sensitive data masking
- Use secure storage for customer IDs and tokens
- Always use HTTPS endpoints
- Validate all user inputs

See [Advanced Usage](doc/advanced.md#security-best-practices) for detailed security guidelines.

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

```bash
# Clone the repository
git clone https://github.com/aliumairdev/flutter_pay_kit.git
cd flutter_pay_kit

# Install dependencies
flutter pub get

# Run code generation
flutter pub run build_runner build

# Run tests
flutter test

# Run example app
cd example
flutter run
```

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📱 Native Mobile Payments

### Google Pay Integration (Android)

```dart
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

### Apple Pay Integration (iOS)

```dart
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

## 🆘 Support

- **Documentation**: [doc/getting_started.md](doc/getting_started.md)
- **Issues**: [GitHub Issues](https://github.com/aliumairdev/flutter_pay_kit/issues)
- **Discussions**: [GitHub Discussions](https://github.com/aliumairdev/flutter_pay_kit/discussions)

## 🗺️ Roadmap

- [x] Apple Pay support (iOS 13.0+)
- [x] Google Pay support (Android)
- [ ] PayPal direct integration
- [ ] Cryptocurrency payments
- [ ] Invoice generation
- [ ] Receipt management
- [ ] Enhanced multi-currency support
- [ ] Tax calculation integration
- [ ] Fraud detection hooks
- [ ] Refund management
- [ ] Dispute handling

## 📦 Requirements

- **Dart SDK**: `>=3.0.0 <4.0.0`
- **Flutter SDK**: `>=3.10.0`

## 🌟 Examples

Check out the [example](example/) directory for a complete Flutter app demonstrating all features:

- Customer initialization
- Subscription management
- Payment method handling
- One-time payments
- UI widgets showcase
- Analytics integration

## 📚 Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- [Riverpod Documentation](https://riverpod.dev)
- [Stripe API Documentation](https://stripe.com/docs/api)
- [Paddle API Documentation](https://developer.paddle.com/)
- [Braintree API Documentation](https://developer.paypal.com/braintree/docs)

---

Made with ❤️ by the Flutter community
