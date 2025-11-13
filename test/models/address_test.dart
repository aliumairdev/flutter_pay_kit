import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_universal_payments/src/models/address.dart';

void main() {
  group('Address', () {
    group('constructor', () {
      test('creates address with all fields', () {
        final address = Address(
          line1: '123 Main St',
          line2: 'Apt 4B',
          city: 'New York',
          state: 'NY',
          postalCode: '10001',
          country: 'US',
        );

        expect(address.line1, '123 Main St');
        expect(address.line2, 'Apt 4B');
        expect(address.city, 'New York');
        expect(address.state, 'NY');
        expect(address.postalCode, '10001');
        expect(address.country, 'US');
      });

      test('creates address with optional fields as null', () {
        const address = Address();

        expect(address.line1, isNull);
        expect(address.line2, isNull);
        expect(address.city, isNull);
        expect(address.state, isNull);
        expect(address.postalCode, isNull);
        expect(address.country, isNull);
      });

      test('creates address with minimal fields', () {
        const address = Address(
          line1: '123 Main St',
          city: 'New York',
          postalCode: '10001',
          country: 'US',
        );

        expect(address.line1, '123 Main St');
        expect(address.line2, isNull);
        expect(address.city, 'New York');
        expect(address.postalCode, '10001');
        expect(address.country, 'US');
      });
    });

    group('JSON serialization', () {
      test('converts to JSON correctly', () {
        const address = Address(
          line1: '123 Main St',
          line2: 'Apt 4B',
          city: 'New York',
          state: 'NY',
          postalCode: '10001',
          country: 'US',
        );

        final json = address.toJson();

        expect(json['line1'], '123 Main St');
        expect(json['line2'], 'Apt 4B');
        expect(json['city'], 'New York');
        expect(json['state'], 'NY');
        expect(json['postal_code'], '10001');
        expect(json['country'], 'US');
      });

      test('converts from JSON correctly', () {
        final json = {
          'line1': '123 Main St',
          'line2': 'Apt 4B',
          'city': 'New York',
          'state': 'NY',
          'postal_code': '10001',
          'country': 'US',
        };

        final address = Address.fromJson(json);

        expect(address.line1, '123 Main St');
        expect(address.line2, 'Apt 4B');
        expect(address.city, 'New York');
        expect(address.state, 'NY');
        expect(address.postalCode, '10001');
        expect(address.country, 'US');
      });

      test('handles null values in JSON', () {
        final json = <String, dynamic>{};

        final address = Address.fromJson(json);

        expect(address.line1, isNull);
        expect(address.line2, isNull);
        expect(address.city, isNull);
        expect(address.state, isNull);
        expect(address.postalCode, isNull);
        expect(address.country, isNull);
      });

      test('round-trip serialization preserves data', () {
        const original = Address(
          line1: '123 Main St',
          line2: 'Apt 4B',
          city: 'New York',
          state: 'NY',
          postalCode: '10001',
          country: 'US',
        );

        final json = original.toJson();
        final deserialized = Address.fromJson(json);

        expect(deserialized, equals(original));
      });
    });

    group('copyWith', () {
      test('copies with new values', () {
        const original = Address(
          line1: '123 Main St',
          city: 'New York',
          postalCode: '10001',
          country: 'US',
        );

        final copy = original.copyWith(
          line2: 'Apt 4B',
          state: 'NY',
        );

        expect(copy.line1, '123 Main St');
        expect(copy.line2, 'Apt 4B');
        expect(copy.city, 'New York');
        expect(copy.state, 'NY');
        expect(copy.postalCode, '10001');
        expect(copy.country, 'US');
      });

      test('copies with all fields changed', () {
        const original = Address(
          line1: '123 Main St',
          city: 'New York',
          postalCode: '10001',
          country: 'US',
        );

        final copy = original.copyWith(
          line1: '456 Elm St',
          line2: 'Suite 100',
          city: 'Los Angeles',
          state: 'CA',
          postalCode: '90001',
          country: 'US',
        );

        expect(copy.line1, '456 Elm St');
        expect(copy.line2, 'Suite 100');
        expect(copy.city, 'Los Angeles');
        expect(copy.state, 'CA');
        expect(copy.postalCode, '90001');
        expect(copy.country, 'US');
      });

      test('copies without changes returns equal object', () {
        const original = Address(
          line1: '123 Main St',
          city: 'New York',
          postalCode: '10001',
          country: 'US',
        );

        final copy = original.copyWith();

        expect(copy, equals(original));
      });
    });

    group('equality', () {
      test('equals when all fields match', () {
        const address1 = Address(
          line1: '123 Main St',
          line2: 'Apt 4B',
          city: 'New York',
          state: 'NY',
          postalCode: '10001',
          country: 'US',
        );

        const address2 = Address(
          line1: '123 Main St',
          line2: 'Apt 4B',
          city: 'New York',
          state: 'NY',
          postalCode: '10001',
          country: 'US',
        );

        expect(address1, equals(address2));
        expect(address1.hashCode, equals(address2.hashCode));
      });

      test('not equals when fields differ', () {
        const address1 = Address(
          line1: '123 Main St',
          city: 'New York',
          postalCode: '10001',
          country: 'US',
        );

        const address2 = Address(
          line1: '456 Elm St',
          city: 'New York',
          postalCode: '10001',
          country: 'US',
        );

        expect(address1, isNot(equals(address2)));
      });

      test('equals when both have null fields', () {
        const address1 = Address();
        const address2 = Address();

        expect(address1, equals(address2));
      });
    });
  });
}
