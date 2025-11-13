import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_universal_payments/src/exceptions/authentication_exception.dart';
import 'package:flutter_universal_payments/src/exceptions/customer_not_found_exception.dart';
import 'package:flutter_universal_payments/src/exceptions/invalid_configuration_exception.dart';
import 'package:flutter_universal_payments/src/exceptions/network_exception.dart';
import 'package:flutter_universal_payments/src/exceptions/payment_exception.dart';
import 'package:flutter_universal_payments/src/exceptions/payment_method_exception.dart';
import 'package:flutter_universal_payments/src/exceptions/processor_exception.dart';
import 'package:flutter_universal_payments/src/exceptions/subscription_not_found_exception.dart';
import 'package:flutter_universal_payments/src/exceptions/validation_exception.dart';
import 'package:flutter_universal_payments/src/exceptions/webhook_exception.dart';

void main() {
  group('PaymentException', () {
    test('creates exception with message', () {
      final exception = _TestPaymentException('Test error');
      expect(exception.message, 'Test error');
      expect(exception.code, isNull);
      expect(exception.originalError, isNull);
      expect(exception.stackTrace, isNull);
    });

    test('creates exception with all fields', () {
      final error = Exception('Original error');
      final stackTrace = StackTrace.current;
      final exception = _TestPaymentException(
        'Test error',
        code: 'ERR_001',
        originalError: error,
        stackTrace: stackTrace,
      );

      expect(exception.message, 'Test error');
      expect(exception.code, 'ERR_001');
      expect(exception.originalError, error);
      expect(exception.stackTrace, stackTrace);
    });

    test('toString returns formatted message', () {
      final exception = _TestPaymentException('Test error');
      expect(exception.toString(), 'PaymentException: Test error');
    });

    test('is an Exception', () {
      final exception = _TestPaymentException('Test error');
      expect(exception, isA<Exception>());
    });
  });

  group('ProcessorException', () {
    test('creates exception with message', () {
      final exception = ProcessorException('Processor error');
      expect(exception.message, 'Processor error');
      expect(exception.processorName, isNull);
    });

    test('creates exception with processor name', () {
      final exception = ProcessorException(
        'Stripe error',
        processorName: 'Stripe',
      );
      expect(exception.message, 'Stripe error');
      expect(exception.processorName, 'Stripe');
    });

    test('creates exception with all fields', () {
      final exception = ProcessorException(
        'Payment failed',
        code: 'card_declined',
        processorName: 'Stripe',
        originalError: Exception('Original'),
        stackTrace: StackTrace.current,
      );

      expect(exception.message, 'Payment failed');
      expect(exception.code, 'card_declined');
      expect(exception.processorName, 'Stripe');
      expect(exception.originalError, isNotNull);
      expect(exception.stackTrace, isNotNull);
    });

    test('toString includes processor name when present', () {
      final exception = ProcessorException(
        'Error',
        processorName: 'Paddle',
        code: 'ERR_001',
      );
      expect(
        exception.toString(),
        'Paddle ProcessorException: Error (code: ERR_001)',
      );
    });

    test('toString without processor name', () {
      final exception = ProcessorException('Error', code: 'ERR_001');
      expect(
        exception.toString(),
        'ProcessorException: Error (code: ERR_001)',
      );
    });

    test('is a PaymentException', () {
      final exception = ProcessorException('Error');
      expect(exception, isA<PaymentException>());
    });
  });

  group('AuthenticationException', () {
    test('creates exception with message', () {
      final exception = AuthenticationException('Invalid API key');
      expect(exception.message, 'Invalid API key');
      expect(exception.authenticationType, isNull);
    });

    test('creates exception with authentication type', () {
      final exception = AuthenticationException(
        'Invalid token',
        authenticationType: 'oauth',
      );
      expect(exception.authenticationType, 'oauth');
    });

    test('creates exception with all fields', () {
      final exception = AuthenticationException(
        'Auth failed',
        code: 'invalid_grant',
        authenticationType: 'jwt',
        originalError: Exception('Original'),
        stackTrace: StackTrace.current,
      );

      expect(exception.message, 'Auth failed');
      expect(exception.code, 'invalid_grant');
      expect(exception.authenticationType, 'jwt');
    });

    test('toString includes authentication type when present', () {
      final exception = AuthenticationException(
        'Failed',
        authenticationType: 'api_key',
        code: 'ERR_001',
      );
      expect(
        exception.toString(),
        'AuthenticationException: Failed (api_key) (code: ERR_001)',
      );
    });

    test('is a PaymentException', () {
      final exception = AuthenticationException('Error');
      expect(exception, isA<PaymentException>());
    });
  });

  group('NetworkException', () {
    test('creates exception with message', () {
      final exception = NetworkException('Connection timeout');
      expect(exception.message, 'Connection timeout');
      expect(exception.statusCode, isNull);
      expect(exception.url, isNull);
    });

    test('creates exception with status code and URL', () {
      final exception = NetworkException(
        'Server error',
        statusCode: 500,
        url: 'https://api.example.com/charge',
      );
      expect(exception.statusCode, 500);
      expect(exception.url, 'https://api.example.com/charge');
    });

    test('creates exception with all fields', () {
      final exception = NetworkException(
        'Request failed',
        code: 'timeout',
        statusCode: 408,
        url: 'https://api.stripe.com/v1/charges',
        originalError: Exception('Original'),
        stackTrace: StackTrace.current,
      );

      expect(exception.message, 'Request failed');
      expect(exception.code, 'timeout');
      expect(exception.statusCode, 408);
      expect(exception.url, 'https://api.stripe.com/v1/charges');
    });

    test('toString includes status and URL when present', () {
      final exception = NetworkException(
        'Error',
        statusCode: 404,
        code: 'not_found',
        url: 'https://api.example.com',
      );
      expect(
        exception.toString(),
        'NetworkException: Error (status: 404) (code: not_found) at https://api.example.com',
      );
    });

    test('is a PaymentException', () {
      final exception = NetworkException('Error');
      expect(exception, isA<PaymentException>());
    });
  });

  group('ValidationException', () {
    test('creates exception with message', () {
      final exception = ValidationException('Invalid email');
      expect(exception.message, 'Invalid email');
      expect(exception.fieldName, isNull);
      expect(exception.invalidValue, isNull);
    });

    test('creates exception with field name and invalid value', () {
      final exception = ValidationException(
        'Email is required',
        fieldName: 'email',
        invalidValue: '',
      );
      expect(exception.fieldName, 'email');
      expect(exception.invalidValue, '');
    });

    test('creates exception with all fields', () {
      final exception = ValidationException(
        'Invalid amount',
        code: 'amount_too_low',
        fieldName: 'amount',
        invalidValue: -100,
        originalError: Exception('Original'),
        stackTrace: StackTrace.current,
      );

      expect(exception.message, 'Invalid amount');
      expect(exception.code, 'amount_too_low');
      expect(exception.fieldName, 'amount');
      expect(exception.invalidValue, -100);
    });

    test('toString includes field name and value when present', () {
      final exception = ValidationException(
        'Invalid',
        fieldName: 'email',
        invalidValue: 'not-an-email',
        code: 'invalid_format',
      );
      expect(
        exception.toString(),
        'ValidationException: Invalid (field: email) (value: not-an-email) (code: invalid_format)',
      );
    });

    test('is a PaymentException', () {
      final exception = ValidationException('Error');
      expect(exception, isA<PaymentException>());
    });
  });

  group('CustomerNotFoundException', () {
    test('creates exception with message', () {
      final exception = CustomerNotFoundException('Customer not found');
      expect(exception.message, 'Customer not found');
      expect(exception.customerId, isNull);
    });

    test('creates exception with customer ID', () {
      final exception = CustomerNotFoundException(
        'Customer does not exist',
        customerId: 'cus_123',
      );
      expect(exception.customerId, 'cus_123');
    });

    test('creates exception with all fields', () {
      final exception = CustomerNotFoundException(
        'Not found',
        code: 'resource_missing',
        customerId: 'cus_xyz',
        originalError: Exception('Original'),
        stackTrace: StackTrace.current,
      );

      expect(exception.message, 'Not found');
      expect(exception.code, 'resource_missing');
      expect(exception.customerId, 'cus_xyz');
    });

    test('toString includes customer ID when present', () {
      final exception = CustomerNotFoundException(
        'Not found',
        customerId: 'cus_123',
        code: 'ERR_001',
      );
      expect(
        exception.toString(),
        'CustomerNotFoundException: Not found (customer: cus_123) (code: ERR_001)',
      );
    });

    test('is a PaymentException', () {
      final exception = CustomerNotFoundException('Error');
      expect(exception, isA<PaymentException>());
    });
  });

  group('SubscriptionNotFoundException', () {
    test('creates exception with message', () {
      final exception = SubscriptionNotFoundException('Subscription not found');
      expect(exception.message, 'Subscription not found');
      expect(exception.subscriptionId, isNull);
    });

    test('creates exception with subscription ID', () {
      final exception = SubscriptionNotFoundException(
        'Subscription does not exist',
        subscriptionId: 'sub_123',
      );
      expect(exception.subscriptionId, 'sub_123');
    });

    test('creates exception with all fields', () {
      final exception = SubscriptionNotFoundException(
        'Not found',
        code: 'resource_missing',
        subscriptionId: 'sub_xyz',
        originalError: Exception('Original'),
        stackTrace: StackTrace.current,
      );

      expect(exception.message, 'Not found');
      expect(exception.code, 'resource_missing');
      expect(exception.subscriptionId, 'sub_xyz');
    });

    test('toString includes subscription ID when present', () {
      final exception = SubscriptionNotFoundException(
        'Not found',
        subscriptionId: 'sub_123',
        code: 'ERR_001',
      );
      expect(
        exception.toString(),
        'SubscriptionNotFoundException: Not found (subscription: sub_123) (code: ERR_001)',
      );
    });

    test('is a PaymentException', () {
      final exception = SubscriptionNotFoundException('Error');
      expect(exception, isA<PaymentException>());
    });
  });

  group('PaymentMethodException', () {
    test('creates exception with message', () {
      final exception = PaymentMethodException('Card declined');
      expect(exception.message, 'Card declined');
      expect(exception.paymentMethodType, isNull);
      expect(exception.last4, isNull);
    });

    test('creates exception with payment method type and last4', () {
      final exception = PaymentMethodException(
        'Payment method failed',
        paymentMethodType: 'card',
        last4: '4242',
      );
      expect(exception.paymentMethodType, 'card');
      expect(exception.last4, '4242');
    });

    test('creates exception with all fields', () {
      final exception = PaymentMethodException(
        'Card expired',
        code: 'card_expired',
        paymentMethodType: 'card',
        last4: '1234',
        originalError: Exception('Original'),
        stackTrace: StackTrace.current,
      );

      expect(exception.message, 'Card expired');
      expect(exception.code, 'card_expired');
      expect(exception.paymentMethodType, 'card');
      expect(exception.last4, '1234');
    });

    test('toString includes payment method type and last4 when present', () {
      final exception = PaymentMethodException(
        'Declined',
        paymentMethodType: 'card',
        last4: '4242',
        code: 'card_declined',
      );
      expect(
        exception.toString(),
        'PaymentMethodException: Declined (card ending in 4242) (code: card_declined)',
      );
    });

    test('toString with only payment method type', () {
      final exception = PaymentMethodException(
        'Error',
        paymentMethodType: 'paypal',
      );
      expect(
        exception.toString(),
        'PaymentMethodException: Error (paypal)',
      );
    });

    test('is a PaymentException', () {
      final exception = PaymentMethodException('Error');
      expect(exception, isA<PaymentException>());
    });
  });

  group('WebhookException', () {
    test('creates exception with message', () {
      final exception = WebhookException('Invalid signature');
      expect(exception.message, 'Invalid signature');
      expect(exception.webhookId, isNull);
      expect(exception.eventType, isNull);
    });

    test('creates exception with webhook ID and event type', () {
      final exception = WebhookException(
        'Webhook failed',
        webhookId: 'wh_123',
        eventType: 'customer.created',
      );
      expect(exception.webhookId, 'wh_123');
      expect(exception.eventType, 'customer.created');
    });

    test('creates exception with all fields', () {
      final exception = WebhookException(
        'Signature mismatch',
        code: 'invalid_signature',
        webhookId: 'wh_xyz',
        eventType: 'charge.succeeded',
        originalError: Exception('Original'),
        stackTrace: StackTrace.current,
      );

      expect(exception.message, 'Signature mismatch');
      expect(exception.code, 'invalid_signature');
      expect(exception.webhookId, 'wh_xyz');
      expect(exception.eventType, 'charge.succeeded');
    });

    test('toString includes webhook ID and event type when present', () {
      final exception = WebhookException(
        'Failed',
        webhookId: 'wh_123',
        eventType: 'subscription.updated',
        code: 'ERR_001',
      );
      expect(
        exception.toString(),
        'WebhookException: Failed (event: subscription.updated) (id: wh_123) (code: ERR_001)',
      );
    });

    test('is a PaymentException', () {
      final exception = WebhookException('Error');
      expect(exception, isA<PaymentException>());
    });
  });

  group('InvalidConfigurationException', () {
    test('creates exception with message', () {
      final exception = InvalidConfigurationException('Missing API key');
      expect(exception.message, 'Missing API key');
      expect(exception.fieldName, isNull);
    });

    test('creates exception with field name', () {
      final exception = InvalidConfigurationException(
        'Configuration error',
        fieldName: 'stripe_api_key',
      );
      expect(exception.fieldName, 'stripe_api_key');
    });

    test('creates exception with all fields', () {
      final exception = InvalidConfigurationException(
        'Invalid config',
        code: 'missing_required',
        fieldName: 'publishable_key',
        originalError: Exception('Original'),
        stackTrace: StackTrace.current,
      );

      expect(exception.message, 'Invalid config');
      expect(exception.code, 'missing_required');
      expect(exception.fieldName, 'publishable_key');
    });

    test('toString includes field name when present', () {
      final exception = InvalidConfigurationException(
        'Invalid',
        fieldName: 'api_key',
        code: 'ERR_001',
      );
      expect(
        exception.toString(),
        'InvalidConfigurationException: Invalid (field: api_key) (code: ERR_001)',
      );
    });

    test('is a PaymentException', () {
      final exception = InvalidConfigurationException('Error');
      expect(exception, isA<PaymentException>());
    });
  });
}

/// Test implementation of PaymentException for testing base class
class _TestPaymentException extends PaymentException {
  _TestPaymentException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
}
