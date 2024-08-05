import 'dart:async';
import 'dart:typed_data';

import 'package:appflowy/core/notification/notification_helper.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-notification/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-storage/notification.pb.dart';
import 'package:appflowy_backend/rust_stream.dart';
import 'package:appflowy_result/appflowy_result.dart';

class StoregeNotificationParser
    extends NotificationParser<StorageNotification, FlowyError> {
  StoregeNotificationParser({
    super.id,
    required super.callback,
  }) : super(
          tyParser: (ty, source) =>
              source == "storage" ? StorageNotification.valueOf(ty) : null,
          errorParser: (bytes) => FlowyError.fromBuffer(bytes),
        );
}

class StoreageNotificationListener {
  StoreageNotificationListener({
    void Function(FlowyError error)? onError,
  }) : _parser = StoregeNotificationParser(
          callback: (
            StorageNotification ty,
            FlowyResult<Uint8List, FlowyError> result,
          ) {
            result.fold(
              (data) {
                try {
                  switch (ty) {
                    case StorageNotification.FileStorageLimitExceeded:
                      onError?.call(FlowyError.fromBuffer(data));
                      break;
                  }
                } catch (e) {
                  Log.error(
                    "$StoreageNotificationListener deserialize PB fail",
                    e,
                  );
                }
              },
              (err) {
                Log.error("Error in StoreageNotificationListener", err);
              },
            );
          },
        ) {
    _subscription =
        RustStreamReceiver.listen((observable) => _parser?.parse(observable));
  }

  StoregeNotificationParser? _parser;
  StreamSubscription<SubscribeObject>? _subscription;

  Future<void> stop() async {
    _parser = null;
    await _subscription?.cancel();
    _subscription = null;
  }
}
