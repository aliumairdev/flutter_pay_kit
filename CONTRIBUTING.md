# Contributing to Flutter Universal Payments

First off, thank you for considering contributing to Flutter Universal Payments! It's people like you that make this package better for everyone.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Coding Guidelines](#coding-guidelines)
- [Testing Requirements](#testing-requirements)
- [Pull Request Process](#pull-request-process)
- [Project Structure](#project-structure)
- [Documentation](#documentation)

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to the maintainers.

### Our Standards

- Be respectful and inclusive
- Welcome newcomers and help them learn
- Focus on what is best for the community
- Show empathy towards other community members
- Be patient with questions and discussions

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples** (code snippets, screenshots)
- **Describe the behavior you observed** and what you expected
- **Include your environment details**: Flutter version, Dart version, OS, processor used

**Bug Report Template:**

```markdown
### Description
A clear description of the bug

### Steps to Reproduce
1. Step one
2. Step two
3. Step three

### Expected Behavior
What you expected to happen

### Actual Behavior
What actually happened

### Environment
- Flutter version:
- Dart version:
- OS:
- Processor:
- Package version:

### Code Sample
```dart
// Your code here
```

### Screenshots
If applicable
```

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- **Use a clear and descriptive title**
- **Provide a detailed description** of the proposed enhancement
- **Explain why this enhancement would be useful**
- **List any examples** of how the enhancement would be used
- **Consider if it fits the project's scope**

### Your First Code Contribution

Unsure where to begin? Look for issues labeled:

- `good first issue` - Good for newcomers
- `help wanted` - Extra attention needed
- `documentation` - Documentation improvements

### Pull Requests

We actively welcome your pull requests:

1. Fork the repo and create your branch from `main`
2. If you've added code that should be tested, add tests
3. If you've changed APIs, update the documentation
4. Ensure the test suite passes
5. Make sure your code follows the style guidelines
6. Write a clear commit message

## Development Setup

### Prerequisites

- Flutter SDK 3.10.0 or higher
- Dart SDK 3.0.0 or higher
- Git
- A code editor (VS Code, Android Studio, IntelliJ IDEA)

### Setting Up Your Development Environment

1. **Fork and Clone**

   ```bash
   git clone https://github.com/YOUR_USERNAME/flutter_pay_kit.git
   cd flutter_pay_kit
   ```

2. **Install Dependencies**

   ```bash
   flutter pub get
   ```

3. **Run Code Generation**

   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Verify Setup**

   ```bash
   flutter test
   ```

### Running the Example App

```bash
cd example
flutter run
```

### Making Changes

1. **Create a Branch**

   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

2. **Make Your Changes**

   - Write clean, readable code
   - Follow the coding guidelines below
   - Add tests for new functionality
   - Update documentation

3. **Test Your Changes**

   ```bash
   # Run all tests
   flutter test

   # Run specific test
   flutter test test/services/payment_service_test.dart

   # Run with coverage
   flutter test --coverage
   ```

4. **Commit Your Changes**

   ```bash
   git add .
   git commit -m "feat: add new feature"
   ```

   Follow [Conventional Commits](https://www.conventionalcommits.org/):
   - `feat:` New feature
   - `fix:` Bug fix
   - `docs:` Documentation changes
   - `style:` Code style changes (formatting)
   - `refactor:` Code refactoring
   - `test:` Adding or updating tests
   - `chore:` Maintenance tasks

## Coding Guidelines

### Dart Style Guide

We follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style) with these additions:

#### Code Formatting

- Use `dart format` to format your code
- Maximum line length: 80 characters
- Use 2 spaces for indentation

```bash
# Format all Dart files
dart format lib/ test/
```

#### Naming Conventions

```dart
// Classes: UpperCamelCase
class PaymentProcessor {}

// Functions and variables: lowerCamelCase
void processPayment() {}
final String apiKey = '...';

// Constants: lowerCamelCase
const int maxRetries = 3;

// Private members: leading underscore
String _privateField;
void _privateMethod() {}

// Enums: UpperCamelCase
enum ProcessorType { stripe, paddle }
```

#### Documentation

Every public API must have dartdoc comments:

```dart
/// Creates a new subscription for the customer.
///
/// This method creates a subscription with the specified [priceId] and
/// optionally attaches a payment method. If [trialDays] is specified,
/// the customer won't be charged until the trial ends.
///
/// Example:
/// ```dart
/// final subscription = await service.subscribe(
///   priceId: 'price_monthly',
///   trialDays: 14,
/// );
/// ```
///
/// Throws:
/// * [ProcessorException] if the processor API fails
/// * [ValidationException] if parameters are invalid
/// * [AuthenticationException] if API credentials are invalid
Future<Subscription> subscribe({
  required String priceId,
  String? paymentMethodToken,
  int? trialDays,
}) async {
  // Implementation
}
```

#### Error Handling

- Use specific exception types
- Provide helpful error messages
- Include error codes when possible

```dart
// ✅ Good
throw ProcessorException(
  'Failed to create subscription',
  code: 'subscription_creation_failed',
  details: {'reason': 'Invalid price ID'},
);

// ❌ Bad
throw Exception('Error');
```

#### Null Safety

- Use null safety properly
- Prefer non-nullable types
- Use nullable types only when necessary

```dart
// ✅ Good
Future<Customer> getCustomer() async {
  final customer = await _fetchCustomer();
  if (customer == null) {
    throw CustomerNotFoundException('Customer not found');
  }
  return customer;
}

// ✅ Also good
Future<Customer?> getCustomerOrNull() async {
  return await _fetchCustomer();
}
```

### Architecture Guidelines

- **Single Responsibility**: Each class should have one clear purpose
- **Dependency Injection**: Use constructor injection
- **Interface Segregation**: Define clear interfaces
- **Immutability**: Prefer immutable models (use Freezed)

```dart
// ✅ Good: Clear separation of concerns
class PaymentService {
  final PaymentProcessor _processor;
  final Storage _storage;

  PaymentService({
    required PaymentProcessor processor,
    required Storage storage,
  }) : _processor = processor,
       _storage = storage;
}

// ❌ Bad: Too many responsibilities
class PaymentService {
  void processPayment() {}
  void sendEmail() {}
  void logEvent() {}
  void updateUI() {}
}
```

## Testing Requirements

### Test Coverage

- All new features must include tests
- Aim for >80% code coverage
- Test both success and failure scenarios

### Test Structure

```dart
void main() {
  group('PaymentService', () {
    late PaymentService service;
    late MockPaymentProcessor mockProcessor;
    late Storage storage;

    setUp(() {
      mockProcessor = MockPaymentProcessor();
      storage = InMemoryStorage();
      service = PaymentService(
        processor: mockProcessor,
        storage: storage,
      );
    });

    group('subscribe', () {
      test('creates subscription successfully', () async {
        // Arrange
        when(() => mockProcessor.createSubscription(...))
            .thenAnswer((_) async => subscription);

        // Act
        final result = await service.subscribe(priceId: 'price_123');

        // Assert
        expect(result, subscription);
        verify(() => mockProcessor.createSubscription(...)).called(1);
      });

      test('throws ProcessorException on API failure', () async {
        // Arrange
        when(() => mockProcessor.createSubscription(...))
            .thenThrow(ProcessorException('API error'));

        // Act & Assert
        expect(
          () => service.subscribe(priceId: 'price_123'),
          throwsA(isA<ProcessorException>()),
        );
      });
    });
  });
}
```

### Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/services/payment_service_test.dart

# Run tests matching pattern
flutter test --name="subscribe"
```

### Test Types

1. **Unit Tests**: Test individual functions and classes
2. **Widget Tests**: Test UI components
3. **Integration Tests**: Test complete flows

## Pull Request Process

### Before Submitting

- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] Tests added/updated
- [ ] All tests pass
- [ ] No new warnings
- [ ] Example app works with changes

### PR Template

```markdown
## Description
Brief description of the changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
Describe the tests you ran

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-reviewed code
- [ ] Commented complex code
- [ ] Updated documentation
- [ ] Added tests
- [ ] All tests pass
- [ ] No new warnings

## Screenshots (if applicable)
Add screenshots to show changes
```

### Review Process

1. Maintainer will review your PR
2. Changes may be requested
3. Once approved, PR will be merged
4. Your contribution will be credited

### After Your PR is Merged

- Delete your branch
- Update your fork
- Celebrate! 🎉

## Project Structure

```
flutter_pay_kit/
├── lib/
│   ├── src/
│   │   ├── models/          # Data models
│   │   ├── processors/      # Payment processor implementations
│   │   ├── services/        # Business logic
│   │   ├── widgets/         # UI components
│   │   ├── utils/           # Utilities (logging, analytics)
│   │   └── exceptions/      # Custom exceptions
│   └── flutter_universal_payments.dart  # Public API
├── test/                    # Tests
├── example/                 # Example app
├── doc/                     # Documentation
└── pubspec.yaml
```

### Key Files

- `lib/flutter_universal_payments.dart` - Main export file
- `lib/src/services/payment_service.dart` - Core payment service
- `lib/src/processors/payment_processor.dart` - Processor interface

## Documentation

### Documentation Requirements

- All public APIs must have dartdoc comments
- Include examples in documentation
- Update README.md for new features
- Add entries to CHANGELOG.md
- Update migration guides for breaking changes

### Writing Good Documentation

```dart
/// Short one-line summary.
///
/// More detailed explanation if needed. Can span multiple paragraphs.
///
/// Use code examples:
/// ```dart
/// final result = await myFunction(param: 'value');
/// print(result);
/// ```
///
/// Document parameters:
/// * [param1] - Description of param1
/// * [param2] - Description of param2
///
/// Returns description of what's returned.
///
/// Throws:
/// * [ExceptionType] when condition occurs
///
/// See also:
/// * [RelatedClass] for related functionality
```

## Getting Help

- **Questions**: Open a [GitHub Discussion](https://github.com/aliumairdev/flutter_pay_kit/discussions)
- **Bugs**: Open a [GitHub Issue](https://github.com/aliumairdev/flutter_pay_kit/issues)
- **Chat**: Join our community (link TBD)

## Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes
- Package credits

Thank you for contributing! 🚀
