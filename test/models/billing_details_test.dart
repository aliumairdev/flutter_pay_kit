import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_universal_payments/src/models/address.dart';
import 'package:flutter_universal_payments/src/models/billing_details.dart';

void main() {
  group('BillingDetails', () {
    group('constructor', () {
      test('creates billing details with all fields', () {
        const address = Address(
          line1: '123 Main St',
          city: 'New York',
          postalCode: '10001',
          country: 'US',
        );

        const billingDetails = BillingDetails(
          name: 'John Doe',
          email: 'john@example.com',
          phone: '+1234567890',
          address: address,
        );

        expect(billingDetails.name, 'John Doe');
        expect(billingDetails.email, 'john@example.com');
        expect(billingDetails.phone, '+1234567890');
        expect(billingDetails.address, address);
      });

      test('creates billing details with all fields null', () {
        const billingDetails = BillingDetails();

        expect(billingDetails.name, isNull);
        expect(billingDetails.email, isNull);
        expect(billingDetails.phone, isNull);
        expect(billingDetails.address, isNull);
      });

      test('creates billing details with minimal fields', () {
        const billingDetails = BillingDetails(
          email: 'john@example.com',
        );

        expect(billingDetails.email, 'john@example.com');
        expect(billingDetails.name, isNull);
        expect(billingDetails.phone, isNull);
        expect(billingDetails.address, isNull);
      });
    });

    group('JSON serialization', () {
      test('converts to JSON correctly', () {
        const address = Address(
          line1: '123 Main St',
          city: 'New York',
          postalCode: '10001',
          country: 'US',
        );

        const billingDetails = BillingDetails(
          name: 'John Doe',
          email: 'john@example.com',
          phone: '+1234567890',
          address: address,
        );

        final json = billingDetails.toJson();

        expect(json['name'], 'John Doe');
        expect(json['email'], 'john@example.com');
        expect(json['phone'], '+1234567890');
        expect(json['address'], isA<Map<String, dynamic>>());
      });

      test('converts from JSON correctly', () {
        final json = {
          'name': 'Jane Smith',
          'email': 'jane@example.com',
          'phone': '+9876543210',
          'address': {
            'line1': '456 Elm St',
            'city': 'Los Angeles',
            'postal_code': '90001',
            'country': 'US',
          },
        };

        final billingDetails = BillingDetails.fromJson(json);

        expect(billingDetails.name, 'Jane Smith');
        expect(billingDetails.email, 'jane@example.com');
        expect(billingDetails.phone, '+9876543210');
        expect(billingDetails.address, isNotNull);
        expect(billingDetails.address!.line1, '456 Elm St');
      });

      test('handles null values in JSON', () {
        final json = <String, dynamic>{};

        final billingDetails = BillingDetails.fromJson(json);

        expect(billingDetails.name, isNull);
        expect(billingDetails.email, isNull);
        expect(billingDetails.phone, isNull);
        expect(billingDetails.address, isNull);
      });

      test('round-trip serialization preserves data', () {
        const address = Address(
          line1: '123 Main St',
          city: 'New York',
          postalCode: '10001',
          country: 'US',
        );

        const original = BillingDetails(
          name: 'John Doe',
          email: 'john@example.com',
          phone: '+1234567890',
          address: address,
        );

        final json = original.toJson();
        final deserialized = BillingDetails.fromJson(json);

        expect(deserialized, equals(original));
      });
    });

    group('copyWith', () {
      test('copies with new values', () {
        const original = BillingDetails(
          name: 'John Doe',
          email: 'john@example.com',
        );

        final copy = original.copyWith(
          phone: '+1234567890',
        );

        expect(copy.name, 'John Doe');
        expect(copy.email, 'john@example.com');
        expect(copy.phone, '+1234567890');
      });

      test('copies with all fields changed', () {
        const original = BillingDetails(
          name: 'John Doe',
          email: 'john@example.com',
        );

        final copy = original.copyWith(
          name: 'Jane Smith',
          email: 'jane@example.com',
          phone: '+9876543210',
        );

        expect(copy.name, 'Jane Smith');
        expect(copy.email, 'jane@example.com');
        expect(copy.phone, '+9876543210');
      });

      test('copies without changes returns equal object', () {
        const original = BillingDetails(
          name: 'John Doe',
          email: 'john@example.com',
        );

        final copy = original.copyWith();

        expect(copy, equals(original));
      });
    });

    group('equality', () {
      test('equals when all fields match', () {
        const address = Address(
          line1: '123 Main St',
          city: 'New York',
          postalCode: '10001',
          country: 'US',
        );

        const billingDetails1 = BillingDetails(
          name: 'John Doe',
          email: 'john@example.com',
          phone: '+1234567890',
          address: address,
        );

        const billingDetails2 = BillingDetails(
          name: 'John Doe',
          email: 'john@example.com',
          phone: '+1234567890',
          address: address,
        );

        expect(billingDetails1, equals(billingDetails2));
        expect(billingDetails1.hashCode, equals(billingDetails2.hashCode));
      });

      test('not equals when fields differ', () {
        const billingDetails1 = BillingDetails(
          name: 'John Doe',
          email: 'john@example.com',
        );

        const billingDetails2 = BillingDetails(
          name: 'Jane Smith',
          email: 'john@example.com',
        );

        expect(billingDetails1, isNot(equals(billingDetails2)));
      });

      test('equals when both have null fields', () {
        const billingDetails1 = BillingDetails();
        const billingDetails2 = BillingDetails();

        expect(billingDetails1, equals(billingDetails2));
      });
    });

    group('edge cases', () {
      test('creates billing details with only email', () {
        const billingDetails = BillingDetails(
          email: 'test@example.com',
        );

        expect(billingDetails.email, 'test@example.com');
        expect(billingDetails.name, isNull);
      });

      test('creates billing details with only phone', () {
        const billingDetails = BillingDetails(
          phone: '+1234567890',
        );

        expect(billingDetails.phone, '+1234567890');
        expect(billingDetails.email, isNull);
      });

      test('creates billing details with only address', () {
        const address = Address(
          line1: '123 Main St',
          city: 'New York',
          postalCode: '10001',
          country: 'US',
        );

        const billingDetails = BillingDetails(
          address: address,
        );

        expect(billingDetails.address, address);
        expect(billingDetails.name, isNull);
        expect(billingDetails.email, isNull);
      });
    });
  });
}
