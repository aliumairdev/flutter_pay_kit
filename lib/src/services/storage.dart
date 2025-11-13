/// Abstract storage interface for caching payment data.
///
/// This interface provides a simple key-value storage abstraction that can be
/// implemented using SharedPreferences, secure storage, or any other storage mechanism.
abstract class Storage {
  /// Retrieves a string value for the given [key].
  ///
  /// Returns null if the key doesn't exist.
  Future<String?> getString(String key);

  /// Stores a string [value] for the given [key].
  Future<void> setString(String key, String value);

  /// Removes the value for the given [key].
  Future<void> remove(String key);

  /// Checks if a [key] exists in storage.
  Future<bool> containsKey(String key);

  /// Clears all stored data.
  Future<void> clear();
}

/// Implementation of [Storage] using SharedPreferences.
///
/// This is a simple, insecure storage suitable for caching non-sensitive data.
/// For sensitive data like payment tokens, consider using flutter_secure_storage.
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
  Future<void> remove(String key) async {
    final prefs = await _getPreferences();
    await prefs.remove(key);
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
