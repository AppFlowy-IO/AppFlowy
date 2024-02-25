import 'package:shared_preferences/shared_preferences.dart';

abstract class KeyValueStorage {
  Future<void> set(String key, String value);
  Future<String?> get(String key);
  Future<T?> getWithFormat<T>(
    String key,
    T Function(String value) formatter,
  );
  Future<void> remove(String key);
  Future<void> clear();
}

class DartKeyValue implements KeyValueStorage {
  SharedPreferences? _sharedPreferences;
  SharedPreferences get sharedPreferences => _sharedPreferences!;

  @override
  Future<String?> get(String key) async {
    await _initSharedPreferencesIfNeeded();

    final value = sharedPreferences.getString(key);
    if (value != null) {
      return value;
    }
    return null;
  }

  @override
  Future<T?> getWithFormat<T>(
    String key,
    T Function(String value) formatter,
  ) async {
    final value = await get(key);
    if (value == null) {
      return null;
    }
    return formatter(value);
  }

  @override
  Future<void> remove(String key) async {
    await _initSharedPreferencesIfNeeded();

    await sharedPreferences.remove(key);
  }

  @override
  Future<void> set(String key, String value) async {
    await _initSharedPreferencesIfNeeded();

    await sharedPreferences.setString(key, value);
  }

  @override
  Future<void> clear() async {
    await _initSharedPreferencesIfNeeded();

    await sharedPreferences.clear();
  }

  Future<void> _initSharedPreferencesIfNeeded() async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
  }
}
