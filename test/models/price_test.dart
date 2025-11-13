import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_universal_payments/src/models/enums.dart';
import 'package:flutter_universal_payments/src/models/price.dart';

void main() {
  group('Price', () {
    group('constructor', () {
      test('creates price with all required fields', () {
        final price = Price(
          id: 'price_123',
          productId: 'prod_123',
          amount: 1000,
          currency: 'usd',
          interval: BillingInterval.month,
          intervalCount: 1,
          active: true,
          processorPriceId: 'stripe_price_123',
          processor: ProcessorType.stripe,
        );

        expect(price.id, 'price_123');
        expect(price.productId, 'prod_123');
        expect(price.amount, 1000);
        expect(price.currency, 'usd');
        expect(price.interval, BillingInterval.month);
        expect(price.intervalCount, 1);
        expect(price.active, true);
        expect(price.processorPriceId, 'stripe_price_123');
        expect(price.processor, ProcessorType.stripe);
      });

      test('creates price with optional fields', () {
        final price = Price(
          id: 'price_123',
          productId: 'prod_123',
          amount: 2000,
          currency: 'usd',
          interval: BillingInterval.year,
          intervalCount: 1,
          trialDays: 14,
          active: true,
          processorPriceId: 'stripe_price_123',
          processor: ProcessorType.stripe,
          metadata: {'tier': 'premium'},
        );

        expect(price.trialDays, 14);
        expect(price.metadata, {'tier': 'premium'});
      });
    });

    group('JSON serialization', () {
      test('converts to JSON correctly', () {
        final price = Price(
          id: 'price_123',
          productId: 'prod_123',
          amount: 1500,
          currency: 'eur',
          interval: BillingInterval.month,
          intervalCount: 3,
          trialDays: 7,
          active: true,
          processorPriceId: 'paddle_price_123',
          processor: ProcessorType.paddle,
          metadata: {'key': 'value'},
        );

        final json = price.toJson();

        expect(json['id'], 'price_123');
        expect(json['product_id'], 'prod_123');
        expect(json['amount'], 1500);
        expect(json['currency'], 'eur');
        expect(json['interval'], 'month');
        expect(json['interval_count'], 3);
        expect(json['trial_days'], 7);
        expect(json['active'], true);
        expect(json['processor_price_id'], 'paddle_price_123');
        expect(json['processor'], 'paddle');
        expect(json['metadata'], {'key': 'value'});
      });

      test('converts from JSON correctly', () {
        final json = {
          'id': 'price_123',
          'product_id': 'prod_123',
          'amount': 2500,
          'currency': 'gbp',
          'interval': 'year',
          'interval_count': 1,
          'active': false,
          'processor_price_id': 'bt_price_123',
          'processor': 'braintree',
        };

        final price = Price.fromJson(json);

        expect(price.id, 'price_123');
        expect(price.productId, 'prod_123');
        expect(price.amount, 2500);
        expect(price.currency, 'gbp');
        expect(price.interval, BillingInterval.year);
        expect(price.intervalCount, 1);
        expect(price.active, false);
        expect(price.processor, ProcessorType.braintree);
      });

      test('handles null optional fields in JSON', () {
        final json = {
          'id': 'price_123',
          'product_id': 'prod_123',
          'amount': 1000,
          'currency': 'usd',
          'interval': 'month',
          'interval_count': 1,
          'active': true,
          'processor_price_id': 'stripe_price_123',
          'processor': 'stripe',
        };

        final price = Price.fromJson(json);

        expect(price.trialDays, isNull);
        expect(price.metadata, isNull);
      });

      test('round-trip serialization preserves data', () {
        final original = Price(
          id: 'price_123',
          productId: 'prod_123',
          amount: 1000,
          currency: 'usd',
          interval: BillingInterval.month,
          intervalCount: 1,
          trialDays: 30,
          active: true,
          processorPriceId: 'ls_price_123',
          processor: ProcessorType.lemonSqueezy,
          metadata: {'key': 'value'},
        );

        final json = original.toJson();
        final deserialized = Price.fromJson(json);

        expect(deserialized, equals(original));
      });
    });

    group('copyWith', () {
      test('copies with new values', () {
        final original = Price(
          id: 'price_123',
          productId: 'prod_123',
          amount: 1000,
          currency: 'usd',
          interval: BillingInterval.month,
          intervalCount: 1,
          active: true,
          processorPriceId: 'stripe_price_123',
          processor: ProcessorType.stripe,
        );

        final copy = original.copyWith(
          amount: 2000,
          trialDays: 14,
          active: false,
        );

        expect(copy.amount, 2000);
        expect(copy.trialDays, 14);
        expect(copy.active, false);
        expect(copy.id, original.id);
        expect(copy.productId, original.productId);
      });

      test('copies without changes returns equal object', () {
        final original = Price(
          id: 'price_123',
          productId: 'prod_123',
          amount: 1000,
          currency: 'usd',
          interval: BillingInterval.month,
          intervalCount: 1,
          active: true,
          processorPriceId: 'stripe_price_123',
          processor: ProcessorType.stripe,
        );

        final copy = original.copyWith();

        expect(copy, equals(original));
      });
    });

    group('equality', () {
      test('equals when all fields match', () {
        final price1 = Price(
          id: 'price_123',
          productId: 'prod_123',
          amount: 1000,
          currency: 'usd',
          interval: BillingInterval.month,
          intervalCount: 1,
          active: true,
          processorPriceId: 'stripe_price_123',
          processor: ProcessorType.stripe,
        );

        final price2 = Price(
          id: 'price_123',
          productId: 'prod_123',
          amount: 1000,
          currency: 'usd',
          interval: BillingInterval.month,
          intervalCount: 1,
          active: true,
          processorPriceId: 'stripe_price_123',
          processor: ProcessorType.stripe,
        );

        expect(price1, equals(price2));
        expect(price1.hashCode, equals(price2.hashCode));
      });

      test('not equals when fields differ', () {
        final price1 = Price(
          id: 'price_123',
          productId: 'prod_123',
          amount: 1000,
          currency: 'usd',
          interval: BillingInterval.month,
          intervalCount: 1,
          active: true,
          processorPriceId: 'stripe_price_123',
          processor: ProcessorType.stripe,
        );

        final price2 = Price(
          id: 'price_456',
          productId: 'prod_123',
          amount: 1000,
          currency: 'usd',
          interval: BillingInterval.month,
          intervalCount: 1,
          active: true,
          processorPriceId: 'stripe_price_123',
          processor: ProcessorType.stripe,
        );

        expect(price1, isNot(equals(price2)));
      });
    });

    group('billing intervals', () {
      test('supports all billing intervals', () {
        for (final interval in BillingInterval.values) {
          final price = Price(
            id: 'price_123',
            productId: 'prod_123',
            amount: 1000,
            currency: 'usd',
            interval: interval,
            intervalCount: 1,
            active: true,
            processorPriceId: 'stripe_price_123',
            processor: ProcessorType.stripe,
          );

          expect(price.interval, interval);
        }
      });

      test('creates monthly price', () {
        final price = Price(
          id: 'price_123',
          productId: 'prod_123',
          amount: 1000,
          currency: 'usd',
          interval: BillingInterval.month,
          intervalCount: 1,
          active: true,
          processorPriceId: 'stripe_price_123',
          processor: ProcessorType.stripe,
        );

        expect(price.interval, BillingInterval.month);
        expect(price.intervalCount, 1);
      });

      test('creates quarterly price', () {
        final price = Price(
          id: 'price_123',
          productId: 'prod_123',
          amount: 3000,
          currency: 'usd',
          interval: BillingInterval.month,
          intervalCount: 3,
          active: true,
          processorPriceId: 'stripe_price_123',
          processor: ProcessorType.stripe,
        );

        expect(price.interval, BillingInterval.month);
        expect(price.intervalCount, 3);
      });

      test('creates yearly price', () {
        final price = Price(
          id: 'price_123',
          productId: 'prod_123',
          amount: 10000,
          currency: 'usd',
          interval: BillingInterval.year,
          intervalCount: 1,
          active: true,
          processorPriceId: 'stripe_price_123',
          processor: ProcessorType.stripe,
        );

        expect(price.interval, BillingInterval.year);
        expect(price.intervalCount, 1);
      });

      test('creates one-time price', () {
        final price = Price(
          id: 'price_123',
          productId: 'prod_123',
          amount: 5000,
          currency: 'usd',
          interval: BillingInterval.oneTime,
          intervalCount: 1,
          active: true,
          processorPriceId: 'stripe_price_123',
          processor: ProcessorType.stripe,
        );

        expect(price.interval, BillingInterval.oneTime);
      });
    });

    group('trial periods', () {
      test('creates price with trial period', () {
        final price = Price(
          id: 'price_123',
          productId: 'prod_123',
          amount: 1000,
          currency: 'usd',
          interval: BillingInterval.month,
          intervalCount: 1,
          trialDays: 14,
          active: true,
          processorPriceId: 'stripe_price_123',
          processor: ProcessorType.stripe,
        );

        expect(price.trialDays, 14);
      });

      test('creates price without trial period', () {
        final price = Price(
          id: 'price_123',
          productId: 'prod_123',
          amount: 1000,
          currency: 'usd',
          interval: BillingInterval.month,
          intervalCount: 1,
          active: true,
          processorPriceId: 'stripe_price_123',
          processor: ProcessorType.stripe,
        );

        expect(price.trialDays, isNull);
      });
    });

    group('active status', () {
      test('creates active price', () {
        final price = Price(
          id: 'price_123',
          productId: 'prod_123',
          amount: 1000,
          currency: 'usd',
          interval: BillingInterval.month,
          intervalCount: 1,
          active: true,
          processorPriceId: 'stripe_price_123',
          processor: ProcessorType.stripe,
        );

        expect(price.active, true);
      });

      test('creates inactive price', () {
        final price = Price(
          id: 'price_123',
          productId: 'prod_123',
          amount: 1000,
          currency: 'usd',
          interval: BillingInterval.month,
          intervalCount: 1,
          active: false,
          processorPriceId: 'stripe_price_123',
          processor: ProcessorType.stripe,
        );

        expect(price.active, false);
      });
    });
  });
}
