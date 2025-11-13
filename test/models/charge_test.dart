import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_universal_payments/src/models/charge.dart';
import 'package:flutter_universal_payments/src/models/enums.dart';

void main() {
  group('Charge', () {
    final testCreatedAt = DateTime(2024, 1, 1);

    group('constructor', () {
      test('creates charge with all required fields', () {
        final charge = Charge(
          id: 'ch_123',
          customerId: 'cus_123',
          amount: 1000,
          currency: 'usd',
          status: ChargeStatus.succeeded,
          refunded: false,
          processorChargeId: 'stripe_ch_123',
          processor: ProcessorType.stripe,
          createdAt: testCreatedAt,
        );

        expect(charge.id, 'ch_123');
        expect(charge.customerId, 'cus_123');
        expect(charge.amount, 1000);
        expect(charge.currency, 'usd');
        expect(charge.status, ChargeStatus.succeeded);
        expect(charge.refunded, false);
        expect(charge.processorChargeId, 'stripe_ch_123');
        expect(charge.processor, ProcessorType.stripe);
        expect(charge.createdAt, testCreatedAt);
      });

      test('creates charge with optional fields', () {
        final charge = Charge(
          id: 'ch_123',
          customerId: 'cus_123',
          amount: 1000,
          currency: 'usd',
          status: ChargeStatus.refunded,
          description: 'Test payment',
          receiptUrl: 'https://example.com/receipt',
          refunded: true,
          refundedAmount: 500,
          processorChargeId: 'stripe_ch_123',
          processor: ProcessorType.stripe,
          createdAt: testCreatedAt,
          metadata: {'order_id': '123'},
        );

        expect(charge.description, 'Test payment');
        expect(charge.receiptUrl, 'https://example.com/receipt');
        expect(charge.refundedAmount, 500);
        expect(charge.metadata, {'order_id': '123'});
      });
    });

    group('JSON serialization', () {
      test('converts to JSON correctly', () {
        final charge = Charge(
          id: 'ch_123',
          customerId: 'cus_123',
          amount: 2500,
          currency: 'eur',
          status: ChargeStatus.succeeded,
          description: 'Premium subscription',
          receiptUrl: 'https://example.com/receipt',
          refunded: false,
          processorChargeId: 'paddle_ch_123',
          processor: ProcessorType.paddle,
          createdAt: testCreatedAt,
          metadata: {'key': 'value'},
        );

        final json = charge.toJson();

        expect(json['id'], 'ch_123');
        expect(json['customer_id'], 'cus_123');
        expect(json['amount'], 2500);
        expect(json['currency'], 'eur');
        expect(json['status'], 'succeeded');
        expect(json['description'], 'Premium subscription');
        expect(json['receipt_url'], 'https://example.com/receipt');
        expect(json['refunded'], false);
        expect(json['processor_charge_id'], 'paddle_ch_123');
        expect(json['processor'], 'paddle');
        expect(json['created_at'], testCreatedAt.toIso8601String());
        expect(json['metadata'], {'key': 'value'});
      });

      test('converts from JSON correctly', () {
        final json = {
          'id': 'ch_123',
          'customer_id': 'cus_123',
          'amount': 3000,
          'currency': 'gbp',
          'status': 'failed',
          'description': 'Failed payment',
          'refunded': false,
          'processor_charge_id': 'bt_ch_123',
          'processor': 'braintree',
          'created_at': testCreatedAt.toIso8601String(),
        };

        final charge = Charge.fromJson(json);

        expect(charge.id, 'ch_123');
        expect(charge.customerId, 'cus_123');
        expect(charge.amount, 3000);
        expect(charge.currency, 'gbp');
        expect(charge.status, ChargeStatus.failed);
        expect(charge.description, 'Failed payment');
        expect(charge.refunded, false);
        expect(charge.processor, ProcessorType.braintree);
      });

      test('handles null optional fields in JSON', () {
        final json = {
          'id': 'ch_123',
          'customer_id': 'cus_123',
          'amount': 1000,
          'currency': 'usd',
          'status': 'succeeded',
          'refunded': false,
          'processor_charge_id': 'stripe_ch_123',
          'processor': 'stripe',
          'created_at': testCreatedAt.toIso8601String(),
        };

        final charge = Charge.fromJson(json);

        expect(charge.description, isNull);
        expect(charge.receiptUrl, isNull);
        expect(charge.refundedAmount, isNull);
        expect(charge.metadata, isNull);
      });

      test('round-trip serialization preserves data', () {
        final original = Charge(
          id: 'ch_123',
          customerId: 'cus_123',
          amount: 1500,
          currency: 'usd',
          status: ChargeStatus.succeeded,
          description: 'Test charge',
          refunded: false,
          processorChargeId: 'ls_ch_123',
          processor: ProcessorType.lemonSqueezy,
          createdAt: testCreatedAt,
          metadata: {'key': 'value'},
        );

        final json = original.toJson();
        final deserialized = Charge.fromJson(json);

        expect(deserialized, equals(original));
      });
    });

    group('copyWith', () {
      test('copies with new values', () {
        final original = Charge(
          id: 'ch_123',
          customerId: 'cus_123',
          amount: 1000,
          currency: 'usd',
          status: ChargeStatus.pending,
          refunded: false,
          processorChargeId: 'stripe_ch_123',
          processor: ProcessorType.stripe,
          createdAt: testCreatedAt,
        );

        final copy = original.copyWith(
          status: ChargeStatus.succeeded,
          description: 'Updated description',
          receiptUrl: 'https://example.com/receipt',
        );

        expect(copy.status, ChargeStatus.succeeded);
        expect(copy.description, 'Updated description');
        expect(copy.receiptUrl, 'https://example.com/receipt');
        expect(copy.id, original.id);
        expect(copy.amount, original.amount);
      });

      test('copies without changes returns equal object', () {
        final original = Charge(
          id: 'ch_123',
          customerId: 'cus_123',
          amount: 1000,
          currency: 'usd',
          status: ChargeStatus.succeeded,
          refunded: false,
          processorChargeId: 'stripe_ch_123',
          processor: ProcessorType.stripe,
          createdAt: testCreatedAt,
        );

        final copy = original.copyWith();

        expect(copy, equals(original));
      });
    });

    group('equality', () {
      test('equals when all fields match', () {
        final charge1 = Charge(
          id: 'ch_123',
          customerId: 'cus_123',
          amount: 1000,
          currency: 'usd',
          status: ChargeStatus.succeeded,
          refunded: false,
          processorChargeId: 'stripe_ch_123',
          processor: ProcessorType.stripe,
          createdAt: testCreatedAt,
        );

        final charge2 = Charge(
          id: 'ch_123',
          customerId: 'cus_123',
          amount: 1000,
          currency: 'usd',
          status: ChargeStatus.succeeded,
          refunded: false,
          processorChargeId: 'stripe_ch_123',
          processor: ProcessorType.stripe,
          createdAt: testCreatedAt,
        );

        expect(charge1, equals(charge2));
        expect(charge1.hashCode, equals(charge2.hashCode));
      });

      test('not equals when fields differ', () {
        final charge1 = Charge(
          id: 'ch_123',
          customerId: 'cus_123',
          amount: 1000,
          currency: 'usd',
          status: ChargeStatus.succeeded,
          refunded: false,
          processorChargeId: 'stripe_ch_123',
          processor: ProcessorType.stripe,
          createdAt: testCreatedAt,
        );

        final charge2 = Charge(
          id: 'ch_456',
          customerId: 'cus_123',
          amount: 1000,
          currency: 'usd',
          status: ChargeStatus.succeeded,
          refunded: false,
          processorChargeId: 'stripe_ch_123',
          processor: ProcessorType.stripe,
          createdAt: testCreatedAt,
        );

        expect(charge1, isNot(equals(charge2)));
      });
    });

    group('refund scenarios', () {
      test('creates fully refunded charge', () {
        final charge = Charge(
          id: 'ch_123',
          customerId: 'cus_123',
          amount: 1000,
          currency: 'usd',
          status: ChargeStatus.refunded,
          refunded: true,
          refundedAmount: 1000,
          processorChargeId: 'stripe_ch_123',
          processor: ProcessorType.stripe,
          createdAt: testCreatedAt,
        );

        expect(charge.refunded, true);
        expect(charge.refundedAmount, 1000);
        expect(charge.status, ChargeStatus.refunded);
      });

      test('creates partially refunded charge', () {
        final charge = Charge(
          id: 'ch_123',
          customerId: 'cus_123',
          amount: 1000,
          currency: 'usd',
          status: ChargeStatus.succeeded,
          refunded: true,
          refundedAmount: 500,
          processorChargeId: 'stripe_ch_123',
          processor: ProcessorType.stripe,
          createdAt: testCreatedAt,
        );

        expect(charge.refunded, true);
        expect(charge.refundedAmount, 500);
        expect(charge.status, ChargeStatus.succeeded);
      });
    });

    group('different currencies', () {
      test('supports various currencies', () {
        final currencies = ['usd', 'eur', 'gbp', 'jpy', 'cad'];

        for (final currency in currencies) {
          final charge = Charge(
            id: 'ch_123',
            customerId: 'cus_123',
            amount: 1000,
            currency: currency,
            status: ChargeStatus.succeeded,
            refunded: false,
            processorChargeId: 'stripe_ch_123',
            processor: ProcessorType.stripe,
            createdAt: testCreatedAt,
          );

          expect(charge.currency, currency);
        }
      });
    });

    group('charge statuses', () {
      test('supports all charge statuses', () {
        for (final status in ChargeStatus.values) {
          final charge = Charge(
            id: 'ch_123',
            customerId: 'cus_123',
            amount: 1000,
            currency: 'usd',
            status: status,
            refunded: false,
            processorChargeId: 'stripe_ch_123',
            processor: ProcessorType.stripe,
            createdAt: testCreatedAt,
          );

          expect(charge.status, status);
        }
      });
    });
  });
}
