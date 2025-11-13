import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_universal_payments/src/models/enums.dart';

void main() {
  group('Enums', () {
    group('ProcessorType', () {
      test('has all expected values', () {
        expect(ProcessorType.values, hasLength(6));
        expect(ProcessorType.values, contains(ProcessorType.stripe));
        expect(ProcessorType.values, contains(ProcessorType.paddle));
        expect(ProcessorType.values, contains(ProcessorType.braintree));
        expect(ProcessorType.values, contains(ProcessorType.lemonSqueezy));
        expect(ProcessorType.values, contains(ProcessorType.totalpayGlobal));
        expect(ProcessorType.values, contains(ProcessorType.fake));
      });

      test('has correct names', () {
        expect(ProcessorType.stripe.name, 'stripe');
        expect(ProcessorType.paddle.name, 'paddle');
        expect(ProcessorType.braintree.name, 'braintree');
        expect(ProcessorType.lemonSqueezy.name, 'lemonSqueezy');
        expect(ProcessorType.totalpayGlobal.name, 'totalpayGlobal');
        expect(ProcessorType.fake.name, 'fake');
      });
    });

    group('PaymentMethodType', () {
      test('has all expected values', () {
        expect(PaymentMethodType.values, hasLength(5));
        expect(PaymentMethodType.values, contains(PaymentMethodType.card));
        expect(PaymentMethodType.values, contains(PaymentMethodType.bankAccount));
        expect(PaymentMethodType.values, contains(PaymentMethodType.paypal));
        expect(PaymentMethodType.values, contains(PaymentMethodType.applePay));
        expect(PaymentMethodType.values, contains(PaymentMethodType.googlePay));
      });

      test('has correct names', () {
        expect(PaymentMethodType.card.name, 'card');
        expect(PaymentMethodType.bankAccount.name, 'bankAccount');
        expect(PaymentMethodType.paypal.name, 'paypal');
        expect(PaymentMethodType.applePay.name, 'applePay');
        expect(PaymentMethodType.googlePay.name, 'googlePay');
      });
    });

    group('SubscriptionStatus', () {
      test('has all expected values', () {
        expect(SubscriptionStatus.values, hasLength(6));
        expect(SubscriptionStatus.values, contains(SubscriptionStatus.active));
        expect(SubscriptionStatus.values, contains(SubscriptionStatus.trialing));
        expect(SubscriptionStatus.values, contains(SubscriptionStatus.pastDue));
        expect(SubscriptionStatus.values, contains(SubscriptionStatus.canceled));
        expect(SubscriptionStatus.values, contains(SubscriptionStatus.incomplete));
        expect(SubscriptionStatus.values, contains(SubscriptionStatus.paused));
      });

      test('has correct names', () {
        expect(SubscriptionStatus.active.name, 'active');
        expect(SubscriptionStatus.trialing.name, 'trialing');
        expect(SubscriptionStatus.pastDue.name, 'pastDue');
        expect(SubscriptionStatus.canceled.name, 'canceled');
        expect(SubscriptionStatus.incomplete.name, 'incomplete');
        expect(SubscriptionStatus.paused.name, 'paused');
      });
    });

    group('ChargeStatus', () {
      test('has all expected values', () {
        expect(ChargeStatus.values, hasLength(4));
        expect(ChargeStatus.values, contains(ChargeStatus.succeeded));
        expect(ChargeStatus.values, contains(ChargeStatus.failed));
        expect(ChargeStatus.values, contains(ChargeStatus.pending));
        expect(ChargeStatus.values, contains(ChargeStatus.refunded));
      });

      test('has correct names', () {
        expect(ChargeStatus.succeeded.name, 'succeeded');
        expect(ChargeStatus.failed.name, 'failed');
        expect(ChargeStatus.pending.name, 'pending');
        expect(ChargeStatus.refunded.name, 'refunded');
      });
    });

    group('BillingInterval', () {
      test('has all expected values', () {
        expect(BillingInterval.values, hasLength(5));
        expect(BillingInterval.values, contains(BillingInterval.day));
        expect(BillingInterval.values, contains(BillingInterval.week));
        expect(BillingInterval.values, contains(BillingInterval.month));
        expect(BillingInterval.values, contains(BillingInterval.year));
        expect(BillingInterval.values, contains(BillingInterval.oneTime));
      });

      test('has correct names', () {
        expect(BillingInterval.day.name, 'day');
        expect(BillingInterval.week.name, 'week');
        expect(BillingInterval.month.name, 'month');
        expect(BillingInterval.year.name, 'year');
        expect(BillingInterval.oneTime.name, 'oneTime');
      });
    });
  });
}
