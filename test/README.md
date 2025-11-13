# Flutter Universal Payments - Test Suite

This directory contains comprehensive unit, widget, and integration tests for the Flutter Universal Payments package.

## Test Structure

```
test/
├── helpers/              # Test helpers and mocks
│   ├── mock_data.dart   # Mock data factories for all models
│   ├── mocks.dart       # Mock classes using mocktail
│   └── test_helpers.dart # Helper functions for testing
├── models/              # Model tests
│   ├── address_test.dart
│   ├── billing_details_test.dart
│   ├── charge_test.dart
│   ├── customer_test.dart
│   ├── enums_test.dart
│   ├── payment_method_test.dart
│   ├── price_test.dart
│   ├── subscription_test.dart
│   └── webhook_event_test.dart
├── exceptions/          # Exception tests
│   └── exceptions_test.dart
├── services/            # Service layer tests
│   ├── storage_test.dart
│   ├── configuration_test.dart (to be created)
│   └── payment_service_test.dart (to be created)
├── processors/          # Processor tests
│   ├── stripe_processor_test.dart
│   ├── paddle_processor_test.dart (to be created)
│   ├── braintree_processor_test.dart (to be created)
│   ├── lemon_squeezy_processor_test.dart (to be created)
│   ├── totalpay_processor_test.dart (to be created)
│   └── fake_processor_test.dart (to be created)
├── widgets/             # Widget tests
│   ├── payment_card_input_test.dart (to be created)
│   ├── payment_method_tile_test.dart (to be created)
│   ├── subscription_card_test.dart (to be created)
│   └── ... (other widget tests)
├── integration/         # Integration tests
│   └── payment_flow_test.dart (to be created)
└── README.md           # This file
```

## Test Coverage

### Completed ✅

#### Models (9 classes - 100% coverage)
- **Address**: JSON serialization, copyWith, equality, null handling
- **BillingDetails**: All fields, nested objects, serialization
- **Charge**: Status transitions, refunds, currency handling
- **Customer**: Processor types, metadata, timestamps
- **Enums**: All enum values and names
- **PaymentMethod**: Types, card details, default status
- **Price**: Billing intervals, trial periods, active status
- **Subscription**: Computed properties (isActive, isOnTrial, isOnGracePeriod, daysUntilDue)
- **WebhookEvent**: Event types, processors, nested data structures

#### Exceptions (10 classes - 100% coverage)
- **PaymentException**: Base class functionality
- **ProcessorException**: Processor-specific errors
- **AuthenticationException**: Auth failures
- **NetworkException**: Network errors with status codes
- **ValidationException**: Field validation errors
- **CustomerNotFoundException**: Customer lookup failures
- **SubscriptionNotFoundException**: Subscription lookup failures
- **PaymentMethodException**: Payment method errors
- **WebhookException**: Webhook processing errors
- **InvalidConfigurationException**: Configuration errors

#### Services
- **Storage**: SharedPreferences and SecureStorage implementations ✅
- **CachedData**: Cache metadata and expiration ✅
- **StorageException**: Storage error handling ✅

#### Processors
- **StripeProcessor**: Sample implementation showing testing patterns ✅
  - Customer creation
  - Subscription creation
  - Charge creation
  - Error handling
  - Authentication errors
  - Network errors

### To Be Extended

#### Additional Processor Tests
Following the Stripe pattern in `stripe_processor_test.dart`, create tests for:
- **PaddleProcessor**
- **BraintreeProcessor**
- **LemonSqueezyProcessor**
- **TotalpayProcessor**
- **FakeProcessor** (for testing)

Each processor test should cover:
- Initialization and configuration
- Customer operations (create, retrieve, update, delete)
- Subscription operations (create, cancel, update, retrieve)
- Payment operations (create charge, refund)
- Webhook verification
- Error handling for all processor-specific errors
- Authentication failures
- Network failures
- API request formatting
- Response mapping

#### Widget Tests
Create widget tests for:
- **PaymentCardInput**: Card number validation, expiry, CVV
- **PaymentMethodTile**: Display, selection, deletion
- **SubscriptionCard**: Status display, actions
- **PricingTable**: Plan selection, intervals
- **PaymentLoadingIndicator**: States
- **SubscriptionStatusWidget**: Status badges

