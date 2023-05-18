import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-config/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:dartz/dartz.dart';

abstract class KeyValueStorage {
  Future<void> set(String key, String value);
  Future<Either<FlowyError, String>> get(String key);
  Future<void> remove(String key);
}

/// Key-value store
/// The data is stored in the local storage of the device.
class KeyValue implements KeyValueStorage {
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
}
