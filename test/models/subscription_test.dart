import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_universal_payments/src/models/enums.dart';
import 'package:flutter_universal_payments/src/models/subscription.dart';

void main() {
  group('Subscription', () {
    final testCurrentPeriodStart = DateTime(2024, 1, 1);
    final testCurrentPeriodEnd = DateTime(2024, 2, 1);

    group('constructor', () {
      test('creates subscription with all required fields', () {
        final subscription = Subscription(
          id: 'sub_123',
          customerId: 'cus_123',
          status: SubscriptionStatus.active,
          priceId: 'price_123',
          productId: 'prod_123',
          currentPeriodStart: testCurrentPeriodStart,
          currentPeriodEnd: testCurrentPeriodEnd,
          cancelAtPeriodEnd: false,
          quantity: 1,
          processor: ProcessorType.stripe,
          processorSubscriptionId: 'stripe_sub_123',
        );

        expect(subscription.id, 'sub_123');
        expect(subscription.customerId, 'cus_123');
        expect(subscription.status, SubscriptionStatus.active);
        expect(subscription.priceId, 'price_123');
        expect(subscription.productId, 'prod_123');
        expect(subscription.currentPeriodStart, testCurrentPeriodStart);
        expect(subscription.currentPeriodEnd, testCurrentPeriodEnd);
        expect(subscription.cancelAtPeriodEnd, false);
        expect(subscription.quantity, 1);
        expect(subscription.processor, ProcessorType.stripe);
        expect(subscription.processorSubscriptionId, 'stripe_sub_123');
      });

      test('creates subscription with optional fields', () {
        final trialStart = DateTime(2023, 12, 1);
        final trialEnd = DateTime(2023, 12, 31);
        final canceledAt = DateTime(2024, 1, 15);

        final subscription = Subscription(
          id: 'sub_123',
          customerId: 'cus_123',
          status: SubscriptionStatus.canceled,
          priceId: 'price_123',
          productId: 'prod_123',
          currentPeriodStart: testCurrentPeriodStart,
          currentPeriodEnd: testCurrentPeriodEnd,
          trialStart: trialStart,
          trialEnd: trialEnd,
          canceledAt: canceledAt,
          cancelAtPeriodEnd: true,
          quantity: 5,
          processor: ProcessorType.paddle,
          processorSubscriptionId: 'paddle_sub_123',
          metadata: {'key': 'value'},
        );

        expect(subscription.trialStart, trialStart);
        expect(subscription.trialEnd, trialEnd);
        expect(subscription.canceledAt, canceledAt);
        expect(subscription.metadata, {'key': 'value'});
      });
    });

    group('computed properties', () {
      group('isActive', () {
        test('returns true when status is active', () {
          final subscription = Subscription(
            id: 'sub_123',
            customerId: 'cus_123',
            status: SubscriptionStatus.active,
            priceId: 'price_123',
            productId: 'prod_123',
            currentPeriodStart: testCurrentPeriodStart,
            currentPeriodEnd: testCurrentPeriodEnd,
            cancelAtPeriodEnd: false,
            quantity: 1,
            processor: ProcessorType.stripe,
            processorSubscriptionId: 'stripe_sub_123',
          );

          expect(subscription.isActive, true);
        });

        test('returns false when status is not active', () {
          final subscription = Subscription(
            id: 'sub_123',
            customerId: 'cus_123',
            status: SubscriptionStatus.canceled,
            priceId: 'price_123',
            productId: 'prod_123',
            currentPeriodStart: testCurrentPeriodStart,
            currentPeriodEnd: testCurrentPeriodEnd,
            cancelAtPeriodEnd: false,
            quantity: 1,
            processor: ProcessorType.stripe,
            processorSubscriptionId: 'stripe_sub_123',
          );

          expect(subscription.isActive, false);
        });
      });

      group('isOnTrial', () {
        test('returns true when trialing with future trial end', () {
          final futureTrialEnd = DateTime.now().add(const Duration(days: 7));

          final subscription = Subscription(
            id: 'sub_123',
            customerId: 'cus_123',
            status: SubscriptionStatus.trialing,
            priceId: 'price_123',
            productId: 'prod_123',
            currentPeriodStart: testCurrentPeriodStart,
            currentPeriodEnd: testCurrentPeriodEnd,
            trialEnd: futureTrialEnd,
            cancelAtPeriodEnd: false,
            quantity: 1,
            processor: ProcessorType.stripe,
            processorSubscriptionId: 'stripe_sub_123',
          );

          expect(subscription.isOnTrial, true);
        });

        test('returns false when trialing with past trial end', () {
          final pastTrialEnd = DateTime.now().subtract(const Duration(days: 7));

          final subscription = Subscription(
            id: 'sub_123',
            customerId: 'cus_123',
            status: SubscriptionStatus.trialing,
            priceId: 'price_123',
            productId: 'prod_123',
            currentPeriodStart: testCurrentPeriodStart,
            currentPeriodEnd: testCurrentPeriodEnd,
            trialEnd: pastTrialEnd,
            cancelAtPeriodEnd: false,
            quantity: 1,
            processor: ProcessorType.stripe,
            processorSubscriptionId: 'stripe_sub_123',
          );

          expect(subscription.isOnTrial, false);
        });

        test('returns false when status is not trialing', () {
          final futureTrialEnd = DateTime.now().add(const Duration(days: 7));

          final subscription = Subscription(
            id: 'sub_123',
            customerId: 'cus_123',
            status: SubscriptionStatus.active,
            priceId: 'price_123',
            productId: 'prod_123',
            currentPeriodStart: testCurrentPeriodStart,
            currentPeriodEnd: testCurrentPeriodEnd,
            trialEnd: futureTrialEnd,
            cancelAtPeriodEnd: false,
            quantity: 1,
            processor: ProcessorType.stripe,
            processorSubscriptionId: 'stripe_sub_123',
          );

          expect(subscription.isOnTrial, false);
        });

        test('returns false when trial end is null', () {
          final subscription = Subscription(
            id: 'sub_123',
            customerId: 'cus_123',
            status: SubscriptionStatus.trialing,
            priceId: 'price_123',
            productId: 'prod_123',
            currentPeriodStart: testCurrentPeriodStart,
            currentPeriodEnd: testCurrentPeriodEnd,
            cancelAtPeriodEnd: false,
            quantity: 1,
            processor: ProcessorType.stripe,
            processorSubscriptionId: 'stripe_sub_123',
          );

          expect(subscription.isOnTrial, false);
        });
      });

      group('isCanceled', () {
        test('returns true when status is canceled', () {
          final subscription = Subscription(
            id: 'sub_123',
            customerId: 'cus_123',
            status: SubscriptionStatus.canceled,
            priceId: 'price_123',
            productId: 'prod_123',
            currentPeriodStart: testCurrentPeriodStart,
            currentPeriodEnd: testCurrentPeriodEnd,
            cancelAtPeriodEnd: false,
            quantity: 1,
            processor: ProcessorType.stripe,
            processorSubscriptionId: 'stripe_sub_123',
          );

          expect(subscription.isCanceled, true);
        });

        test('returns false when status is not canceled', () {
          final subscription = Subscription(
            id: 'sub_123',
            customerId: 'cus_123',
            status: SubscriptionStatus.active,
            priceId: 'price_123',
            productId: 'prod_123',
            currentPeriodStart: testCurrentPeriodStart,
            currentPeriodEnd: testCurrentPeriodEnd,
            cancelAtPeriodEnd: false,
            quantity: 1,
            processor: ProcessorType.stripe,
            processorSubscriptionId: 'stripe_sub_123',
          );

          expect(subscription.isCanceled, false);
        });
      });

      group('isOnGracePeriod', () {
        test('returns true when canceled but within current period', () {
          final futurePeriodEnd = DateTime.now().add(const Duration(days: 15));
          final canceledAt = DateTime.now();

          final subscription = Subscription(
            id: 'sub_123',
            customerId: 'cus_123',
            status: SubscriptionStatus.active,
            priceId: 'price_123',
            productId: 'prod_123',
            currentPeriodStart: testCurrentPeriodStart,
            currentPeriodEnd: futurePeriodEnd,
            canceledAt: canceledAt,
            cancelAtPeriodEnd: true,
            quantity: 1,
            processor: ProcessorType.stripe,
            processorSubscriptionId: 'stripe_sub_123',
          );

          expect(subscription.isOnGracePeriod, true);
        });

        test('returns false when cancelAtPeriodEnd is false', () {
          final futurePeriodEnd = DateTime.now().add(const Duration(days: 15));
          final canceledAt = DateTime.now();

          final subscription = Subscription(
            id: 'sub_123',
            customerId: 'cus_123',
            status: SubscriptionStatus.active,
            priceId: 'price_123',
            productId: 'prod_123',
            currentPeriodStart: testCurrentPeriodStart,
            currentPeriodEnd: futurePeriodEnd,
            canceledAt: canceledAt,
            cancelAtPeriodEnd: false,
            quantity: 1,
            processor: ProcessorType.stripe,
            processorSubscriptionId: 'stripe_sub_123',
          );

          expect(subscription.isOnGracePeriod, false);
        });

        test('returns false when canceledAt is null', () {
          final futurePeriodEnd = DateTime.now().add(const Duration(days: 15));

          final subscription = Subscription(
            id: 'sub_123',
            customerId: 'cus_123',
            status: SubscriptionStatus.active,
            priceId: 'price_123',
            productId: 'prod_123',
            currentPeriodStart: testCurrentPeriodStart,
            currentPeriodEnd: futurePeriodEnd,
            cancelAtPeriodEnd: true,
            quantity: 1,
            processor: ProcessorType.stripe,
            processorSubscriptionId: 'stripe_sub_123',
          );

          expect(subscription.isOnGracePeriod, false);
        });

        test('returns false when current period has ended', () {
          final pastPeriodEnd = DateTime.now().subtract(const Duration(days: 1));
          final canceledAt = DateTime.now().subtract(const Duration(days: 5));

          final subscription = Subscription(
            id: 'sub_123',
            customerId: 'cus_123',
            status: SubscriptionStatus.canceled,
            priceId: 'price_123',
            productId: 'prod_123',
            currentPeriodStart: testCurrentPeriodStart,
            currentPeriodEnd: pastPeriodEnd,
            canceledAt: canceledAt,
            cancelAtPeriodEnd: true,
            quantity: 1,
            processor: ProcessorType.stripe,
            processorSubscriptionId: 'stripe_sub_123',
          );

          expect(subscription.isOnGracePeriod, false);
        });
      });

      group('daysUntilDue', () {
        test('returns null when status is not past_due', () {
          final subscription = Subscription(
            id: 'sub_123',
            customerId: 'cus_123',
            status: SubscriptionStatus.active,
            priceId: 'price_123',
            productId: 'prod_123',
            currentPeriodStart: testCurrentPeriodStart,
            currentPeriodEnd: testCurrentPeriodEnd,
            cancelAtPeriodEnd: false,
            quantity: 1,
            processor: ProcessorType.stripe,
            processorSubscriptionId: 'stripe_sub_123',
          );

          expect(subscription.daysUntilDue, isNull);
        });

        test('returns positive number when still in grace period', () {
          final pastPeriodEnd = DateTime.now().subtract(const Duration(days: 2));

          final subscription = Subscription(
            id: 'sub_123',
            customerId: 'cus_123',
            status: SubscriptionStatus.pastDue,
            priceId: 'price_123',
            productId: 'prod_123',
            currentPeriodStart: testCurrentPeriodStart,
            currentPeriodEnd: pastPeriodEnd,
            cancelAtPeriodEnd: false,
            quantity: 1,
            processor: ProcessorType.stripe,
            processorSubscriptionId: 'stripe_sub_123',
          );

          expect(subscription.daysUntilDue, 5); // 7 - 2 = 5 days remaining
        });

        test('returns negative number when grace period has passed', () {
          final pastPeriodEnd = DateTime.now().subtract(const Duration(days: 10));

          final subscription = Subscription(
            id: 'sub_123',
            customerId: 'cus_123',
            status: SubscriptionStatus.pastDue,
            priceId: 'price_123',
            productId: 'prod_123',
            currentPeriodStart: testCurrentPeriodStart,
            currentPeriodEnd: pastPeriodEnd,
            cancelAtPeriodEnd: false,
            quantity: 1,
            processor: ProcessorType.stripe,
            processorSubscriptionId: 'stripe_sub_123',
          );

          expect(subscription.daysUntilDue, -3); // 7 - 10 = -3 days overdue
        });
      });
    });

    group('JSON serialization', () {
      test('converts to JSON correctly', () {
        final subscription = Subscription(
          id: 'sub_123',
          customerId: 'cus_123',
          status: SubscriptionStatus.active,
          priceId: 'price_123',
          productId: 'prod_123',
          currentPeriodStart: testCurrentPeriodStart,
          currentPeriodEnd: testCurrentPeriodEnd,
          cancelAtPeriodEnd: false,
          quantity: 2,
          processor: ProcessorType.paddle,
          processorSubscriptionId: 'paddle_sub_123',
          metadata: {'key': 'value'},
        );

        final json = subscription.toJson();

        expect(json['id'], 'sub_123');
        expect(json['customer_id'], 'cus_123');
        expect(json['status'], 'active');
        expect(json['price_id'], 'price_123');
        expect(json['product_id'], 'prod_123');
        expect(json['current_period_start'], testCurrentPeriodStart.toIso8601String());
        expect(json['current_period_end'], testCurrentPeriodEnd.toIso8601String());
        expect(json['cancel_at_period_end'], false);
        expect(json['quantity'], 2);
        expect(json['processor'], 'paddle');
        expect(json['processor_subscription_id'], 'paddle_sub_123');
        expect(json['metadata'], {'key': 'value'});
      });

      test('converts from JSON correctly', () {
        final json = {
          'id': 'sub_123',
          'customer_id': 'cus_123',
          'status': 'trialing',
          'price_id': 'price_123',
          'product_id': 'prod_123',
          'current_period_start': testCurrentPeriodStart.toIso8601String(),
          'current_period_end': testCurrentPeriodEnd.toIso8601String(),
          'cancel_at_period_end': true,
          'quantity': 3,
          'processor': 'lemon_squeezy',
          'processor_subscription_id': 'ls_sub_123',
        };

        final subscription = Subscription.fromJson(json);

        expect(subscription.id, 'sub_123');
        expect(subscription.customerId, 'cus_123');
        expect(subscription.status, SubscriptionStatus.trialing);
        expect(subscription.priceId, 'price_123');
        expect(subscription.productId, 'prod_123');
        expect(subscription.quantity, 3);
        expect(subscription.processor, ProcessorType.lemonSqueezy);
      });

      test('round-trip serialization preserves data', () {
        final original = Subscription(
          id: 'sub_123',
          customerId: 'cus_123',
          status: SubscriptionStatus.active,
          priceId: 'price_123',
          productId: 'prod_123',
          currentPeriodStart: testCurrentPeriodStart,
          currentPeriodEnd: testCurrentPeriodEnd,
          cancelAtPeriodEnd: false,
          quantity: 1,
          processor: ProcessorType.stripe,
          processorSubscriptionId: 'stripe_sub_123',
          metadata: {'key': 'value'},
        );

        final json = original.toJson();
        final deserialized = Subscription.fromJson(json);

        expect(deserialized, equals(original));
      });
    });

    group('copyWith', () {
      test('copies with new values', () {
        final original = Subscription(
          id: 'sub_123',
          customerId: 'cus_123',
          status: SubscriptionStatus.active,
          priceId: 'price_123',
          productId: 'prod_123',
          currentPeriodStart: testCurrentPeriodStart,
          currentPeriodEnd: testCurrentPeriodEnd,
          cancelAtPeriodEnd: false,
          quantity: 1,
          processor: ProcessorType.stripe,
          processorSubscriptionId: 'stripe_sub_123',
        );

        final copy = original.copyWith(
          status: SubscriptionStatus.canceled,
          cancelAtPeriodEnd: true,
          quantity: 5,
        );

        expect(copy.status, SubscriptionStatus.canceled);
        expect(copy.cancelAtPeriodEnd, true);
        expect(copy.quantity, 5);
        expect(copy.id, original.id);
        expect(copy.customerId, original.customerId);
      });

      test('copies without changes returns equal object', () {
        final original = Subscription(
          id: 'sub_123',
          customerId: 'cus_123',
          status: SubscriptionStatus.active,
          priceId: 'price_123',
          productId: 'prod_123',
          currentPeriodStart: testCurrentPeriodStart,
          currentPeriodEnd: testCurrentPeriodEnd,
          cancelAtPeriodEnd: false,
          quantity: 1,
          processor: ProcessorType.stripe,
          processorSubscriptionId: 'stripe_sub_123',
        );

        final copy = original.copyWith();

        expect(copy, equals(original));
      });
    });

    group('equality', () {
      test('equals when all fields match', () {
        final subscription1 = Subscription(
          id: 'sub_123',
          customerId: 'cus_123',
          status: SubscriptionStatus.active,
          priceId: 'price_123',
          productId: 'prod_123',
          currentPeriodStart: testCurrentPeriodStart,
          currentPeriodEnd: testCurrentPeriodEnd,
          cancelAtPeriodEnd: false,
          quantity: 1,
          processor: ProcessorType.stripe,
          processorSubscriptionId: 'stripe_sub_123',
        );

        final subscription2 = Subscription(
          id: 'sub_123',
          customerId: 'cus_123',
          status: SubscriptionStatus.active,
          priceId: 'price_123',
          productId: 'prod_123',
          currentPeriodStart: testCurrentPeriodStart,
          currentPeriodEnd: testCurrentPeriodEnd,
          cancelAtPeriodEnd: false,
          quantity: 1,
          processor: ProcessorType.stripe,
          processorSubscriptionId: 'stripe_sub_123',
        );

        expect(subscription1, equals(subscription2));
        expect(subscription1.hashCode, equals(subscription2.hashCode));
      });

      test('not equals when fields differ', () {
        final subscription1 = Subscription(
          id: 'sub_123',
          customerId: 'cus_123',
          status: SubscriptionStatus.active,
          priceId: 'price_123',
          productId: 'prod_123',
          currentPeriodStart: testCurrentPeriodStart,
          currentPeriodEnd: testCurrentPeriodEnd,
          cancelAtPeriodEnd: false,
          quantity: 1,
          processor: ProcessorType.stripe,
          processorSubscriptionId: 'stripe_sub_123',
        );

        final subscription2 = Subscription(
          id: 'sub_456',
          customerId: 'cus_123',
          status: SubscriptionStatus.active,
          priceId: 'price_123',
          productId: 'prod_123',
          currentPeriodStart: testCurrentPeriodStart,
          currentPeriodEnd: testCurrentPeriodEnd,
          cancelAtPeriodEnd: false,
          quantity: 1,
          processor: ProcessorType.stripe,
          processorSubscriptionId: 'stripe_sub_123',
        );

        expect(subscription1, isNot(equals(subscription2)));
      });
    });
  });
}
