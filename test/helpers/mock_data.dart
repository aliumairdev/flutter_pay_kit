/// Mock data factory for testing
library;

import 'package:flutter_universal_payments/src/models/address.dart';
import 'package:flutter_universal_payments/src/models/billing_details.dart';
import 'package:flutter_universal_payments/src/models/charge.dart';
import 'package:flutter_universal_payments/src/models/customer.dart';
import 'package:flutter_universal_payments/src/models/enums.dart';
import 'package:flutter_universal_payments/src/models/payment_method.dart';
import 'package:flutter_universal_payments/src/models/price.dart';
import 'package:flutter_universal_payments/src/models/subscription.dart';
import 'package:flutter_universal_payments/src/models/webhook_event.dart';

/// Mock data factory for creating test objects
class MockData {
  /// Creates a mock address
  static Address mockAddress({
    String? line1,
    String? line2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
  }) {
    return Address(
      line1: line1 ?? '123 Test St',
      line2: line2,
      city: city ?? 'Test City',
      state: state ?? 'TS',
      postalCode: postalCode ?? '12345',
      country: country ?? 'US',
    );
  }

  /// Creates a mock billing details
  static BillingDetails mockBillingDetails({
    String? name,
    String? email,
    String? phone,
    Address? address,
  }) {
    return BillingDetails(
      name: name ?? 'Test User',
      email: email ?? 'test@example.com',
      phone: phone ?? '+1234567890',
      address: address ?? mockAddress(),
    );
  }

  /// Creates a mock customer
  static Customer mockCustomer({
    String? id,
    String? email,
    String? name,
    String? phone,
    ProcessorType? processor,
    String? processorCustomerId,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? 'cus_test123',
      email: email ?? 'test@example.com',
      name: name ?? 'Test User',
      phone: phone,
      processor: processor ?? ProcessorType.stripe,
      processorCustomerId: processorCustomerId ?? 'proc_cus_123',
      metadata: metadata,
      createdAt: createdAt ?? DateTime(2024, 1, 1),
      updatedAt: updatedAt ?? DateTime(2024, 1, 1),
    );
  }

