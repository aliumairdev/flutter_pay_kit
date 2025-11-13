import 'dart:convert';

/// Storage keys for payment-related data.
///
/// These keys are used to store and retrieve payment data from storage.
/// IMPORTANT: Only store non-sensitive identifiers, never store card numbers or CVV.
class StorageKeys {
  /// Customer ID from payment processor
  static const String customerId = 'payment_customer_id';

  /// Customer email address
  static const String customerEmail = 'payment_customer_email';

  /// Active subscription ID
  static const String activeSubscriptionId = 'payment_active_subscription_id';

  /// Payment processor type (stripe, paddle, braintree, etc.)
  static const String processorType = 'payment_processor_type';

  /// Last sync timestamp in milliseconds since epoch
  static const String lastSyncTime = 'payment_last_sync_time';

  /// Cache version for migration support
  static const String cacheVersion = 'payment_cache_version';

  /// Current cache version number
  static const int currentCacheVersion = 1;

  /// Prefix for timestamp keys
  static String timestampKey(String key) => '${key}_timestamp';

  /// Prefix for cached object keys
  static String cacheKey(String key) => 'payment_cache_$key';
}

/// Abstract storage interface for caching payment data.
///
/// This interface provides a key-value storage abstraction that can be
/// implemented using SharedPreferences, secure storage, or any other storage mechanism.
abstract class Storage {
  /// Retrieves a string value for the given [key].
  ///
  /// Returns null if the key doesn't exist.
  Future<String?> getString(String key);

  /// Stores a string [value] for the given [key].
  Future<void> setString(String key, String value);

  /// Retrieves an integer value for the given [key].
  ///
  /// Returns null if the key doesn't exist.
  Future<int?> getInt(String key);

  /// Stores an integer [value] for the given [key].
  Future<void> setInt(String key, int value);

  /// Retrieves a boolean value for the given [key].
  ///
  /// Returns null if the key doesn't exist.
  Future<bool?> getBool(String key);

  /// Stores a boolean [value] for the given [key].
  Future<void> setBool(String key, bool value);

  /// Stores an object [object] for the given [key].
  ///
  /// The object is serialized to JSON before storage.
  /// The [toJson] function should convert the object to a Map.
  Future<void> setObject<T>(
    String key,
    T object,
    Map<String, dynamic> Function(T) toJson,
  );

  /// Retrieves an object for the given [key].
  ///
  /// The [fromJson] function should construct the object from a Map.
  /// Returns null if the key doesn't exist or deserialization fails.
  Future<T?> getObject<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  );

  /// Removes the value for the given [key].
  Future<void> remove(String key);

  /// Checks if a [key] exists in storage.
  Future<bool> containsKey(String key);

  /// Clears all stored data.
  Future<void> clear();
}

/// Implementation of [Storage] using SharedPreferences.
///
/// This is suitable for caching non-sensitive data such as:
/// - Customer IDs and email addresses
/// - Subscription status and IDs
/// - Configuration settings
/// - Cache timestamps
///
/// WARNING: DO NOT use this for sensitive data like:
/// - Payment card numbers
/// - CVV codes
/// - API keys or tokens
/// - Any PCI-sensitive information
class SharedPreferencesStorage implements Storage {
  final Future<dynamic> Function() _getPreferences;

  /// Creates a [SharedPreferencesStorage] instance.
  ///
  /// The [getPreferences] function should return a SharedPreferences instance.
  /// This is injected to avoid tight coupling to the package.
  SharedPreferencesStorage({
    required Future<dynamic> Function() getPreferences,
  }) : _getPreferences = getPreferences;

