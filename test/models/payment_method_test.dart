import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_universal_payments/src/models/billing_details.dart';
import 'package:flutter_universal_payments/src/models/enums.dart';
import 'package:flutter_universal_payments/src/models/payment_method.dart';

import '../helpers/mock_data.dart';

void main() {
  group('PaymentMethod', () {
    group('constructor', () {
      test('creates payment method with all required fields', () {
        final paymentMethod = PaymentMethod(
          id: 'pm_123',
          customerId: 'cus_123',
          type: PaymentMethodType.card,
          last4: '4242',
          brand: 'visa',
          expiryMonth: 12,
          expiryYear: 2025,
          isDefault: true,
        );

        expect(paymentMethod.id, 'pm_123');
        expect(paymentMethod.customerId, 'cus_123');
        expect(paymentMethod.type, PaymentMethodType.card);
        expect(paymentMethod.last4, '4242');
        expect(paymentMethod.brand, 'visa');
        expect(paymentMethod.expiryMonth, 12);
        expect(paymentMethod.expiryYear, 2025);
        expect(paymentMethod.isDefault, true);
      });

      test('creates payment method with optional fields', () {
        final billingDetails = MockData.mockBillingDetails();
        final paymentMethod = PaymentMethod(
          id: 'pm_123',
          customerId: 'cus_123',
          type: PaymentMethodType.card,
          isDefault: false,
          billingDetails: billingDetails,
          metadata: {'key': 'value'},
        );

        expect(paymentMethod.billingDetails, billingDetails);
        expect(paymentMethod.metadata, {'key': 'value'});
      });

      test('creates non-card payment method', () {
        final paymentMethod = PaymentMethod(
          id: 'pm_123',
          customerId: 'cus_123',
          type: PaymentMethodType.paypal,
          isDefault: true,
        );

        expect(paymentMethod.type, PaymentMethodType.paypal);
        expect(paymentMethod.last4, isNull);
        expect(paymentMethod.brand, isNull);
        expect(paymentMethod.expiryMonth, isNull);
        expect(paymentMethod.expiryYear, isNull);
      });
    });

    group('JSON serialization', () {
      test('converts to JSON correctly', () {
        final billingDetails = MockData.mockBillingDetails();
        final paymentMethod = PaymentMethod(
          id: 'pm_123',
          customerId: 'cus_123',
          type: PaymentMethodType.card,
          last4: '4242',
          brand: 'visa',
          expiryMonth: 12,
          expiryYear: 2025,
          isDefault: true,
          billingDetails: billingDetails,
          metadata: {'key': 'value'},
        );

        final json = paymentMethod.toJson();

        expect(json['id'], 'pm_123');
        expect(json['customer_id'], 'cus_123');
        expect(json['type'], 'card');
        expect(json['last4'], '4242');
        expect(json['brand'], 'visa');
        expect(json['expiry_month'], 12);
        expect(json['expiry_year'], 2025);
        expect(json['is_default'], true);
        expect(json['billing_details'], isA<Map<String, dynamic>>());
        expect(json['metadata'], {'key': 'value'});
      });

      test('converts from JSON correctly', () {
        final json = {
          'id': 'pm_123',
          'customer_id': 'cus_123',
          'type': 'card',
          'last4': '5555',
          'brand': 'mastercard',
          'expiry_month': 6,
          'expiry_year': 2026,
          'is_default': false,
        };

        final paymentMethod = PaymentMethod.fromJson(json);

        expect(paymentMethod.id, 'pm_123');
        expect(paymentMethod.customerId, 'cus_123');
        expect(paymentMethod.type, PaymentMethodType.card);
        expect(paymentMethod.last4, '5555');
        expect(paymentMethod.brand, 'mastercard');
        expect(paymentMethod.expiryMonth, 6);
        expect(paymentMethod.expiryYear, 2026);
        expect(paymentMethod.isDefault, false);
      });

      test('handles null optional fields in JSON', () {
        final json = {
          'id': 'pm_123',
          'customer_id': 'cus_123',
          'type': 'bank_account',
          'is_default': true,
        };

        final paymentMethod = PaymentMethod.fromJson(json);

        expect(paymentMethod.last4, isNull);
        expect(paymentMethod.brand, isNull);
        expect(paymentMethod.expiryMonth, isNull);
        expect(paymentMethod.expiryYear, isNull);
        expect(paymentMethod.billingDetails, isNull);
        expect(paymentMethod.metadata, isNull);
      });

      test('round-trip serialization preserves data', () {
        final billingDetails = MockData.mockBillingDetails();
        final original = PaymentMethod(
          id: 'pm_123',
          customerId: 'cus_123',
          type: PaymentMethodType.card,
          last4: '4242',
          brand: 'visa',
          expiryMonth: 12,
          expiryYear: 2025,
          isDefault: true,
          billingDetails: billingDetails,
          metadata: {'key': 'value'},
        );

        final json = original.toJson();
        final deserialized = PaymentMethod.fromJson(json);

        expect(deserialized, equals(original));
      });
    });

    group('copyWith', () {
      test('copies with new values', () {
        final original = PaymentMethod(
          id: 'pm_123',
          customerId: 'cus_123',
          type: PaymentMethodType.card,
          last4: '4242',
          isDefault: false,
        );

        final copy = original.copyWith(
          isDefault: true,
          brand: 'visa',
          expiryMonth: 12,
          expiryYear: 2025,
        );

        expect(copy.isDefault, true);
        expect(copy.brand, 'visa');
        expect(copy.expiryMonth, 12);
        expect(copy.expiryYear, 2025);
        expect(copy.id, original.id);
        expect(copy.customerId, original.customerId);
      });

      test('copies without changes returns equal object', () {
        final original = PaymentMethod(
          id: 'pm_123',
          customerId: 'cus_123',
          type: PaymentMethodType.card,
          isDefault: true,
        );

        final copy = original.copyWith();

        expect(copy, equals(original));
      });
    });

    group('equality', () {
      test('equals when all fields match', () {
        final paymentMethod1 = PaymentMethod(
          id: 'pm_123',
          customerId: 'cus_123',
          type: PaymentMethodType.card,
          last4: '4242',
          brand: 'visa',
          expiryMonth: 12,
          expiryYear: 2025,
          isDefault: true,
        );

        final paymentMethod2 = PaymentMethod(
          id: 'pm_123',
          customerId: 'cus_123',
          type: PaymentMethodType.card,
          last4: '4242',
          brand: 'visa',
          expiryMonth: 12,
          expiryYear: 2025,
          isDefault: true,
        );

        expect(paymentMethod1, equals(paymentMethod2));
        expect(paymentMethod1.hashCode, equals(paymentMethod2.hashCode));
      });

      test('not equals when fields differ', () {
        final paymentMethod1 = PaymentMethod(
          id: 'pm_123',
          customerId: 'cus_123',
          type: PaymentMethodType.card,
          isDefault: true,
        );

        final paymentMethod2 = PaymentMethod(
          id: 'pm_456',
          customerId: 'cus_123',
          type: PaymentMethodType.card,
          isDefault: true,
        );

        expect(paymentMethod1, isNot(equals(paymentMethod2)));
      });
    });

    group('payment method types', () {
      test('supports all payment method types', () {
        for (final type in PaymentMethodType.values) {
          final paymentMethod = PaymentMethod(
            id: 'pm_123',
            customerId: 'cus_123',
            type: type,
            isDefault: false,
          );

          expect(paymentMethod.type, type);
        }
      });

      test('creates card payment method with full details', () {
        final paymentMethod = PaymentMethod(
          id: 'pm_123',
          customerId: 'cus_123',
          type: PaymentMethodType.card,
          last4: '4242',
          brand: 'visa',
          expiryMonth: 12,
          expiryYear: 2025,
          isDefault: true,
        );

        expect(paymentMethod.type, PaymentMethodType.card);
        expect(paymentMethod.last4, isNotNull);
        expect(paymentMethod.brand, isNotNull);
        expect(paymentMethod.expiryMonth, isNotNull);
        expect(paymentMethod.expiryYear, isNotNull);
      });

      test('creates PayPal payment method', () {
        final paymentMethod = PaymentMethod(
          id: 'pm_123',
          customerId: 'cus_123',
          type: PaymentMethodType.paypal,
          isDefault: false,
        );

        expect(paymentMethod.type, PaymentMethodType.paypal);
      });

      test('creates bank account payment method', () {
        final paymentMethod = PaymentMethod(
          id: 'pm_123',
          customerId: 'cus_123',
          type: PaymentMethodType.bankAccount,
          last4: '1234',
          isDefault: false,
        );

        expect(paymentMethod.type, PaymentMethodType.bankAccount);
        expect(paymentMethod.last4, '1234');
      });
    });

    group('default payment method', () {
      test('creates default payment method', () {
        final paymentMethod = PaymentMethod(
          id: 'pm_123',
          customerId: 'cus_123',
          type: PaymentMethodType.card,
          isDefault: true,
        );

        expect(paymentMethod.isDefault, true);
      });

      test('creates non-default payment method', () {
        final paymentMethod = PaymentMethod(
          id: 'pm_123',
          customerId: 'cus_123',
          type: PaymentMethodType.card,
          isDefault: false,
        );

        expect(paymentMethod.isDefault, false);
      });
    });

    group('card brands', () {
      test('supports various card brands', () {
        final brands = ['visa', 'mastercard', 'amex', 'discover', 'jcb'];

        for (final brand in brands) {
          final paymentMethod = PaymentMethod(
            id: 'pm_123',
            customerId: 'cus_123',
            type: PaymentMethodType.card,
            brand: brand,
            isDefault: false,
          );

          expect(paymentMethod.brand, brand);
        }
      });
    });
  });
}
