# Code Examples

This directory contains practical code examples for Flutter Universal Payments.

## Available Examples

### 1. [Quick Start](quick_start.dart)
The simplest possible implementation to get started with Flutter Universal Payments.

**What it demonstrates:**
- Basic package initialization
- Simple storage implementation
- Creating a subscription
- Minimal error handling

**Best for:** First-time users wanting to see the package in action quickly.

---

### 2. [Subscription Management](subscription_management.dart)
Complete subscription lifecycle management.

**What it demonstrates:**
- Loading subscription status
- Creating subscriptions with trials
- Changing subscription plans
- Canceling subscriptions (immediate and at period end)
- Resuming canceled subscriptions
- Error handling and user feedback
- Using SubscriptionStatusWidget

**Best for:** Apps with subscription-based business models.

---

### 3. [Payment Form](payment_form.dart)
A complete, production-ready payment form.

**What it demonstrates:**
- PaymentCardInput widget usage
- Real-time card validation
- Payment method tokenization
- Processing payments with loading states
- Comprehensive error handling
- Security best practices
- PaymentLoadingIndicator states

**Best for:** Implementing checkout flows.

---

### 4. [Switching Processors](switching_processors.dart)
Runtime processor switching demonstration.

**What it demonstrates:**
- Switching between payment processors at runtime
- Configuration for each processor type
- Testing different processors
- Multi-region payment setups
- Using the same API across processors

**Best for:** Understanding the processor abstraction and multi-region setups.

---

## Running the Examples

### Prerequisites

```bash
flutter pub get
```

### Configuration

Before running examples, you'll need API credentials for the processors you want to test.

For quick testing, use the Fake processor (no credentials needed):

```dart
final config = PaymentConfigurationBuilder()
    .useFake()
    .build();
```

For real processors, add your credentials:

```dart
// Using environment variables (recommended)
final config = PaymentConfigurationBuilder()
    .useStripe(
      publishableKey: const String.fromEnvironment('STRIPE_PUBLISHABLE_KEY'),
      secretKey: const String.fromEnvironment('STRIPE_SECRET_KEY'),
    )
    .build();

// Run with:
// flutter run --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_... --dart-define=STRIPE_SECRET_KEY=sk_test_...
```

### Running an Example

These examples are meant to be copied into your own project or the example app:

1. **Copy to your project:**
   ```bash
   cp doc/examples/quick_start.dart lib/
   ```

2. **Update your main.dart:**
   ```dart
   import 'package:your_app/quick_start.dart';

   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await initializePaymentService();
     runApp(const MyApp());
   }
   ```

3. **Run:**
   ```bash
   flutter run
   ```

---

## Integration with Main Example App

The main example app (`example/`) includes all these patterns and more. Check it out for a complete, working application.

```bash
cd example
flutter run
```

---

## Example Patterns

### Error Handling Pattern

```dart
try {
  final result = await paymentService.someOperation();
  // Handle success
} on ProcessorException catch (e) {
  // Handle processor-specific errors
  print('Processor error: ${e.code} - ${e.message}');
} on NetworkException catch (e) {
  // Handle network errors
  print('Network error - check connection');
} on ValidationException catch (e) {
  // Handle validation errors
  print('Validation error: ${e.message}');
} catch (e) {
  // Handle unexpected errors
  print('Unexpected error: $e');
}
```

### Loading State Pattern

```dart
class _MyWidgetState extends State<MyWidget> {
  bool _isLoading = false;

  Future<void> _doOperation() async {
    setState(() => _isLoading = true);
    try {
      await paymentService.someOperation();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _doOperation,
      child: _isLoading
          ? CircularProgressIndicator()
          : Text('Submit'),
    );
  }
}
```

### Using Riverpod Pattern

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync = ref.watch(activeSubscriptionProvider);

    return subscriptionAsync.when(
      data: (subscription) => SubscriptionCard(subscription: subscription),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => ErrorWidget(error),
    );
  }
}
```

---

## Testing Examples

All examples can be tested with the Fake processor:

```dart
final config = PaymentConfigurationBuilder()
    .useFake(
      simulateDelays: true,
      delayDuration: Duration(seconds: 1),
      failureRate: 0.1, // 10% of operations fail
    )
    .build();

await FlutterUniversalPayments.initialize(
  config: config,
  storage: InMemoryStorage(),
);
```

---

## Contributing Examples

Have a useful example? We'd love to include it! Please:

1. Follow the existing code style
2. Include comprehensive comments
3. Demonstrate a specific use case or pattern
4. Add it to this README
5. Submit a pull request

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for details.

---

## Additional Resources

- [Getting Started Guide](../getting_started.md)
- [Widget Documentation](../widgets.md)
- [Advanced Usage](../advanced.md)
- [Main Example App](../../example/)
- [API Documentation](https://pub.dev/documentation/flutter_universal_payments/latest/)

---

## Questions?

- Check the [documentation](../)
- Search [GitHub issues](https://github.com/aliumairdev/flutter_pay_kit/issues)
- Start a [discussion](https://github.com/aliumairdev/flutter_pay_kit/discussions)
