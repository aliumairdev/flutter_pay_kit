import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_universal_payments/src/exceptions/authentication_exception.dart';
import 'package:flutter_universal_payments/src/exceptions/network_exception.dart';
import 'package:flutter_universal_payments/src/exceptions/processor_exception.dart';
import 'package:flutter_universal_payments/src/processors/stripe_processor.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mocks.dart';
import '../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMockFallbacks();
  });

  group('StripeProcessor', () {
    late MockDio mockDio;
    late StripeProcessor processor;

    setUp(() {
      mockDio = MockDio();
      processor = StripeProcessor(
        publishableKey: 'pk_test_123',
        secretKey: 'sk_test_123',
        dio: mockDio,
      );
    });

    group('initialization', () {
      test('requires publishable key', () {
        expect(
          () => StripeProcessor(publishableKey: '', secretKey: 'sk_test_123'),
          throwsA(isA<AuthenticationException>()),
        );
      });

      test('requires secret key for server-side operations', () {
        expect(
          () => StripeProcessor(publishableKey: 'pk_test_123', secretKey: ''),
          throwsA(isA<AuthenticationException>()),
        );
      });

      test('creates processor with valid keys', () {
        final proc = StripeProcessor(
          publishableKey: 'pk_test_123',
          secretKey: 'sk_test_123',
        );

        expect(proc, isNotNull);
        expect(proc.processorType.name, 'stripe');
      });
    });

    group('createCustomer', () {
      test('creates customer successfully', () async {
        final responseData = {
          'id': 'cus_123',
          'email': 'test@example.com',
          'object': 'customer',
        };

        when(() => mockDio.post(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenAnswer(
          (_) async => createSuccessResponse(responseData),
        );

        final customer = await processor.createCustomer(
          email: 'test@example.com',
          name: 'Test User',
        );

        expect(customer.id, 'cus_123');
        expect(customer.email, 'test@example.com');
        verify(() => mockDio.post(any(), data: any(named: 'data'), options: any(named: 'options'))).called(1);
      });

      test('handles authentication error', () async {
        when(() => mockDio.post(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenThrow(
          createDioException(statusCode: 401, message: 'Invalid API key'),
        );

        expect(
          () => processor.createCustomer(email: 'test@example.com'),
          throwsA(isA<AuthenticationException>()),
        );
      });

      test('handles network error', () async {
        when(() => mockDio.post(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenThrow(createNetworkError());

        expect(
          () => processor.createCustomer(email: 'test@example.com'),
          throwsA(isA<NetworkException>()),
        );
      });

      test('handles processor error', () async {
        when(() => mockDio.post(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenThrow(
          createDioException(
            statusCode: 400,
            message: 'Invalid request',
            data: {'error': {'message': 'Email is invalid'}},
          ),
        );

        expect(
          () => processor.createCustomer(email: 'invalid-email'),
          throwsA(isA<ProcessorException>()),
        );
      });
    });

    group('createSubscription', () {
      test('creates subscription successfully', () async {
        final responseData = {
          'id': 'sub_123',
          'customer': 'cus_123',
          'status': 'active',
          'items': {
            'data': [
              {
                'price': {
                  'id': 'price_123',
                  'product': 'prod_123',
                },
              },
            ],
          },
          'current_period_start': 1704067200,
          'current_period_end': 1706745600,
        };

        when(() => mockDio.post(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenAnswer(
          (_) async => createSuccessResponse(responseData),
        );

        final subscription = await processor.createSubscription(
          customerId: 'cus_123',
          priceId: 'price_123',
        );

        expect(subscription.id, 'sub_123');
        expect(subscription.customerId, 'cus_123');
        expect(subscription.status.name, 'active');
      });

      test('handles subscription creation errors', () async {
        when(() => mockDio.post(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenThrow(
          createDioException(
            statusCode: 402,
            message: 'Payment required',
            data: {'error': {'message': 'Your card was declined'}},
          ),
        );

        expect(
          () => processor.createSubscription(
            customerId: 'cus_123',
            priceId: 'price_123',
          ),
          throwsA(isA<ProcessorException>()),
        );
      });
    });

    group('createCharge', () {
      test('creates charge successfully', () async {
        final responseData = {
          'id': 'ch_123',
          'amount': 1000,
          'currency': 'usd',
          'status': 'succeeded',
          'customer': 'cus_123',
        };

        when(() => mockDio.post(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenAnswer(
          (_) async => createSuccessResponse(responseData),
        );

        final charge = await processor.createCharge(
          amount: 1000,
          currency: 'usd',
          customerId: 'cus_123',
        );

        expect(charge.id, 'ch_123');
        expect(charge.amount, 1000);
        expect(charge.currency, 'usd');
        expect(charge.status.name, 'succeeded');
      });

      test('handles insufficient funds error', () async {
        when(() => mockDio.post(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenThrow(
          createDioException(
            statusCode: 402,
            data: {
              'error': {
                'code': 'insufficient_funds',
                'message': 'Insufficient funds',
              },
            },
          ),
        );

        expect(
          () => processor.createCharge(
            amount: 1000,
            currency: 'usd',
            customerId: 'cus_123',
          ),
          throwsA(isA<ProcessorException>()),
        );
      });
    });

    group('cancelSubscription', () {
      test('cancels subscription successfully', () async {
        final responseData = {
          'id': 'sub_123',
          'status': 'canceled',
          'canceled_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        };

        when(() => mockDio.delete(
              any(),
              options: any(named: 'options'),
            )).thenAnswer(
          (_) async => createSuccessResponse(responseData),
        );

        final subscription = await processor.cancelSubscription('sub_123');

        expect(subscription.id, 'sub_123');
        expect(subscription.status.name, 'canceled');
        verify(() => mockDio.delete(any(), options: any(named: 'options'))).called(1);
      });

      test('handles subscription not found', () async {
        when(() => mockDio.delete(
              any(),
              options: any(named: 'options'),
            )).thenThrow(
          createDioException(
            statusCode: 404,
            data: {'error': {'message': 'No such subscription'}},
          ),
        );

        expect(
          () => processor.cancelSubscription('sub_missing'),
          throwsA(isA<ProcessorException>()),
        );
      });
    });

    group('error handling', () {
      test('maps 401 errors to AuthenticationException', () async {
        when(() => mockDio.post(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenThrow(createDioException(statusCode: 401));

        expect(
          () => processor.createCustomer(email: 'test@example.com'),
          throwsA(isA<AuthenticationException>()),
        );
      });

      test('maps network errors to NetworkException', () async {
        when(() => mockDio.post(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenThrow(createNetworkError());

        expect(
          () => processor.createCustomer(email: 'test@example.com'),
          throwsA(isA<NetworkException>()),
        );
      });

      test('maps 4xx errors to ProcessorException', () async {
        when(() => mockDio.post(
              any(),
              data: any(named: 'data'),
              options: any(named: 'options'),
            )).thenThrow(createDioException(statusCode: 400));

        expect(
          () => processor.createCustomer(email: 'test@example.com'),
          throwsA(isA<ProcessorException>()),
        );
      });
    });
  });
}