  /// Creates a mock payment method
  static PaymentMethod mockPaymentMethod({
    String? id,
    String? customerId,
    PaymentMethodType? type,
    String? last4,
    String? brand,
    int? expiryMonth,
    int? expiryYear,
    bool? isDefault,
    BillingDetails? billingDetails,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentMethod(
      id: id ?? 'pm_test123',
      customerId: customerId ?? 'cus_test123',
      type: type ?? PaymentMethodType.card,
      last4: last4 ?? '4242',
      brand: brand ?? 'visa',
      expiryMonth: expiryMonth ?? 12,
      expiryYear: expiryYear ?? 2025,
      isDefault: isDefault ?? false,
      billingDetails: billingDetails,
      metadata: metadata,
    );
  }

  /// Creates a mock price
  static Price mockPrice({
    String? id,
    String? productId,
    int? amount,
    String? currency,
    BillingInterval? interval,
    int? intervalCount,
    int? trialDays,
    bool? active,
    String? processorPriceId,
    ProcessorType? processor,
    Map<String, dynamic>? metadata,
  }) {
    return Price(
      id: id ?? 'price_test123',
      productId: productId ?? 'prod_test123',
      amount: amount ?? 1000,
      currency: currency ?? 'usd',
      interval: interval ?? BillingInterval.month,
      intervalCount: intervalCount ?? 1,
      trialDays: trialDays,
      active: active ?? true,
      processorPriceId: processorPriceId ?? 'proc_price_123',
      processor: processor ?? ProcessorType.stripe,
      metadata: metadata,
    );
  }

  /// Creates a mock subscription
  static Subscription mockSubscription({
    String? id,
    String? customerId,
    SubscriptionStatus? status,
    String? priceId,
    String? productId,
    DateTime? currentPeriodStart,
    DateTime? currentPeriodEnd,
    DateTime? trialStart,
    DateTime? trialEnd,
    DateTime? canceledAt,
    bool? cancelAtPeriodEnd,
    int? quantity,
    ProcessorType? processor,
    String? processorSubscriptionId,
    Map<String, dynamic>? metadata,
  }) {
    return Subscription(
      id: id ?? 'sub_test123',
      customerId: customerId ?? 'cus_test123',
      status: status ?? SubscriptionStatus.active,
      priceId: priceId ?? 'price_test123',
      productId: productId ?? 'prod_test123',
      currentPeriodStart: currentPeriodStart ?? DateTime(2024, 1, 1),
      currentPeriodEnd: currentPeriodEnd ?? DateTime(2024, 2, 1),
      trialStart: trialStart,
      trialEnd: trialEnd,
      canceledAt: canceledAt,
      cancelAtPeriodEnd: cancelAtPeriodEnd ?? false,
      quantity: quantity ?? 1,
      processor: processor ?? ProcessorType.stripe,
      processorSubscriptionId: processorSubscriptionId ?? 'proc_sub_123',
      metadata: metadata,
    );
  }

  /// Creates a mock charge
  static Charge mockCharge({
    String? id,
    String? customerId,
    int? amount,
    String? currency,
    ChargeStatus? status,
    String? description,
    String? receiptUrl,
    bool? refunded,
    int? refundedAmount,
    String? processorChargeId,
    ProcessorType? processor,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return Charge(
      id: id ?? 'ch_test123',
      customerId: customerId ?? 'cus_test123',
      amount: amount ?? 1000,
      currency: currency ?? 'usd',
      status: status ?? ChargeStatus.succeeded,
      description: description,
      receiptUrl: receiptUrl,
      refunded: refunded ?? false,
      refundedAmount: refundedAmount,
      processorChargeId: processorChargeId ?? 'proc_ch_123',
      processor: processor ?? ProcessorType.stripe,
      createdAt: createdAt ?? DateTime(2024, 1, 1),
      metadata: metadata,
    );
  }

  /// Creates a mock webhook event
  static WebhookEvent mockWebhookEvent({
    String? id,
    String? type,
    ProcessorType? processor,
    Map<String, dynamic>? data,
    DateTime? createdAt,
  }) {
    return WebhookEvent(
      id: id ?? 'evt_test123',
      type: type ?? 'customer.created',
      processor: processor ?? ProcessorType.stripe,
      data: data ?? {'object': 'customer'},
      createdAt: createdAt ?? DateTime(2024, 1, 1),
    );
  }

  /// Creates a map representation of a customer (for JSON tests)
  static Map<String, dynamic> mockCustomerJson({
    String? id,
    String? email,
    String? name,
  }) {
    return {
      'id': id ?? 'cus_test123',
      'email': email ?? 'test@example.com',
      'name': name ?? 'Test User',
      'metadata': <String, dynamic>{},
      'created': DateTime(2024, 1, 1).toIso8601String(),
    };
  }

  /// Creates a map representation of a payment method (for JSON tests)
  static Map<String, dynamic> mockPaymentMethodJson({
    String? id,
    String? type,
  }) {
    return {
      'id': id ?? 'pm_test123',
      'type': type ?? 'card',
      'last4': '4242',
      'brand': 'visa',
      'expMonth': 12,
      'expYear': 2025,
      'billingDetails': {
        'name': 'Test User',
        'email': 'test@example.com',
        'phone': '+1234567890',
        'address': {
          'line1': '123 Test St',
          'city': 'Test City',
          'state': 'TS',
          'postalCode': '12345',
          'country': 'US',
        },
      },
    };
  }

  /// Creates a map representation of a subscription (for JSON tests)
  static Map<String, dynamic> mockSubscriptionJson({
    String? id,
    String? status,
  }) {
    return {
      'id': id ?? 'sub_test123',
      'customerId': 'cus_test123',
      'status': status ?? 'active',
      'price': {
        'id': 'price_test123',
        'productId': 'prod_test123',
        'unitAmount': 1000,
        'currency': 'usd',
        'interval': 'month',
        'intervalCount': 1,
        'metadata': <String, dynamic>{},
      },
      'currentPeriodStart': DateTime(2024, 1, 1).toIso8601String(),
      'currentPeriodEnd': DateTime(2024, 2, 1).toIso8601String(),
      'metadata': <String, dynamic>{},
    };
  }

  /// Creates a map representation of a charge (for JSON tests)
  static Map<String, dynamic> mockChargeJson({
    String? id,
    int? amount,
    String? status,
  }) {
    return {
      'id': id ?? 'ch_test123',
      'amount': amount ?? 1000,
      'currency': 'usd',
      'status': status ?? 'succeeded',
      'customerId': 'cus_test123',
      'paymentMethodId': 'pm_test123',
      'metadata': <String, dynamic>{},
      'created': DateTime(2024, 1, 1).toIso8601String(),
    };
  }
}
