# Widget Documentation

Flutter Universal Payments includes six pre-built, customizable widgets to help you quickly implement payment UI in your Flutter app.

## Table of Contents

- [PaymentCardInput](#paymentcardinput)
- [PricingTable](#pricingtable)
- [SubscriptionCard](#subscriptioncard)
- [SubscriptionStatusWidget](#subscriptionstatuswidget)
- [PaymentMethodTile](#paymentmethodtile)
- [PaymentLoadingIndicator](#paymentloadingindicator)
- [Styling Guide](#styling-guide)
- [Best Practices](#best-practices)

---

## PaymentCardInput

A fully-featured card input widget with real-time validation and card brand detection.

### Features

- Real-time card number validation
- Automatic card brand detection (Visa, Mastercard, Amex, Discover, JCB, Diners Club)
- CVV validation
- Expiry date validation
- Postal code support (optional)
- Card number formatting (spaces every 4 digits)
- Luhn algorithm validation
- Custom styling support

### Basic Usage

```dart
import 'package:flutter_universal_payments/flutter_universal_payments.dart';

PaymentCardInput(
  onCardChanged: (PaymentCardData cardData) {
    if (cardData.isValid) {
      // Card data is valid, enable submit button
      setState(() {
        this.cardData = cardData;
        canSubmit = true;
      });
    }
  },
)
```

### With Postal Code

```dart
PaymentCardInput(
  requirePostalCode: true,
  onCardChanged: (cardData) {
    print('Card Number: ${cardData.cardNumber}');
    print('Expiry: ${cardData.expiryMonth}/${cardData.expiryYear}');
    print('CVV: ${cardData.cvv}');
    print('Postal Code: ${cardData.postalCode}');
    print('Card Brand: ${cardData.cardBrand}');
    print('Is Valid: ${cardData.isValid}');
  },
)
```

### Custom Styling

```dart
PaymentCardInput(
  cardDecoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Colors.blue, Colors.purple],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black26,
        blurRadius: 10,
        offset: Offset(0, 5),
      ),
    ],
  ),
  inputTextStyle: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  ),
  labelTextStyle: TextStyle(
    fontSize: 12,
    color: Colors.white70,
  ),
  errorTextStyle: TextStyle(
    fontSize: 12,
    color: Colors.red[300],
  ),
  onCardChanged: (cardData) {
    // Handle card data
  },
)
```

### PaymentCardData Properties

```dart
class PaymentCardData {
  String cardNumber;           // Card number without spaces
  int expiryMonth;            // 1-12
  int expiryYear;             // Full year (e.g., 2025)
  String cvv;                 // 3-4 digits
  String postalCode;          // Optional
  CardBrand cardBrand;        // Detected card brand
  bool isValid;               // Overall validity
  String? cardNumberError;    // Validation error message
  String? expiryError;        // Validation error message
  String? cvvError;           // Validation error message
  String? postalCodeError;    // Validation error message
}
```

### Card Brand Detection

Automatically detects card brands:

- 💳 **Visa**: Starts with 4
- 💳 **Mastercard**: Starts with 51-55 or 2221-2720
- 💳 **American Express**: Starts with 34 or 37
- 💳 **Discover**: Starts with 6011, 622126-622925, 644-649, or 65
- 💳 **JCB**: Starts with 3528-3589
- 💳 **Diners Club**: Starts with 36 or 38

---

## PricingTable

Display subscription plans in an attractive, customizable layout.

### Features

- Multiple layout modes (List, Grid, Row)
- Configurable columns for grid layout
- Featured/Popular/Best Value badges
- Trial period display
- Custom header support
- Empty state widget
- Loading state
- Customizable styling

### Basic Usage

```dart
PricingTable(
  plans: [
    SubscriptionPlanData(
      id: 'basic',
      name: 'Basic',
      description: 'Perfect for individuals',
      price: Price(
        id: 'price_basic',
        amount: 999,              // $9.99
        currency: 'USD',
        interval: BillingInterval.month,
      ),
      features: [
        '10 Projects',
        '5GB Storage',
        'Email Support',
      ],
    ),
    SubscriptionPlanData(
      id: 'pro',
      name: 'Professional',
      description: 'For growing teams',
      price: Price(
        id: 'price_pro',
        amount: 2999,             // $29.99
        currency: 'USD',
        interval: BillingInterval.month,
      ),
      features: [
        'Unlimited Projects',
        '100GB Storage',
        'Priority Support',
        'Advanced Analytics',
      ],
      badge: 'Popular',
      badgeColor: Colors.orange,
      isPopular: true,
    ),
  ],
  onPlanSelected: (plan) async {
    // Handle plan selection
    await paymentService.subscribe(priceId: plan.price.id);
  },
)
```

### Grid Layout

```dart
PricingTable(
  plans: plans,
  layout: PricingLayout.grid(crossAxisCount: 3),  // 3 columns
  onPlanSelected: (plan) {
    // Handle selection
  },
)
```

### Horizontal Scrolling

```dart
PricingTable(
  plans: plans,
  layout: PricingLayout.row,  // Horizontally scrollable
  onPlanSelected: (plan) {
    // Handle selection
  },
)
```

### Custom Styling

```dart
PricingTable(
  plans: plans,
  cardDecoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.grey[300]!, width: 2),
    boxShadow: [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 15,
        offset: Offset(0, 5),
      ),
    ],
  ),
  selectedPlanColor: Colors.green,
  popularPlanColor: Colors.blue,
  headerTextStyle: TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  ),
  priceTextStyle: TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w900,
    color: Colors.green,
  ),
  featureTextStyle: TextStyle(
    fontSize: 14,
    color: Colors.grey[700],
  ),
  onPlanSelected: (plan) {
    // Handle selection
  },
)
```

### With Custom Header

```dart
PricingTable(
  plans: plans,
  headerBuilder: (context) => Column(
    children: [
      Text(
        'Choose Your Plan',
        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 8),
      Text(
        'Start your 14-day free trial',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
      SizedBox(height: 24),
    ],
  ),
  onPlanSelected: (plan) {
    // Handle selection
  },
)
```

### With Annual Billing

```dart
PricingTable(
  plans: [
    SubscriptionPlanData(
      id: 'monthly',
      name: 'Monthly',
      price: Price(
        id: 'price_monthly',
        amount: 999,
        currency: 'USD',
        interval: BillingInterval.month,
      ),
      features: ['Feature 1', 'Feature 2'],
    ),
    SubscriptionPlanData(
      id: 'annual',
      name: 'Annual',
      price: Price(
        id: 'price_annual',
        amount: 9999,
        currency: 'USD',
        interval: BillingInterval.year,
      ),
      features: ['Feature 1', 'Feature 2', '2 months free'],
      badge: 'Best Value',
      badgeColor: Colors.green,
    ),
  ],
  onPlanSelected: (plan) {
    // Handle selection
  },
)
```

---

## SubscriptionCard

Display detailed subscription information in a card format.

### Features

- Status indicators with color coding
- Trial period display
- Billing period information
- Renewal/expiry dates
- Cancellation status
- Custom actions
- Fully customizable styling

### Basic Usage

```dart
SubscriptionCard(
  subscription: subscription,
  onManage: () {
    // Navigate to subscription management
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageSubscriptionScreen(subscription),
      ),
    );
  },
)
```

### With Actions

```dart
SubscriptionCard(
  subscription: subscription,
  showActions: true,
  onCancel: () async {
    final confirm = await showConfirmDialog(context);
    if (confirm) {
      await paymentService.cancelSubscription(
        id: subscription.id,
        immediate: false,
      );
    }
  },
  onUpgrade: () {
    // Show upgrade options
    showUpgradeDialog(context);
  },
)
```

### Custom Styling

```dart
SubscriptionCard(
  subscription: subscription,
  cardDecoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Colors.purple[700]!, Colors.purple[400]!],
    ),
    borderRadius: BorderRadius.circular(16),
  ),
  textColor: Colors.white,
  statusColor: Colors.white,
  onManage: () {
    // Handle manage action
  },
)
```

### Status Colors

The widget automatically colors based on subscription status:

- 🟢 **Active**: Green
- 🔵 **Trialing**: Blue
- 🟡 **Past Due**: Amber
- 🔴 **Canceled**: Red
- ⚫ **Incomplete**: Grey
- 🟣 **Paused**: Purple

---

## SubscriptionStatusWidget

A compact widget showing subscription status with visual indicators.

### Features

- Real-time status display
- Color-coded indicators
- Trial countdown
- Renewal date display
- Grace period information
- Usage progress (optional)
- Customizable

### Basic Usage

```dart
SubscriptionStatusWidget(
  subscription: subscription,
)
```

### With Progress Indicator

```dart
SubscriptionStatusWidget(
  subscription: subscription,
  showProgress: true,
  currentUsage: 450,    // Current usage
  maxUsage: 1000,       // Plan limit
  usageLabel: 'API Calls',
)
```

### Custom Styling

```dart
SubscriptionStatusWidget(
  subscription: subscription,
  activeColor: Colors.green,
  trialColor: Colors.blue,
  expiredColor: Colors.red,
  textStyle: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  ),
  iconSize: 24,
)
```

### In AppBar

```dart
AppBar(
  title: Text('My App'),
  actions: [
    Padding(
      padding: EdgeInsets.all(8),
      child: SubscriptionStatusWidget(
        subscription: subscription,
        compact: true,
      ),
    ),
  ],
)
```

### With Riverpod

```dart
class SubscriptionStatusDisplay extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync = ref.watch(activeSubscriptionProvider);

    return subscriptionAsync.when(
      data: (subscription) => subscription != null
          ? SubscriptionStatusWidget(subscription: subscription)
          : Text('No active subscription'),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Icon(Icons.error),
    );
  }
}
```

---

## PaymentMethodTile

Display payment methods in a list or grid format.

### Features

- Card brand icons
- Last 4 digits display (masked)
- Expiry date
- Default badge
- Remove action
- Custom styling

### Basic Usage

```dart
PaymentMethodTile(
  paymentMethod: paymentMethod,
  onTap: () {
    // Set as default or edit
  },
)
```

### In ListView

```dart
ListView.builder(
  itemCount: paymentMethods.length,
  itemBuilder: (context, index) {
    final method = paymentMethods[index];
    return PaymentMethodTile(
      paymentMethod: method,
      showRemoveButton: true,
      onTap: () async {
        // Set as default
        await paymentService.setDefaultPaymentMethod(method.id);
      },
      onRemove: () async {
        // Remove payment method
        await paymentService.removePaymentMethod(method.id);
      },
    );
  },
)
```

### Custom Styling

```dart
PaymentMethodTile(
  paymentMethod: paymentMethod,
  tileDecoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: paymentMethod.isDefault ? Colors.blue : Colors.grey[300]!,
      width: 2,
    ),
  ),
  textStyle: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  ),
  defaultBadgeColor: Colors.green,
  onTap: () {
    // Handle tap
  },
)
```

### With Add New Button

```dart
Column(
  children: [
    ...paymentMethods.map((method) => PaymentMethodTile(
      paymentMethod: method,
      onTap: () => selectMethod(method),
    )),
    ListTile(
      leading: Icon(Icons.add_circle, color: Colors.blue),
      title: Text('Add New Payment Method'),
      onTap: () {
        // Navigate to add payment method screen
      },
    ),
  ],
)
```

---

## PaymentLoadingIndicator

An attractive loading indicator for payment operations.

### Features

- Multiple animation styles
- Success/failure states
- Customizable colors
- Message display
- Configurable size

### Basic Usage

```dart
if (isProcessingPayment)
  PaymentLoadingIndicator(
    message: 'Processing payment...',
  )
```

### With State Changes

```dart
class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentLoadingState state = PaymentLoadingState.loading;

  Future<void> processPayment() async {
    setState(() => state = PaymentLoadingState.loading);

    try {
      await paymentService.makePayment(...);
      setState(() => state = PaymentLoadingState.success);
      await Future.delayed(Duration(seconds: 2));
      Navigator.pop(context);
    } catch (e) {
      setState(() => state = PaymentLoadingState.failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Your payment form

        if (state != PaymentLoadingState.idle)
          PaymentLoadingIndicator(
            state: state,
            loadingMessage: 'Processing payment...',
            successMessage: 'Payment successful!',
            failureMessage: 'Payment failed. Please try again.',
          ),
      ],
    );
  }
}
```

### Custom Styling

```dart
PaymentLoadingIndicator(
  state: PaymentLoadingState.loading,
  message: 'Securing your payment...',
  loadingColor: Colors.blue,
  successColor: Colors.green,
  failureColor: Colors.red,
  backgroundColor: Colors.black87,
  textStyle: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  ),
  size: 60,
)
```

### Full Screen Overlay

```dart
if (isLoading)
  Positioned.fill(
    child: Container(
      color: Colors.black54,
      child: Center(
        child: PaymentLoadingIndicator(
          message: 'Processing...',
        ),
      ),
    ),
  )
```

---

## Styling Guide

### Theme Integration

All widgets respect your app's theme by default:

```dart
MaterialApp(
  theme: ThemeData(
    primaryColor: Colors.blue,
    cardTheme: CardTheme(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    textTheme: TextTheme(
      headlineSmall: TextStyle(fontWeight: FontWeight.bold),
      bodyMedium: TextStyle(fontSize: 14),
    ),
  ),
  home: YourApp(),
)

// Widgets will inherit these styles
```

### Consistent Branding

Create reusable style constants:

```dart
class PaymentStyles {
  static const primaryColor = Color(0xFF6C63FF);
  static const accentColor = Color(0xFF4CAF50);

  static final cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 10,
        offset: Offset(0, 4),
      ),
    ],
  );

  static const headerTextStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );
}

// Use in widgets
PricingTable(
  plans: plans,
  cardDecoration: PaymentStyles.cardDecoration,
  headerTextStyle: PaymentStyles.headerTextStyle,
  selectedPlanColor: PaymentStyles.accentColor,
  onPlanSelected: (plan) => selectPlan(plan),
)
```

### Responsive Design

Make widgets responsive:

```dart
LayoutBuilder(
  builder: (context, constraints) {
    // Mobile: List layout
    if (constraints.maxWidth < 600) {
      return PricingTable(
        plans: plans,
        layout: PricingLayout.list,
        onPlanSelected: selectPlan,
      );
    }
    // Tablet: 2 columns
    else if (constraints.maxWidth < 900) {
      return PricingTable(
        plans: plans,
        layout: PricingLayout.grid(crossAxisCount: 2),
        onPlanSelected: selectPlan,
      );
    }
    // Desktop: 3 columns
    else {
      return PricingTable(
        plans: plans,
        layout: PricingLayout.grid(crossAxisCount: 3),
        onPlanSelected: selectPlan,
      );
    }
  },
)
```

---

## Best Practices

### 1. Form Validation

Always validate before submission:

```dart
final formKey = GlobalKey<FormState>();
PaymentCardData? cardData;

Form(
  key: formKey,
  child: Column(
    children: [
      PaymentCardInput(
        onCardChanged: (data) {
          cardData = data;
        },
      ),
      ElevatedButton(
        onPressed: () {
          if (cardData?.isValid ?? false) {
            processPayment(cardData!);
          } else {
            showError('Please check card details');
          }
        },
        child: Text('Pay Now'),
      ),
    ],
  ),
)
```

### 2. Loading States

Always show loading indicators:

```dart
bool isLoading = false;

ElevatedButton(
  onPressed: isLoading ? null : () async {
    setState(() => isLoading = true);
    try {
      await paymentService.subscribe(priceId: priceId);
      // Success
    } finally {
      setState(() => isLoading = false);
    }
  },
  child: isLoading
      ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : Text('Subscribe'),
)
```

### 3. Error Handling

Provide clear error messages:

```dart
try {
  await paymentService.subscribe(priceId: priceId);
} on ProcessorException catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(e.message),
      backgroundColor: Colors.red,
      action: SnackBarAction(
        label: 'Retry',
        onPressed: () => retry(),
      ),
    ),
  );
}
```

### 4. Accessibility

Ensure widgets are accessible:

```dart
Semantics(
  label: 'Credit card number input',
  child: PaymentCardInput(
    onCardChanged: (data) => handleCardData(data),
  ),
)
```

### 5. Testing

Test widgets thoroughly:

```dart
testWidgets('PaymentCardInput validates card number', (tester) async {
  PaymentCardData? cardData;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PaymentCardInput(
          onCardChanged: (data) => cardData = data,
        ),
      ),
    ),
  );

  // Enter invalid card number
  await tester.enterText(find.byType(TextField).first, '1234');
  await tester.pump();

  expect(cardData?.isValid, false);
  expect(cardData?.cardNumberError, isNotNull);
});
```

---

## Complete Example

Here's a complete payment flow using multiple widgets:

```dart
class CheckoutScreen extends StatefulWidget {
  final SubscriptionPlanData plan;

  CheckoutScreen({required this.plan});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  PaymentCardData? cardData;
  PaymentLoadingState loadingState = PaymentLoadingState.idle;

  Future<void> processPayment() async {
    if (cardData == null || !cardData!.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please check card details')),
      );
      return;
    }

    setState(() => loadingState = PaymentLoadingState.loading);

    try {
      // Tokenize card
      final token = await tokenizeCard(cardData!);

      // Set payment method
      await paymentService.setDefaultPaymentMethod(token);

      // Create subscription
      final subscription = await paymentService.subscribe(
        priceId: widget.plan.price.id,
      );

      setState(() => loadingState = PaymentLoadingState.success);

      await Future.delayed(Duration(seconds: 2));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SuccessScreen(subscription: subscription),
        ),
      );
    } catch (e) {
      setState(() => loadingState = PaymentLoadingState.failure);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Checkout')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Selected plan summary
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.plan.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        SizedBox(height: 8),
                        Text(
                          widget.plan.price.formattedPrice,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Card input
                PaymentCardInput(
                  requirePostalCode: true,
                  onCardChanged: (data) {
                    setState(() => cardData = data);
                  },
                ),

                SizedBox(height: 24),

                // Submit button
                ElevatedButton(
                  onPressed: loadingState == PaymentLoadingState.loading
                      ? null
                      : processPayment,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.all(16),
                  ),
                  child: Text(
                    'Subscribe Now',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),

          // Loading overlay
          if (loadingState != PaymentLoadingState.idle)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: PaymentLoadingIndicator(
                    state: loadingState,
                    loadingMessage: 'Processing payment...',
                    successMessage: 'Payment successful!',
                    failureMessage: 'Payment failed',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

---

For more widget examples, check out the [example app](../example/) or explore individual widget files in `lib/src/widgets/`.
