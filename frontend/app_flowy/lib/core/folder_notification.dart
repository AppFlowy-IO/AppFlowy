import 'dart:async';
import 'dart:typed_data';
import 'package:appflowy_backend/protobuf/dart-notify/protobuf.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/dart_notification.pb.dart';
import 'package:appflowy_backend/rust_stream.dart';

import 'notification_helper.dart';

// Folder
typedef FolderNotificationCallback = void Function(
    FolderNotification, Either<Uint8List, FlowyError>);

class FolderNotificationParser
    extends NotificationParser<FolderNotification, FlowyError> {
  FolderNotificationParser(
      {String? id, required FolderNotificationCallback callback})
      : super(
          id: id,
          callback: callback,
          tyParser: (ty) => FolderNotification.valueOf(ty),
          errorParser: (bytes) => FlowyError.fromBuffer(bytes),
        );
}

typedef FolderNotificationHandler = Function(
    FolderNotification ty, Either<Uint8List, FlowyError> result);

class FolderNotificationListener {
  StreamSubscription<SubscribeObject>? _subscription;
  FolderNotificationParser? _parser;

  FolderNotificationListener(
      {required String objectId, required FolderNotificationHandler handler})
      : _parser = FolderNotificationParser(id: objectId, callback: handler) {
    _subscription =
        RustStreamReceiver.listen((observable) => _parser?.parse(observable));
  }

  Future<void> stop() async {
    _parser = null;
    await _subscription?.cancel();
  }
}
