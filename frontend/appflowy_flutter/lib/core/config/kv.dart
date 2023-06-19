import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-config/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class KeyValueStorage {
  Future<void> set(String key, String value);
  Future<Either<FlowyError, String>> get(String key);
  Future<void> remove(String key);
  Future<void> clear();
}

class DartKeyValue implements KeyValueStorage {
  SharedPreferences? _sharedPreferences;
  SharedPreferences get sharedPreferences => _sharedPreferences!;

  @override
  Future<Either<FlowyError, String>> get(String key) async {
    await _initSharedPreferencesIfNeeded();

    final value = sharedPreferences.getString(key);
    if (value != null) {
      return Right(value);
    }
    return Left(FlowyError());
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

/// Key-value store
/// The data is stored in the local storage of the device.
class RustKeyValue implements KeyValueStorage {
  @override
  Future<void> set(String key, String value) async {
    await ConfigEventSetKeyValue(
      KeyValuePB.create()
        ..key = key
        ..value = value,
    ).send();
  }

  @override
  Future<Either<FlowyError, String>> get(String key) async {
    final payload = KeyPB.create()..key = key;
    final response = await ConfigEventGetKeyValue(payload).send();
    return response.swap().map((r) => r.value);
  }

  @override
  Future<void> remove(String key) async {
    await ConfigEventRemoveKeyValue(
      KeyPB.create()..key = key,
    ).send();
  }

  @override
  Future<void> clear() async {
    // TODO(Lucas): implement clear
  }
}
