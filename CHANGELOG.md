# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
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
- Initial package structure
- Core architecture with models, processors, services, widgets, utils, and exceptions
- Support for multiple payment processors:
  - Stripe
  - Paddle
  - Braintree
  - Lemon Squeezy
  - Totalpay Global
- Unified API interface for payment processing
- State management with Riverpod
- Type-safe models using Freezed
- Comprehensive error handling with custom exceptions
- Package configuration and documentation
