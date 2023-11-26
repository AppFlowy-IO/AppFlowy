import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class KeyValueStorage {
  Future<void> set(String key, String value);
  Future<Option<String>> get(String key);
  Future<Option<T>> getWithFormat<T>(
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
  Future<Option<String>> get(String key) async {
    await _initSharedPreferencesIfNeeded();

    final value = sharedPreferences.getString(key);
    if (value != null) {
      return Some(value);
    }
    return none();
  }

  @override
  Future<Option<T>> getWithFormat<T>(
    String key,
    T Function(String value) formatter,
  ) async {
    final value = await get(key);
    return value.fold(
      () => none(),
      (s) => Some(formatter(s)),
    );
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
