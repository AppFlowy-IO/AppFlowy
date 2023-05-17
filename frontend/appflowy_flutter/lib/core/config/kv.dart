import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-config/entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:dartz/dartz.dart';

/// Key-value store
/// The data is stored in the local storage of the device.
class KeyValue {
  static Future<void> set(String key, String value) async {
    await ConfigEventSetKeyValue(
      KeyValuePB.create()
        ..key = key
        ..value = value,
    ).send();
  }

  static Future<Either<String, FlowyError>> get(String key) {
    return ConfigEventGetKeyValue(
      KeyPB.create()..key = key,
    ).send().then(
          (result) => result.fold(
            (pb) => left(pb.value),
            (error) => right(error),
          ),
        );
  }

  static Future<void> remove(String key) async {
    await ConfigEventRemoveKeyValue(
      KeyPB.create()..key = key,
    ).send();
  }
}
