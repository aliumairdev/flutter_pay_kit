# Apple Pay Setup Guide

This guide will help you set up Apple Pay integration in your Flutter app using the `flutter_universal_payments` package.

## Prerequisites

- iOS 13.0 or later
- Physical iOS device (Apple Pay doesn't work in the simulator)
- Apple Developer Program membership
- Xcode 14.0 or later

## Step 1: Create Merchant Identifier

1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Select **Identifiers** from the sidebar
4. Click the **+** button to create a new identifier
5. Select **Merchant IDs** and click **Continue**
6. Enter a description and identifier (e.g., `merchant.com.yourcompany.yourapp`)
7. Click **Register**

## Step 2: Enable Apple Pay Capability

1. Open your Flutter project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. Select your app target in Xcode
3. Go to the **Signing & Capabilities** tab
4. Click **+ Capability**
5. Select **Apple Pay**
6. Under **Merchant IDs**, click the **+** button
7. Select the Merchant ID you created in Step 1

## Step 3: Add Entitlements File

1. In Xcode, right-click on the **Runner** folder
2. Select **New File...**
3. Choose **Property List**
4. Name it **Runner.entitlements**
5. Add the following content:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.developer.in-app-payments</key>
	<array>
		<string>merchant.com.yourcompany.yourapp</string>
	</array>
</dict>
</plist>
```

Replace `merchant.com.yourcompany.yourapp` with your actual Merchant ID.

## Step 4: Configure Payment Processing Certificate

### For Production:

1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Select **Identifiers** > Your Merchant ID
4. Click **Create Certificate** under **Apple Pay Payment Processing Certificate**
5. Follow the instructions to generate a CSR (Certificate Signing Request) in Keychain Access
6. Upload the CSR and download the certificate
7. Double-click the certificate to install it in Keychain Access

### For Development/Sandbox:

1. Follow the same steps as above
2. Click **Create Certificate** under **Apple Pay Merchant Identity Certificate**
3. This allows testing with sandbox cards

## Step 5: Integrate with Your Payment Processor

Apple Pay generates a payment token that needs to be processed by your payment backend. Configure your payment processor to accept Apple Pay tokens:

### Stripe Example:
```dart
import 'package:flutter_universal_payments/flutter_universal_payments.dart';

// Check if Apple Pay is available
final isAvailable = await ApplePayHandler.isAvailable();
if (!isAvailable) {
  print('Apple Pay is not available on this device');
  return;
}

// Check if user has cards set up
final canMakePayments = await ApplePayHandler.canMakePayments(
  networks: ['visa', 'mastercard', 'amex'],
);

if (!canMakePayments) {
  print('No supported cards are set up in Wallet');
  return;
}

try {
  // Request payment
  final result = await ApplePayHandler.requestPayment(
    amount: 1999, // $19.99 in cents
    currency: 'USD',
    merchantId: 'merchant.com.yourcompany.yourapp',
    countryCode: 'US',
    label: 'Premium Subscription',
    networks: ['visa', 'mastercard', 'amex'],
  );

  // Extract payment token
  final paymentData = result['paymentData'] as String;
  final transactionId = result['transactionIdentifier'] as String;

  // Send to your backend for processing
  await processPaymentWithBackend(paymentData, transactionId);

  print('Payment successful!');
} on ApplePayException catch (e) {
  print('Apple Pay error: ${e.message}');
}
```

## Step 6: Testing

### Test Cards

Apple Pay in sandbox mode works with test cards configured in the Sandbox environment:

1. Go to Settings > Wallet & Apple Pay on your test device
2. Add a test card (these are provided by Apple for testing)

### Common Test Scenarios

```dart
// Basic payment
final result = await ApplePayHandler.requestPayment(
  amount: 1000,
  currency: 'USD',
  merchantId: 'merchant.com.yourcompany.yourapp',
  countryCode: 'US',
);

// Payment with shipping
final resultWithShipping = await ApplePayHandler.requestPayment(
  amount: 1000,
  currency: 'USD',
  merchantId: 'merchant.com.yourcompany.yourapp',
  countryCode: 'US',
  shippingRequired: true,
  shippingMethods: [
    {
      'identifier': 'standard',
      'label': 'Standard Shipping',
      'detail': '5-7 business days',
      'amount': '5.00',
    },
    {
      'identifier': 'express',
      'label': 'Express Shipping',
      'detail': '2-3 business days',
      'amount': '15.00',
    },
  ],
);

// Payment requiring billing address
final resultWithBilling = await ApplePayHandler.requestPayment(
  amount: 1000,
  currency: 'USD',
  merchantId: 'merchant.com.yourcompany.yourapp',
  countryCode: 'US',
  billingRequired: true,
);
```

## Configuration Options

### Supported Card Networks

```dart
final networks = [
  ApplePayNetwork.visa,
  ApplePayNetwork.masterCard,
  ApplePayNetwork.amex,
  ApplePayNetwork.discover,
  ApplePayNetwork.chinaUnionPay,
  ApplePayNetwork.interac,
  ApplePayNetwork.jcb,
  ApplePayNetwork.maestro,
  ApplePayNetwork.eftpos,
  ApplePayNetwork.electron,
  ApplePayNetwork.elo,
  ApplePayNetwork.mada,
  ApplePayNetwork.vpay,
  ApplePayNetwork.girocard,
];
```

### Merchant Capabilities

```dart
final capabilities = [
  ApplePayCapability.threeDS,  // 3D Secure
  ApplePayCapability.emv,      // EMV
  ApplePayCapability.credit,   // Credit cards
  ApplePayCapability.debit,    // Debit cards
];
```

### Shipping Types

```dart
final shippingType = ApplePayShippingType.shipping;      // Physical goods
final shippingType = ApplePayShippingType.delivery;      // Food delivery, etc.
final shippingType = ApplePayShippingType.storePickup;   // Pick up in store
final shippingType = ApplePayShippingType.servicePickup; // Service appointment
```

## Payment Result Structure

```dart
final result = await ApplePayHandler.requestPayment(...);

// Result contains:
{
  'paymentData': 'base64-encoded payment token',
  'transactionIdentifier': 'unique-transaction-id',
  'paymentMethod': {
    'displayName': 'Visa •••• 1234',
    'network': 'Visa',
    'type': 2, // 1=debit, 2=credit, 3=prepaid, 4=store
  },
  'billingContact': {
    'name': {...},
    'postalAddress': {...},
    'emailAddress': '...',
    'phoneNumber': '...',
  },
  'shippingContact': {...},
  'shippingMethod': {...},
}
```

## Backend Integration

The `paymentData` field contains a base64-encoded payment token that must be sent to your payment processor's server. Each processor has different requirements:

### Stripe
Send the payment token to Stripe's API using the `pk_token` parameter.

### Braintree
Use the Braintree SDK on your server to process the Apple Pay token.

### Other Processors
Refer to your payment processor's documentation for Apple Pay integration.

## Troubleshooting

### "Apple Pay is not available"
- Ensure you're testing on a physical device (not simulator)
- Check that the device supports Apple Pay
- Verify iOS version is 13.0 or later

### "No supported cards are set up"
- Add a test card in Wallet & Apple Pay settings
- Ensure the card networks you specify are supported by the user's cards

### "Invalid Merchant ID"
- Double-check your Merchant ID in Apple Developer Portal
- Ensure the Merchant ID in your entitlements file matches the code
- Verify the Merchant ID is enabled for your app bundle identifier

### Certificate Issues
- Ensure you've created and installed the Payment Processing Certificate
- Check that the certificate is not expired
- Verify the certificate is associated with the correct Merchant ID

### Payment Processing Fails
- Check your backend logs for errors
- Verify your payment processor supports Apple Pay
- Ensure you're sending the payment token in the correct format

## Security Best Practices

1. **Never store Apple Pay tokens** - They are single-use and expire quickly
2. **Always use HTTPS** - Payment tokens should only be sent over secure connections
3. **Validate on the server** - Always verify payment tokens on your backend
4. **Handle errors gracefully** - Provide clear feedback to users when payments fail
5. **Test thoroughly** - Test with various card types and scenarios

## Additional Resources

- [Apple Pay Documentation](https://developer.apple.com/apple-pay/)
- [PassKit Framework Reference](https://developer.apple.com/documentation/passkit)
- [Apple Pay Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/apple-pay)
- [Payment Processor Documentation](https://stripe.com/docs/apple-pay) (Stripe example)

## Support

For issues specific to this package, please file an issue on the [GitHub repository](https://github.com/aliumairdev/flutter_pay_kit/issues).

For Apple Pay-related issues, refer to Apple's [technical support resources](https://developer.apple.com/support/).
