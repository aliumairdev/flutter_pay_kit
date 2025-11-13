import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_universal_payments/src/models/enums.dart';
import 'package:flutter_universal_payments/src/models/webhook_event.dart';

void main() {
  group('WebhookEvent', () {
    final testCreatedAt = DateTime(2024, 1, 1);

    group('constructor', () {
      test('creates webhook event with all fields', () {
        final event = WebhookEvent(
          id: 'evt_123',
          type: 'customer.created',
          processor: ProcessorType.stripe,
          data: {'customer_id': 'cus_123'},
          createdAt: testCreatedAt,
        );

        expect(event.id, 'evt_123');
        expect(event.type, 'customer.created');
        expect(event.processor, ProcessorType.stripe);
        expect(event.data, {'customer_id': 'cus_123'});
        expect(event.createdAt, testCreatedAt);
      });

      test('creates webhook event with complex data', () {
        final event = WebhookEvent(
          id: 'evt_123',
          type: 'subscription.updated',
          processor: ProcessorType.paddle,
          data: {
            'subscription': {
              'id': 'sub_123',
              'status': 'active',
              'customer_id': 'cus_123',
            },
          },
          createdAt: testCreatedAt,
        );

        expect(event.data, isA<Map<String, dynamic>>());
        expect(event.data['subscription'], isA<Map<String, dynamic>>());
      });
    });

    group('JSON serialization', () {
      test('converts to JSON correctly', () {
        final event = WebhookEvent(
          id: 'evt_123',
          type: 'charge.succeeded',
          processor: ProcessorType.braintree,
          data: {'charge_id': 'ch_123', 'amount': 1000},
          createdAt: testCreatedAt,
        );

        final json = event.toJson();

        expect(json['id'], 'evt_123');
        expect(json['type'], 'charge.succeeded');
        expect(json['processor'], 'braintree');
        expect(json['data'], {'charge_id': 'ch_123', 'amount': 1000});
        expect(json['created_at'], testCreatedAt.toIso8601String());
      });

      test('converts from JSON correctly', () {
        final json = {
          'id': 'evt_456',
          'type': 'payment_method.attached',
          'processor': 'lemon_squeezy',
          'data': {'payment_method_id': 'pm_123'},
          'created_at': testCreatedAt.toIso8601String(),
        };

        final event = WebhookEvent.fromJson(json);

        expect(event.id, 'evt_456');
        expect(event.type, 'payment_method.attached');
        expect(event.processor, ProcessorType.lemonSqueezy);
        expect(event.data, {'payment_method_id': 'pm_123'});
        expect(event.createdAt, testCreatedAt);
      });

      test('round-trip serialization preserves data', () {
        final original = WebhookEvent(
          id: 'evt_123',
          type: 'invoice.payment_failed',
          processor: ProcessorType.totalpayGlobal,
          data: {
            'invoice_id': 'inv_123',
            'amount_due': 5000,
            'customer': {'id': 'cus_123', 'email': 'test@example.com'},
          },
          createdAt: testCreatedAt,
        );

        final json = original.toJson();
        final deserialized = WebhookEvent.fromJson(json);

        expect(deserialized, equals(original));
      });

      test('handles empty data map', () {
        final event = WebhookEvent(
          id: 'evt_123',
          type: 'ping',
          processor: ProcessorType.stripe,
          data: {},
          createdAt: testCreatedAt,
        );

        final json = event.toJson();
        final deserialized = WebhookEvent.fromJson(json);

        expect(deserialized.data, isEmpty);
      });
    });

    group('copyWith', () {
      test('copies with new values', () {
        final original = WebhookEvent(
          id: 'evt_123',
          type: 'customer.created',
          processor: ProcessorType.stripe,
          data: {'customer_id': 'cus_123'},
          createdAt: testCreatedAt,
        );

        final copy = original.copyWith(
          type: 'customer.updated',
          data: {'customer_id': 'cus_123', 'updated': true},
        );

        expect(copy.type, 'customer.updated');
        expect(copy.data['updated'], true);
        expect(copy.id, original.id);
        expect(copy.processor, original.processor);
      });

      test('copies without changes returns equal object', () {
        final original = WebhookEvent(
          id: 'evt_123',
          type: 'customer.created',
          processor: ProcessorType.stripe,
          data: {'customer_id': 'cus_123'},
          createdAt: testCreatedAt,
        );

        final copy = original.copyWith();

        expect(copy, equals(original));
      });
    });

    group('equality', () {
      test('equals when all fields match', () {
        final event1 = WebhookEvent(
          id: 'evt_123',
          type: 'customer.created',
          processor: ProcessorType.stripe,
          data: {'customer_id': 'cus_123'},
          createdAt: testCreatedAt,
        );

        final event2 = WebhookEvent(
          id: 'evt_123',
          type: 'customer.created',
          processor: ProcessorType.stripe,
          data: {'customer_id': 'cus_123'},
          createdAt: testCreatedAt,
        );

        expect(event1, equals(event2));
        expect(event1.hashCode, equals(event2.hashCode));
      });

      test('not equals when fields differ', () {
        final event1 = WebhookEvent(
          id: 'evt_123',
          type: 'customer.created',
          processor: ProcessorType.stripe,
          data: {'customer_id': 'cus_123'},
          createdAt: testCreatedAt,
        );

        final event2 = WebhookEvent(
          id: 'evt_456',
          type: 'customer.created',
          processor: ProcessorType.stripe,
          data: {'customer_id': 'cus_123'},
          createdAt: testCreatedAt,
        );

        expect(event1, isNot(equals(event2)));
      });
    });

    group('event types', () {
      test('supports customer event types', () {
        final customerEvents = [
          'customer.created',
          'customer.updated',
          'customer.deleted',
        ];

        for (final type in customerEvents) {
          final event = WebhookEvent(
            id: 'evt_123',
            type: type,
            processor: ProcessorType.stripe,
            data: {'customer_id': 'cus_123'},
            createdAt: testCreatedAt,
          );

          expect(event.type, type);
        }
      });

      test('supports subscription event types', () {
        final subscriptionEvents = [
          'subscription.created',
          'subscription.updated',
          'subscription.canceled',
          'subscription.resumed',
        ];

        for (final type in subscriptionEvents) {
          final event = WebhookEvent(
            id: 'evt_123',
            type: type,
            processor: ProcessorType.stripe,
            data: {'subscription_id': 'sub_123'},
            createdAt: testCreatedAt,
          );

          expect(event.type, type);
        }
      });

      test('supports payment event types', () {
        final paymentEvents = [
          'charge.succeeded',
          'charge.failed',
          'charge.refunded',
          'payment_intent.succeeded',
          'payment_intent.failed',
        ];

        for (final type in paymentEvents) {
          final event = WebhookEvent(
            id: 'evt_123',
            type: type,
            processor: ProcessorType.stripe,
            data: {'payment_id': 'pay_123'},
            createdAt: testCreatedAt,
          );

          expect(event.type, type);
        }
      });
    });

    group('processors', () {
      test('supports all processor types', () {
        for (final processor in ProcessorType.values) {
          final event = WebhookEvent(
            id: 'evt_123',
            type: 'test.event',
            processor: processor,
            data: {'test': 'data'},
            createdAt: testCreatedAt,
          );

          expect(event.processor, processor);
        }
      });
    });

    group('data payload', () {
      test('handles nested data structures', () {
        final event = WebhookEvent(
          id: 'evt_123',
          type: 'complex.event',
          processor: ProcessorType.stripe,
          data: {
            'level1': {
              'level2': {
                'level3': 'value',
              },
            },
          },
          createdAt: testCreatedAt,
        );

        expect(event.data['level1']['level2']['level3'], 'value');
      });

      test('handles array data', () {
        final event = WebhookEvent(
          id: 'evt_123',
          type: 'batch.event',
          processor: ProcessorType.stripe,
          data: {
            'items': [
              {'id': '1'},
              {'id': '2'},
              {'id': '3'},
            ],
          },
          createdAt: testCreatedAt,
        );

        expect(event.data['items'], isA<List>());
        expect((event.data['items'] as List).length, 3);
      });

      test('handles various data types', () {
        final event = WebhookEvent(
          id: 'evt_123',
          type: 'mixed.event',
          processor: ProcessorType.stripe,
          data: {
            'string': 'value',
            'number': 123,
            'boolean': true,
            'null': null,
            'array': [1, 2, 3],
            'object': {'key': 'value'},
          },
          createdAt: testCreatedAt,
        );

        expect(event.data['string'], 'value');
        expect(event.data['number'], 123);
        expect(event.data['boolean'], true);
        expect(event.data['null'], isNull);
        expect(event.data['array'], [1, 2, 3]);
        expect(event.data['object'], {'key': 'value'});
      });
    });
  });
}
