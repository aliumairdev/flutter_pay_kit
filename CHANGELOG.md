# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive package documentation
  - Getting started guide with detailed setup instructions for each processor
  - Processor-specific integration guides (Stripe, Paddle, Braintree, Lemon Squeezy, Totalpay)
  - Widget documentation with examples and customization options
  - Advanced usage guide covering webhooks, custom processors, and best practices
  - Contributing guidelines
  - Example code snippets for common use cases
- Native Android Google Pay integration
  - `GooglePayHandler` for platform channel communication
  - `GooglePayConfig` for easy configuration
  - Native Kotlin implementation (`FlutterUniversalPaymentsPlugin.kt`)
  - Support for both TEST and PRODUCTION environments
  - Comprehensive error handling and validation
  - Example app demonstrating Google Pay usage
  - Detailed integration guide (GOOGLE_PAY_INTEGRATION.md)

## [0.1.0] - 2025-11-13

### Added
- Initial release of Flutter Universal Payments
- Support for 6 payment processors:
  - Stripe integration with full API support
  - Paddle integration for SaaS billing
  - Braintree integration with PayPal support
  - Lemon Squeezy integration for digital products
  - Totalpay Global for international payments
  - Fake processor for testing and development
- Core payment features:
  - Customer management (create, update, delete)
  - Payment method handling (add, remove, set default)
  - Subscription management (create, update, cancel, resume)
  - One-time payment processing
  - Plan swapping with proration
  - Trial period support
- Payment models with Freezed:
  - Customer model with metadata support
  - Subscription model with status tracking
  - Charge model for one-time payments
  - PaymentMethod model with card details
  - Price model for subscription plans
  - WebhookEvent model for webhook handling
- Comprehensive exception hierarchy:
  - PaymentException (base exception)
  - AuthenticationException
  - ProcessorException
  - ValidationException
  - NetworkException
  - CustomerNotFoundException
  - SubscriptionNotFoundException
  - PaymentMethodException
  - WebhookException
  - InvalidConfigurationException
- Six pre-built UI widgets:
  - PaymentCardInput with real-time validation and card brand detection
  - PricingTable with multiple layout options (list, grid, row)
  - SubscriptionCard for displaying subscription details
  - SubscriptionStatusWidget for status indicators
  - PaymentMethodTile for payment method display
  - PaymentLoadingIndicator for payment processing states
- Payment service features:
  - Singleton service architecture
  - Automatic caching with Storage abstraction
  - Retry logic with exponential backoff
  - Webhook signature verification
  - Runtime processor switching
- Logging and analytics:
  - PaymentLogger with configurable log levels
  - Sensitive data masking for PCI compliance
  - Analytics provider interface
  - Firebase Analytics integration example
  - Sentry integration example
  - Firebase Crashlytics integration example
- State management:
  - Riverpod integration with pre-configured providers
  - Reactive state updates
  - Provider-based architecture
- Storage layer:
  - Abstract Storage interface
  - Secure storage support
  - Cache management
  - Automatic retry logic
- Testing utilities:
  - Fake processor with configurable delays
  - Configurable failure rates for testing
  - In-memory storage implementation
  - Mock-friendly architecture
- Comprehensive test suite:
  - Unit tests for all services
  - Widget tests for UI components
  - Integration tests
  - Mock processor for testing
- Complete example app:
  - Home screen with feature overview
  - Pricing screen with plan selection
  - Subscription management screen
  - Payment processing screen
  - Settings and configuration
  - Sample plans and test data
- Documentation:
  - README with quick start guide
  - API documentation with dartdoc
  - Inline code examples
  - Architecture overview

### Features by Processor

#### Stripe
- Full REST API v1 support
- Webhook signature verification
- Idempotency key support
- Test mode with test cards
- 3D Secure authentication

#### Paddle
- Sandbox and production environments
- Vendor authentication
- Multi-currency support
- Automatic tax calculation
- Webhook signing

#### Braintree
- PayPal integration
- Merchant account support
- Sandbox testing
- Fraud protection
- Multiple payment methods

#### Lemon Squeezy
- Store-based configuration
- Digital product sales
- License key management
- Customer portal
- Webhook events

#### Totalpay
- International payments
- Multi-currency support (150+ currencies)
- Sandbox environment
- Risk management
- Batch processing

#### Fake Processor
- Simulated delays
- Configurable failure rates
- All operations supported
- Perfect for development
- No external dependencies

### Technical Details
- Dart SDK: >=3.0.0 <4.0.0
- Flutter SDK: >=3.10.0
- Uses Freezed for immutable models
- Uses Riverpod for state management
- Uses Dio for HTTP requests
- Uses SharedPreferences for caching
- Uses FlutterSecureStorage for secure data

---

## Migration Guides

### Upgrading to 0.1.0 from pre-release

This is the first stable release. No migration needed.

---

## Known Issues

### Version 0.1.0
- Some processors may have rate limits affecting high-volume applications
- Webhook signature verification requires proper server setup
- Test mode behavior may vary slightly between processors

Report issues at: https://github.com/aliumairdev/flutter_pay_kit/issues

---

## Roadmap

See [README.md](README.md#roadmap) for upcoming features:
- Apple Pay support
- Google Pay support
- PayPal direct integration
- Cryptocurrency payments
- Invoice generation
- Multi-currency support
- Tax calculation integration

---

[Unreleased]: https://github.com/aliumairdev/flutter_pay_kit/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/aliumairdev/flutter_pay_kit/releases/tag/v0.1.0