#### Integration Tests
Create end-to-end tests for:
- Complete payment flows
- Subscription lifecycle
- Payment method management
- Webhook processing
- Processor switching
- Cache management

## Running Tests

### Run all tests
```bash
flutter test
```

### Run specific test file
```bash
flutter test test/models/customer_test.dart
```

### Run tests with coverage
```bash
flutter test --coverage
```

### View coverage report
```bash
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Test Patterns and Best Practices

### 1. Model Tests

Model tests should cover:
- Constructor with all required and optional fields
- JSON serialization (toJson)
- JSON deserialization (fromJson)
- Round-trip serialization
- copyWith functionality
- Equality comparison
- HashCode consistency
- Computed properties (if any)
- Edge cases and null values

Example:
```dart
test('creates customer with all fields', () {
  final customer = Customer(
    id: 'cus_123',
    email: 'test@example.com',
    // ... all fields
  );

  expect(customer.id, 'cus_123');
  expect(customer.email, 'test@example.com');
});
```

### 2. Processor Tests

Processor tests should use `mocktail` to mock HTTP clients:
```dart
late MockDio mockDio;
late StripeProcessor processor;

setUp(() {
  mockDio = MockDio();
  processor = StripeProcessor(
    publishableKey: 'pk_test_123',
    secretKey: 'sk_test_123',
    dio: mockDio,
  );
});

test('creates customer successfully', () async {
  when(() => mockDio.post(any(), data: any(named: 'data')))
      .thenAnswer((_) async => createSuccessResponse({...}));

  final customer = await processor.createCustomer(email: 'test@example.com');

  expect(customer.email, 'test@example.com');
  verify(() => mockDio.post(any(), data: any(named: 'data'))).called(1);
});
```

### 3. Service Tests

Service tests should:
- Mock dependencies (processors, storage)
- Test caching behavior
- Test retry logic
- Test error handling
- Test state management

### 4. Widget Tests

Widget tests should:
- Use `testWidgets` function
- Pump widgets with necessary providers
- Test user interactions
- Test validation
- Test error states
- Test loading states

Example:
```dart
testWidgets('shows validation error for invalid card', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PaymentCardInput(
          onCardChanged: (_) {},
        ),
      ),
    ),
  );

  await tester.enterText(find.byType(TextField), '1234');
  await tester.pump();

  expect(find.text('Invalid card number'), findsOneWidget);
});
```

## Test Helpers

### MockData
Factory class for creating test data:
```dart
final customer = MockData.mockCustomer(
  id: 'cus_123',
  email: 'test@example.com',
);
```

### Mocks
Mock classes for testing:
- `MockDio` - HTTP client
- `MockHttpClient` - Alternative HTTP client
- `MockSharedPreferences` - Local storage
- `MockFlutterSecureStorage` - Secure storage
- `MockBaseProcessor` - Processor interface

### Test Helpers
Utility functions:
- `createSuccessResponse()` - Creates successful Dio responses
- `createDioException()` - Creates Dio errors
- `createNetworkError()` - Creates network errors

## Coverage Goals

- **Models**: 100% ✅
- **Exceptions**: 100% ✅
- **Services**: >90% (currently ~70%)
- **Processors**: >85% (currently ~15% - sample only)
- **Widgets**: >80% (not yet created)
- **Overall**: >80%

## Contributing Tests

When adding tests:
1. Follow the existing patterns
2. Use descriptive test names
3. Group related tests
4. Test both success and failure cases
5. Mock external dependencies
6. Use `setUp` and `tearDown` appropriately
7. Add tests for edge cases
8. Document complex test scenarios

## Dependencies

Testing dependencies (already in `pubspec.yaml`):
- `flutter_test`: Flutter testing framework
- `mocktail`: ^1.0.3 - Mocking library
- `build_runner`: ^2.4.8 - Code generation (for mocks)

## Notes

- All processors should follow the pattern in `stripe_processor_test.dart`
- Use `MockData` helpers for consistent test data
- Always test error scenarios
- Widget tests should use golden files where appropriate
- Integration tests should use `FakeProcessor` for predictable results
