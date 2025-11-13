import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_universal_payments/src/models/customer.dart';
import 'package:flutter_universal_payments/src/models/enums.dart';
import 'package:flutter_universal_payments/src/services/storage.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mocks.dart';

void main() {
  group('StorageKeys', () {
    test('has correct key values', () {
      expect(StorageKeys.customerId, 'payment_customer_id');
      expect(StorageKeys.customerEmail, 'payment_customer_email');
      expect(StorageKeys.activeSubscriptionId, 'payment_active_subscription_id');
      expect(StorageKeys.processorType, 'payment_processor_type');
    });

    test('timestampKey generates correct format', () {
      expect(StorageKeys.timestampKey('test'), 'test_timestamp');
    });

    test('cacheKey generates correct format', () {
      expect(StorageKeys.cacheKey('test'), 'payment_cache_test');
    });
  });

  group('SharedPreferencesStorage', () {
    late MockSharedPreferences mockPrefs;
    late SharedPreferencesStorage storage;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      storage = SharedPreferencesStorage(
        getPreferences: () async => mockPrefs,
      );
    });

    group('getString', () {
      test('returns value when key exists', () async {
        when(() => mockPrefs.getString('test_key'))
            .thenReturn('test_value');

        final result = await storage.getString('test_key');

        expect(result, 'test_value');
        verify(() => mockPrefs.getString('test_key')).called(1);
      });

      test('returns null when key does not exist', () async {
        when(() => mockPrefs.getString('missing_key')).thenReturn(null);

        final result = await storage.getString('missing_key');

        expect(result, isNull);
      });
    });

    group('setString', () {
      test('stores string value', () async {
        when(() => mockPrefs.setString('test_key', 'test_value'))
            .thenAnswer((_) async => true);

        await storage.setString('test_key', 'test_value');

        verify(() => mockPrefs.setString('test_key', 'test_value')).called(1);
      });
    });

    group('getInt', () {
      test('returns integer when key exists', () async {
        when(() => mockPrefs.getInt('count')).thenReturn(42);

        final result = await storage.getInt('count');

        expect(result, 42);
      });

      test('returns null when key does not exist', () async {
        when(() => mockPrefs.getInt('missing')).thenReturn(null);

        final result = await storage.getInt('missing');

        expect(result, isNull);
      });
    });

    group('setInt', () {
      test('stores integer value', () async {
        when(() => mockPrefs.setInt('count', 42))
            .thenAnswer((_) async => true);

        await storage.setInt('count', 42);

        verify(() => mockPrefs.setInt('count', 42)).called(1);
      });
    });

    group('getBool', () {
      test('returns boolean when key exists', () async {
        when(() => mockPrefs.getBool('flag')).thenReturn(true);

        final result = await storage.getBool('flag');

        expect(result, true);
      });
    });

    group('setBool', () {
      test('stores boolean value', () async {
        when(() => mockPrefs.setBool('flag', true))
            .thenAnswer((_) async => true);

        await storage.setBool('flag', true);

        verify(() => mockPrefs.setBool('flag', true)).called(1);
      });
    });

    group('setObject', () {
      test('stores object as JSON with timestamp', () async {
        final customer = Customer(
          id: 'cus_123',
          email: 'test@example.com',
          processor: ProcessorType.stripe,
          processorCustomerId: 'stripe_cus_123',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        );

        when(() => mockPrefs.setString(any(), any()))
            .thenAnswer((_) async => true);
        when(() => mockPrefs.setInt(any(), any()))
            .thenAnswer((_) async => true);

        await storage.setObject('customer', customer, (c) => c.toJson());

        verify(() => mockPrefs.setString('customer', any())).called(1);
        verify(() => mockPrefs.setInt('customer_timestamp', any())).called(1);
      });

      test('throws StorageException on serialization error', () async {
        expect(
          () => storage.setObject('bad', Object(), (_) => throw Exception()),
          throwsA(isA<StorageException>()),
        );
      });
    });

    group('getObject', () {
      test('retrieves and deserializes object', () async {
        final jsonString = '{"id":"cus_123","email":"test@example.com",'
            '"processor":"stripe","processor_customer_id":"stripe_cus_123",'
            '"created_at":"2024-01-01T00:00:00.000","updated_at":"2024-01-01T00:00:00.000"}';

        when(() => mockPrefs.getString('customer')).thenReturn(jsonString);

        final result = await storage.getObject(
          'customer',
          (json) => Customer.fromJson(json),
        );

        expect(result, isNotNull);
        expect(result!.id, 'cus_123');
        expect(result.email, 'test@example.com');
      });

      test('returns null when key does not exist', () async {
        when(() => mockPrefs.getString('missing')).thenReturn(null);

        final result = await storage.getObject(
          'missing',
          (json) => Customer.fromJson(json),
        );

        expect(result, isNull);
      });

      test('removes corrupted data and returns null', () async {
        when(() => mockPrefs.getString('corrupted'))
            .thenReturn('invalid json');
        when(() => mockPrefs.remove(any())).thenAnswer((_) async => true);

        final result = await storage.getObject(
          'corrupted',
          (json) => Customer.fromJson(json),
        );

        expect(result, isNull);
        verify(() => mockPrefs.remove('corrupted')).called(1);
      });
    });

    group('remove', () {
      test('removes key and timestamp', () async {
        when(() => mockPrefs.remove(any())).thenAnswer((_) async => true);

        await storage.remove('test_key');

        verify(() => mockPrefs.remove('test_key')).called(1);
        verify(() => mockPrefs.remove('test_key_timestamp')).called(1);
      });
    });

    group('containsKey', () {
      test('returns true when key exists', () async {
        when(() => mockPrefs.containsKey('exists')).thenReturn(true);

        final result = await storage.containsKey('exists');

        expect(result, true);
      });

      test('returns false when key does not exist', () async {
        when(() => mockPrefs.containsKey('missing')).thenReturn(false);

        final result = await storage.containsKey('missing');

        expect(result, false);
      });
    });

    group('clear', () {
      test('clears all data', () async {
        when(() => mockPrefs.clear()).thenAnswer((_) async => true);

        await storage.clear();

        verify(() => mockPrefs.clear()).called(1);
      });
    });
  });

  group('SecureStorage', () {
    late MockFlutterSecureStorage mockSecureStorage;
    late SecureStorage storage;

    setUp(() {
      mockSecureStorage = MockFlutterSecureStorage();
      storage = SecureStorage(secureStorage: mockSecureStorage);
    });

    group('getString', () {
      test('reads value from secure storage', () async {
        when(() => mockSecureStorage.read(key: 'key'))
            .thenAnswer((_) async => 'value');

        final result = await storage.getString('key');

        expect(result, 'value');
      });
    });

    group('setString', () {
      test('writes value to secure storage', () async {
        when(() => mockSecureStorage.write(key: 'key', value: 'value'))
            .thenAnswer((_) async => {});

        await storage.setString('key', 'value');

        verify(() => mockSecureStorage.write(key: 'key', value: 'value')).called(1);
      });
    });

    group('getInt', () {
      test('parses integer from string', () async {
        when(() => mockSecureStorage.read(key: 'count'))
            .thenAnswer((_) async => '42');

        final result = await storage.getInt('count');

        expect(result, 42);
      });

      test('returns null for invalid integer', () async {
        when(() => mockSecureStorage.read(key: 'bad'))
            .thenAnswer((_) async => 'not_a_number');

        final result = await storage.getInt('bad');

        expect(result, isNull);
      });
    });

    group('getBool', () {
      test('parses true from string', () async {
        when(() => mockSecureStorage.read(key: 'flag'))
            .thenAnswer((_) async => 'true');

        final result = await storage.getBool('flag');

        expect(result, true);
      });

      test('parses false from string', () async {
        when(() => mockSecureStorage.read(key: 'flag'))
            .thenAnswer((_) async => 'false');

        final result = await storage.getBool('flag');

        expect(result, false);
      });

      test('is case insensitive', () async {
        when(() => mockSecureStorage.read(key: 'flag'))
            .thenAnswer((_) async => 'TRUE');

        final result = await storage.getBool('flag');

        expect(result, true);
      });
    });

    group('remove', () {
      test('deletes key and timestamp', () async {
        when(() => mockSecureStorage.delete(key: any(named: 'key')))
            .thenAnswer((_) async => {});

        await storage.remove('test_key');

        verify(() => mockSecureStorage.delete(key: 'test_key')).called(1);
        verify(() => mockSecureStorage.delete(key: 'test_key_timestamp')).called(1);
      });
    });

    group('clear', () {
      test('deletes all data', () async {
        when(() => mockSecureStorage.deleteAll()).thenAnswer((_) async => {});

        await storage.clear();

        verify(() => mockSecureStorage.deleteAll()).called(1);
      });
    });
  });

  group('CachedData', () {
    final testTime = DateTime(2024, 1, 1);

    test('creates with current timestamp using factory', () {
      final cached = CachedData.now('test data');

      expect(cached.data, 'test data');
      expect(cached.timestamp.isAfter(DateTime.now().subtract(const Duration(seconds: 1))), true);
      expect(cached.version, StorageKeys.currentCacheVersion);
    });

    test('converts to JSON correctly', () {
      final cached = CachedData(
        data: 'test',
        timestamp: testTime,
        version: 1,
      );

      final json = cached.toJson((data) => {'value': data});

      expect(json['data'], {'value': 'test'});
      expect(json['timestamp'], testTime.millisecondsSinceEpoch);
      expect(json['version'], 1);
    });

    test('creates from JSON correctly', () {
      final json = {
        'data': {'value': 'test'},
        'timestamp': testTime.millisecondsSinceEpoch,
        'version': 1,
      };

      final cached = CachedData.fromJson<String>(
        json,
        (data) => data['value'] as String,
      );

      expect(cached.data, 'test');
      expect(cached.timestamp, testTime);
      expect(cached.version, 1);
    });

    test('isExpired returns true for old data', () {
      final cached = CachedData(
        data: 'test',
        timestamp: DateTime.now().subtract(const Duration(hours: 25)),
      );

      expect(cached.isExpired(const Duration(hours: 24)), true);
    });

    test('isExpired returns false for fresh data', () {
      final cached = CachedData(
        data: 'test',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(cached.isExpired(const Duration(hours: 24)), false);
    });

    test('age returns correct duration', () {
      final cached = CachedData(
        data: 'test',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      );

      expect(cached.age.inHours, 2);
    });
  });

  group('StorageException', () {
    test('creates exception with message', () {
      final exception = StorageException('Test error');

      expect(exception.message, 'Test error');
      expect(exception.toString(), 'StorageException: Test error');
    });
  });
}