  @override
  Future<String?> getString(String key) async {
    final prefs = await _getPreferences();
    return prefs.getString(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    final prefs = await _getPreferences();
    await prefs.setString(key, value);
  }

  @override
  Future<int?> getInt(String key) async {
    final prefs = await _getPreferences();
    return prefs.getInt(key);
  }

  @override
  Future<void> setInt(String key, int value) async {
    final prefs = await _getPreferences();
    await prefs.setInt(key, value);
  }

  @override
  Future<bool?> getBool(String key) async {
    final prefs = await _getPreferences();
    return prefs.getBool(key);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    final prefs = await _getPreferences();
    await prefs.setBool(key, value);
  }

  @override
  Future<void> setObject<T>(
    String key,
    T object,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    try {
      final json = toJson(object);
      final jsonString = jsonEncode(json);
      await setString(key, jsonString);

      // Store timestamp for cache expiration
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await setInt(StorageKeys.timestampKey(key), timestamp);
    } catch (e) {
      throw StorageException('Failed to serialize object for key "$key": $e');
    }
  }

  @override
  Future<T?> getObject<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final jsonString = await getString(key);
      if (jsonString == null) return null;

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return fromJson(json);
    } catch (e) {
      // If deserialization fails, remove the corrupted data
      await remove(key);
      return null;
    }
  }

  @override
  Future<void> remove(String key) async {
    final prefs = await _getPreferences();
    await prefs.remove(key);
    // Also remove associated timestamp
    await prefs.remove(StorageKeys.timestampKey(key));
  }

  @override
  Future<bool> containsKey(String key) async {
    final prefs = await _getPreferences();
    return prefs.containsKey(key);
  }

  @override
  Future<void> clear() async {
    final prefs = await _getPreferences();
    await prefs.clear();
  }
}

/// Implementation of [Storage] using flutter_secure_storage.
///
/// This should be used for sensitive data such as:
/// - API keys (if needed on client)
/// - Authentication tokens
/// - Encrypted payment processor credentials
///
/// WARNING: Still DO NOT store:
/// - Payment card numbers
/// - CVV codes
/// - Any PCI-sensitive cardholder data
class SecureStorage implements Storage {
  final dynamic _secureStorage;

  /// Creates a [SecureStorage] instance.
  ///
  /// The [secureStorage] should be an instance of FlutterSecureStorage.
  /// This is injected to avoid tight coupling to the package.
  SecureStorage({
    required dynamic secureStorage,
  }) : _secureStorage = secureStorage;

  @override
  Future<String?> getString(String key) async {
    return await _secureStorage.read(key: key);
  }

  @override
  Future<void> setString(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  @override
  Future<int?> getInt(String key) async {
    final value = await getString(key);
    return value != null ? int.tryParse(value) : null;
  }

  @override
  Future<void> setInt(String key, int value) async {
    await setString(key, value.toString());
  }

  @override
  Future<bool?> getBool(String key) async {
    final value = await getString(key);
    if (value == null) return null;
    return value.toLowerCase() == 'true';
  }

  @override
  Future<void> setBool(String key, bool value) async {
    await setString(key, value.toString());
  }

  @override
  Future<void> setObject<T>(
    String key,
    T object,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    try {
      final json = toJson(object);
      final jsonString = jsonEncode(json);
      await setString(key, jsonString);

      // Store timestamp for cache expiration
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await setInt(StorageKeys.timestampKey(key), timestamp);
    } catch (e) {
      throw StorageException('Failed to serialize object for key "$key": $e');
    }
  }

  @override
  Future<T?> getObject<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final jsonString = await getString(key);
      if (jsonString == null) return null;

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return fromJson(json);
    } catch (e) {
      // If deserialization fails, remove the corrupted data
      await remove(key);
      return null;
    }
  }

  @override
  Future<void> remove(String key) async {
    await _secureStorage.delete(key: key);
    // Also remove associated timestamp
    await _secureStorage.delete(key: StorageKeys.timestampKey(key));
  }

  @override
  Future<bool> containsKey(String key) async {
    final value = await _secureStorage.read(key: key);
    return value != null;
  }

  @override
  Future<void> clear() async {
    await _secureStorage.deleteAll();
  }
}

