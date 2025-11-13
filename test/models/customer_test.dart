import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_universal_payments/src/models/customer.dart';
import 'package:flutter_universal_payments/src/models/enums.dart';

void main() {
  group('Customer', () {
    final testCreatedAt = DateTime(2024, 1, 1);
    final testUpdatedAt = DateTime(2024, 1, 2);

    group('constructor', () {
      test('creates customer with all required fields', () {
        final customer = Customer(
          id: 'cus_123',
          email: 'test@example.com',
          name: 'Test User',
          phone: '+1234567890',
          processor: ProcessorType.stripe,
          processorCustomerId: 'stripe_cus_123',
          metadata: {'key': 'value'},
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(customer.id, 'cus_123');
        expect(customer.email, 'test@example.com');
        expect(customer.name, 'Test User');
        expect(customer.phone, '+1234567890');
        expect(customer.processor, ProcessorType.stripe);
        expect(customer.processorCustomerId, 'stripe_cus_123');
        expect(customer.metadata, {'key': 'value'});
        expect(customer.createdAt, testCreatedAt);
        expect(customer.updatedAt, testUpdatedAt);
      });

      test('creates customer with optional fields as null', () {
        final customer = Customer(
          id: 'cus_123',
          email: 'test@example.com',
          processor: ProcessorType.stripe,
          processorCustomerId: 'stripe_cus_123',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(customer.name, isNull);
        expect(customer.phone, isNull);
        expect(customer.metadata, isNull);
      });
    });

    group('JSON serialization', () {
      test('converts to JSON correctly', () {
        final customer = Customer(
          id: 'cus_123',
          email: 'test@example.com',
          name: 'Test User',
          phone: '+1234567890',
          processor: ProcessorType.paddle,
          processorCustomerId: 'paddle_cus_123',
          metadata: {'key': 'value'},
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final json = customer.toJson();

        expect(json['id'], 'cus_123');
        expect(json['email'], 'test@example.com');
        expect(json['name'], 'Test User');
        expect(json['phone'], '+1234567890');
        expect(json['processor'], 'paddle');
        expect(json['processor_customer_id'], 'paddle_cus_123');
        expect(json['metadata'], {'key': 'value'});
        expect(json['created_at'], testCreatedAt.toIso8601String());
        expect(json['updated_at'], testUpdatedAt.toIso8601String());
      });

      test('converts from JSON correctly', () {
        final json = {
          'id': 'cus_123',
          'email': 'test@example.com',
          'name': 'Test User',
          'phone': '+1234567890',
          'processor': 'braintree',
          'processor_customer_id': 'bt_cus_123',
          'metadata': {'key': 'value'},
          'created_at': testCreatedAt.toIso8601String(),
          'updated_at': testUpdatedAt.toIso8601String(),
        };

        final customer = Customer.fromJson(json);

        expect(customer.id, 'cus_123');
        expect(customer.email, 'test@example.com');
        expect(customer.name, 'Test User');
        expect(customer.phone, '+1234567890');
        expect(customer.processor, ProcessorType.braintree);
        expect(customer.processorCustomerId, 'bt_cus_123');
        expect(customer.metadata, {'key': 'value'});
        expect(customer.createdAt, testCreatedAt);
        expect(customer.updatedAt, testUpdatedAt);
      });

      test('handles null optional fields in JSON', () {
        final json = {
          'id': 'cus_123',
          'email': 'test@example.com',
          'processor': 'stripe',
          'processor_customer_id': 'stripe_cus_123',
          'created_at': testCreatedAt.toIso8601String(),
          'updated_at': testUpdatedAt.toIso8601String(),
        };

        final customer = Customer.fromJson(json);

        expect(customer.name, isNull);
        expect(customer.phone, isNull);
        expect(customer.metadata, isNull);
      });

      test('round-trip serialization preserves data', () {
        final original = Customer(
          id: 'cus_123',
          email: 'test@example.com',
          name: 'Test User',
          phone: '+1234567890',
          processor: ProcessorType.lemonSqueezy,
          processorCustomerId: 'ls_cus_123',
          metadata: {'key': 'value'},
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final json = original.toJson();
        final deserialized = Customer.fromJson(json);

        expect(deserialized, equals(original));
      });
    });

    group('copyWith', () {
      test('copies with new values', () {
        final original = Customer(
          id: 'cus_123',
          email: 'test@example.com',
          processor: ProcessorType.stripe,
          processorCustomerId: 'stripe_cus_123',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final copy = original.copyWith(
          name: 'Updated User',
          phone: '+1234567890',
        );

        expect(copy.id, 'cus_123');
        expect(copy.email, 'test@example.com');
        expect(copy.name, 'Updated User');
        expect(copy.phone, '+1234567890');
      });

      test('copies without changes returns equal object', () {
        final original = Customer(
          id: 'cus_123',
          email: 'test@example.com',
          processor: ProcessorType.stripe,
          processorCustomerId: 'stripe_cus_123',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final copy = original.copyWith();

        expect(copy, equals(original));
      });
    });

    group('equality', () {
      test('equals when all fields match', () {
        final customer1 = Customer(
          id: 'cus_123',
          email: 'test@example.com',
          name: 'Test User',
          processor: ProcessorType.stripe,
          processorCustomerId: 'stripe_cus_123',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final customer2 = Customer(
          id: 'cus_123',
          email: 'test@example.com',
          name: 'Test User',
          processor: ProcessorType.stripe,
          processorCustomerId: 'stripe_cus_123',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(customer1, equals(customer2));
        expect(customer1.hashCode, equals(customer2.hashCode));
      });

      test('not equals when fields differ', () {
        final customer1 = Customer(
          id: 'cus_123',
          email: 'test@example.com',
          processor: ProcessorType.stripe,
          processorCustomerId: 'stripe_cus_123',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final customer2 = Customer(
          id: 'cus_456',
          email: 'test@example.com',
          processor: ProcessorType.stripe,
          processorCustomerId: 'stripe_cus_123',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(customer1, isNot(equals(customer2)));
      });
    });

    group('processor types', () {
      test('supports all processor types', () {
        for (final processor in ProcessorType.values) {
          final customer = Customer(
            id: 'cus_123',
            email: 'test@example.com',
            processor: processor,
            processorCustomerId: 'proc_cus_123',
            createdAt: testCreatedAt,
            updatedAt: testUpdatedAt,
          );

          expect(customer.processor, processor);
        }
      });
    });
  });
}
