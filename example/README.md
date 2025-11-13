# Flutter Universal Payments Example

This directory contains example applications demonstrating how to use the `flutter_universal_payments` package.

## Getting Started

To run the example app:

1. Navigate to the example directory:
   ```bash
   cd example
   ```

2. Get dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Examples Included

The example app demonstrates:

- Setting up payment processors
- Processing one-time payments
- Handling recurring subscriptions
- Error handling and retry logic
- Switching between different payment providers
- Using pre-built payment UI widgets

## Configuration

Before running the example, you'll need to configure your API keys for the payment processors you want to test.

Create a `.env` file in this directory (example/.env) with your test API keys:

```
STRIPE_TEST_KEY=your_stripe_test_key
PADDLE_TEST_KEY=your_paddle_test_key
BRAINTREE_TEST_KEY=your_braintree_test_key
LEMON_SQUEEZY_TEST_KEY=your_lemon_squeezy_test_key
TOTALPAY_TEST_KEY=your_totalpay_test_key
```

Never commit your API keys to version control!

## Learn More

For more information on using this package, see the main [README](../README.md).
