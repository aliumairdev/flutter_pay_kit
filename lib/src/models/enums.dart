/// Enums for flutter_universal_payments package.
library;

import 'package:json_annotation/json_annotation.dart';

/// Supported payment processors
enum ProcessorType {
  /// Stripe payment processor
  @JsonValue('stripe')
  stripe,

  /// Paddle payment processor
  @JsonValue('paddle')
  paddle,

  /// Braintree payment processor
  @JsonValue('braintree')
  braintree,

  /// Lemon Squeezy payment processor
  @JsonValue('lemon_squeezy')
  lemonSqueezy,

  /// Totalpay Global payment processor
  @JsonValue('totalpay_global')
  totalpayGlobal,

  /// Fake payment processor for testing
  @JsonValue('fake')
  fake,
}

/// Types of payment methods
enum PaymentMethodType {
  /// Credit or debit card
  @JsonValue('card')
  card,

  /// Bank account
  @JsonValue('bank_account')
  bankAccount,

  /// PayPal account
  @JsonValue('paypal')
  paypal,

  /// Apple Pay
  @JsonValue('apple_pay')
  applePay,

  /// Google Pay
  @JsonValue('google_pay')
  googlePay,
}

/// Subscription status values
enum SubscriptionStatus {
  /// Subscription is active and current
  @JsonValue('active')
  active,

  /// Subscription is in trial period
  @JsonValue('trialing')
  trialing,

  /// Subscription payment is past due
  @JsonValue('past_due')
  pastDue,

  /// Subscription has been canceled
  @JsonValue('canceled')
  canceled,

  /// Subscription is incomplete (initial payment failed)
  @JsonValue('incomplete')
  incomplete,

  /// Subscription is paused
  @JsonValue('paused')
  paused,
}

/// Charge/payment status values
enum ChargeStatus {
  /// Charge was successful
  @JsonValue('succeeded')
  succeeded,

  /// Charge failed
  @JsonValue('failed')
  failed,

  /// Charge is pending
  @JsonValue('pending')
  pending,

  /// Charge was refunded
  @JsonValue('refunded')
  refunded,
}

/// Billing interval for recurring charges
enum BillingInterval {
  /// Daily billing
  @JsonValue('day')
  day,

  /// Weekly billing
  @JsonValue('week')
  week,

  /// Monthly billing
  @JsonValue('month')
  month,

  /// Yearly billing
  @JsonValue('year')
  year,

  /// One-time payment (not recurring)
  @JsonValue('one_time')
  oneTime,
}
