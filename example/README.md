# Flutter Universal Payments Example App

A comprehensive example application demonstrating all features of the `flutter_universal_payments` package.

## Overview

This example app showcases:

- **Payment Processing**: Complete payment flow with card input validation
- **Subscription Management**: Browse plans, subscribe, cancel, and resume subscriptions
- **Payment Methods**: Add, update, and manage payment methods
- **Billing History**: View past charges and invoices
- **Multiple Processors**: Switch between payment processors at runtime
- **Error Handling**: Comprehensive error handling and user feedback
- **UI Widgets**: All pre-built payment UI widgets from the package

## Screenshots

The app includes:
- **Home Screen**: Subscription status and quick actions
- **Pricing Screen**: Interactive subscription plans with PricingTable widget
- **Payment Screen**: Card input with validation using PaymentCardInput widget
- **Subscription Screen**: Manage active subscriptions with SubscriptionStatusWidget
- **Settings Screen**: Configure processors and test scenarios

## Getting Started

### 1. Navigate to Example Directory

```bash
cd example
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run the App

```bash
flutter run
```

That's it! The app uses the **Fake processor** by default, so no API keys are required.

## Using the Demo App

### Default Configuration

The app is configured to use the **Fake processor** for easy testing without requiring real payment credentials. This allows you to:
- Test all payment flows
- Simulate different payment scenarios
- Explore the UI without real charges

### Test Card Numbers

When testing with the Fake processor, use these card numbers:

| Scenario | Card Number |
|----------|-------------|
| Success | 4242 4242 4242 4242 |
| Declined | 4000 0000 0000 0002 |
| Insufficient Funds | 4000 0000 0000 9995 |
| Expired Card | 4000 0000 0000 0069 |
| Processing Error | 4000 0000 0000 0119 |

Use any future expiry date (e.g., 12/25) and any 3-digit CVC (e.g., 123).

### App Features

#### 1. Home Screen
- View current subscription status
- Quick access to all features
- Customer information display
- Feature overview

#### 2. Pricing Screen
- Browse subscription plans
- Compare features
- Switch between list, grid, and row layouts
- Comparison table view
- Trial period information

#### 3. Payment Screen
- Add payment methods using PaymentCardInput widget
- Card validation and formatting
- Set default payment method
- View saved payment methods
- Test different scenarios

#### 4. Subscription Screen
- View subscription details using SubscriptionStatusWidget
- Manage active subscription
- Cancel or resume subscription
- View billing history
- Change payment method

#### 5. Settings Screen
- Switch between payment processors
- Configure app settings
- View test card numbers
- Clear cache
- Reset demo data

## Switching to Real Processors

To test with real payment processors:

### Stripe

1. Get test API keys from [Stripe Dashboard](https://dashboard.stripe.com/test/apikeys)
2. Update `lib/config/config.dart`:
   ```dart
   static const String stripePublishableKey = 'pk_test_your_key';
   static const String stripeSecretKey = 'sk_test_your_key';
   ```
3. Go to Settings → Switch processor to Stripe

### Other Processors

Similar steps apply for other processors. Update the configuration in `lib/config/config.dart` with your test credentials.

**Important**: Never commit real API keys to version control!

## Code Structure

```
example/
├── lib/
│   ├── main.dart                 # App entry point and initialization
│   ├── config/
│   │   └── config.dart          # App configuration and sample data
│   └── screens/
│       ├── home_screen.dart     # Home screen with status overview
│       ├── pricing_screen.dart  # Subscription plans display
│       ├── payment_screen.dart  # Payment method management
│       ├── subscription_screen.dart  # Subscription management
│       └── settings_screen.dart # App settings and configuration
└── pubspec.yaml                 # Dependencies
```

## Key Concepts Demonstrated

### 1. Package Initialization

See `lib/main.dart:14-32` for how to initialize the payment system:

```dart
final config = PaymentConfigurationBuilder()
    .useFake(simulateDelays: true)
    .enableLogging()
    .build();

await FlutterUniversalPayments.initialize(config, storage: storage);
```

### 2. Using Payment Widgets

#### PaymentCardInput Widget
See `lib/screens/payment_screen.dart:73-90` for card input implementation.

#### PricingTable Widget
See `lib/screens/pricing_screen.dart:60-78` for pricing table implementation.

#### SubscriptionStatusWidget
See `lib/screens/subscription_screen.dart:88-100` for subscription status display.

### 3. Payment Service Operations

#### Subscribe to a Plan
```dart
await service.subscribe(
  priceId: 'plan_id',
  paymentMethodToken: 'token',
  trialDays: 14,
);
```

#### Manage Subscriptions
```dart
// Cancel subscription
await service.cancelSubscription(subscriptionId, immediate: false);

// Resume subscription
await service.resumeSubscription(subscriptionId);

// Change plan
await service.changePlan(
  subscriptionId: 'sub_id',
  newPriceId: 'new_plan_id',
);
```

#### Payment Methods
```dart
// Add payment method
await service.setDefaultPaymentMethod(paymentToken);

// Get payment methods
final methods = await service.getPaymentMethods();

// Remove payment method
await service.removePaymentMethod(methodId);
```

## Testing Scenarios

### Happy Path
1. Browse plans on Pricing screen
2. Select a plan
3. Enter payment details (use success card: 4242 4242 4242 4242)
4. View subscription on Subscription screen

### Error Handling
1. Go to Payment screen
2. Enter declined card: 4000 0000 0000 0002
3. See error handling in action

### Subscription Management
1. Subscribe to a plan
2. Go to Subscription screen
3. Try canceling subscription
4. Resume subscription before period ends

## Troubleshooting

### App won't build
- Make sure you're in the example directory: `cd example`
- Run `flutter pub get` to install dependencies
- Check Flutter version: `flutter --version` (requires Flutter 3.0+)

### Payment operations fail
- The Fake processor should work without any configuration
- Check console logs for error messages (logging is enabled by default)
- Try clearing cache in Settings screen

### UI not updating
- Pull down to refresh on Home and Subscription screens
- Check that the payment service is initialized properly

## Learn More

For detailed documentation on the package APIs:
- [Main Package README](../README.md)
- [API Documentation](https://pub.dev/documentation/flutter_universal_payments/latest/)

## Support

If you encounter issues or have questions:
1. Check the [GitHub Issues](https://github.com/yourusername/flutter_pay_kit/issues)
2. Review the package documentation
3. Examine the example code - it demonstrates all features

## License

This example app is part of the flutter_universal_payments package.