/// Exception thrown when storage operations fail.
class StorageException implements Exception {
  final String message;

  StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}

/// Helper class for cache expiration management.
///
/// This class provides utilities for checking if cached data is stale
/// and should be refreshed.
class CacheExpiration {
  final Storage _storage;
  final Duration _defaultExpiration;

  /// Creates a [CacheExpiration] instance.
  ///
  /// [storage] is the storage instance to use for timestamp retrieval.
  /// [defaultExpiration] is the default duration after which cache is considered stale.
  CacheExpiration({
    required Storage storage,
    Duration defaultExpiration = const Duration(hours: 24),
  })  : _storage = storage,
        _defaultExpiration = defaultExpiration;

  /// Checks if the cached data for [key] is expired.
  ///
  /// Returns true if:
  /// - The key has no timestamp
  /// - The timestamp is older than [expiration] (or default if not provided)
  ///
  /// Returns false if the cache is still valid.
  Future<bool> isExpired(String key, {Duration? expiration}) async {
    final timestamp = await _storage.getInt(StorageKeys.timestampKey(key));
    if (timestamp == null) return true;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final expirationDuration = expiration ?? _defaultExpiration;
    final expiryTime = cacheTime.add(expirationDuration);

    return DateTime.now().isAfter(expiryTime);
  }

  /// Checks if the cached data for [key] is still valid.
  ///
  /// This is the inverse of [isExpired].
  Future<bool> isValid(String key, {Duration? expiration}) async {
    return !(await isExpired(key, expiration: expiration));
  }

  /// Gets the age of the cached data for [key].
  ///
  /// Returns null if the key has no timestamp.
  Future<Duration?> getAge(String key) async {
    final timestamp = await _storage.getInt(StorageKeys.timestampKey(key));
    if (timestamp == null) return null;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cacheTime);
  }

  /// Gets the remaining time before cache expires.
  ///
  /// Returns null if the key has no timestamp or is already expired.
  Future<Duration?> getRemainingTime(String key, {Duration? expiration}) async {
    final timestamp = await _storage.getInt(StorageKeys.timestampKey(key));
    if (timestamp == null) return null;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final expirationDuration = expiration ?? _defaultExpiration;
    final expiryTime = cacheTime.add(expirationDuration);

    if (DateTime.now().isAfter(expiryTime)) return null;

    return expiryTime.difference(DateTime.now());
  }
}

/// Helper class for serializing and deserializing objects.
///
/// This provides convenience methods for common serialization patterns.
class SerializationHelper {
  /// Serializes a list of objects to JSON.
  static List<Map<String, dynamic>> serializeList<T>(
    List<T> items,
    Map<String, dynamic> Function(T) toJson,
  ) {
    return items.map(toJson).toList();
  }

  /// Deserializes a list of objects from JSON.
  ///
  /// Returns an empty list if [jsonList] is null or deserialization fails.
  static List<T> deserializeList<T>(
    List<dynamic>? jsonList,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (jsonList == null) return [];

    try {
      return jsonList
          .whereType<Map<String, dynamic>>()
          .map(fromJson)
          .toList();
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }

  /// Safely serializes an object, returning null on error.
  static Map<String, dynamic>? safeSerialize<T>(
    T? object,
    Map<String, dynamic> Function(T) toJson,
  ) {
    if (object == null) return null;

    try {
      return toJson(object);
    } catch (e) {
      return null;
    }
  }

  /// Safely deserializes an object, returning null on error.
  static T? safeDeserialize<T>(
    Map<String, dynamic>? json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (json == null) return null;

    try {
      return fromJson(json);
    } catch (e) {
      return null;
    }
  }
}

/// Wrapper for cached data with metadata.
///
/// This class wraps cached data with additional metadata such as
/// timestamp and version information.
class CachedData<T> {
  final T data;
  final DateTime timestamp;
  final int version;

  CachedData({
    required this.data,
    required this.timestamp,
    this.version = StorageKeys.currentCacheVersion,
  });

  /// Creates a [CachedData] instance with current timestamp.
  factory CachedData.now(T data) {
    return CachedData(
      data: data,
      timestamp: DateTime.now(),
    );
  }

  /// Converts to JSON for storage.
  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) dataToJson) {
    return {
      'data': dataToJson(data),
      'timestamp': timestamp.millisecondsSinceEpoch,
      'version': version,
    };
  }

  /// Creates from JSON.
  static CachedData<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) dataFromJson,
  ) {
    return CachedData(
      data: dataFromJson(json['data'] as Map<String, dynamic>),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      version: json['version'] as int? ?? StorageKeys.currentCacheVersion,
    );
  }

  /// Checks if this cached data is expired.
  bool isExpired(Duration expiration) {
    final expiryTime = timestamp.add(expiration);
    return DateTime.now().isAfter(expiryTime);
  }

  /// Checks if this cached data is still valid.
  bool isValid(Duration expiration) => !isExpired(expiration);

  /// Gets the age of this cached data.
  Duration get age => DateTime.now().difference(timestamp);
}

/// Storage manager with cache expiration and versioning.
///
/// This class provides a higher-level interface for managing cached data
/// with automatic expiration handling and version migration.
class CachedStorageManager {
  final Storage _storage;
  final Duration _defaultExpiration;

  CachedStorageManager({
    required Storage storage,
    Duration defaultExpiration = const Duration(hours: 24),
  })  : _storage = storage,
        _defaultExpiration = defaultExpiration;

  /// Stores data with cache metadata.
  Future<void> setCachedData<T>(
    String key,
    T data,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    final cachedData = CachedData.now(data);
    await _storage.setObject(
      key,
      cachedData,
      (cd) => cd.toJson(toJson),
    );
  }

  /// Retrieves cached data if valid, null if expired or missing.
  Future<T?> getCachedData<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson, {
    Duration? expiration,
  }) async {
    final cachedData = await _storage.getObject<CachedData<T>>(
      key,
      (json) => CachedData.fromJson(json, fromJson),
    );

    if (cachedData == null) return null;

    // Check if cache is expired
    final expirationDuration = expiration ?? _defaultExpiration;
    if (cachedData.isExpired(expirationDuration)) {
      await _storage.remove(key);
      return null;
    }

    // Check version compatibility
    if (cachedData.version != StorageKeys.currentCacheVersion) {
      await _storage.remove(key);
      return null;
    }

    return cachedData.data;
  }

  /// Gets cached data or fetches new data if expired.
  Future<T> getOrFetch<T>(
    String key,
    Future<T> Function() fetch,
    Map<String, dynamic> Function(T) toJson,
    T Function(Map<String, dynamic>) fromJson, {
    Duration? expiration,
  }) async {
    // Try to get cached data
    final cached = await getCachedData(key, fromJson, expiration: expiration);
    if (cached != null) return cached;

    // Fetch new data
    final data = await fetch();

    // Cache it
    await setCachedData(key, data, toJson);

    return data;
  }

  /// Clears all payment-related cache.
  Future<void> clearPaymentCache() async {
    final keys = [
      StorageKeys.customerId,
      StorageKeys.customerEmail,
      StorageKeys.activeSubscriptionId,
      StorageKeys.processorType,
      StorageKeys.lastSyncTime,
    ];

    for (final key in keys) {
      await _storage.remove(key);
    }
  }

  /// Checks cache version and clears if outdated.
  Future<void> checkAndMigrateCacheVersion() async {
    final storedVersion = await _storage.getInt(StorageKeys.cacheVersion);

    if (storedVersion == null ||
        storedVersion != StorageKeys.currentCacheVersion) {
      // Clear all cache on version mismatch
      await _storage.clear();
      await _storage.setInt(
        StorageKeys.cacheVersion,
        StorageKeys.currentCacheVersion,
      );
    }
  }
}
