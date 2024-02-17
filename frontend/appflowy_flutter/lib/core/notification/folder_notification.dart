import 'dart:async';
import 'dart:typed_data';
import 'package:appflowy_backend/protobuf/flowy-notification/protobuf.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/notification.pb.dart';
import 'package:appflowy_backend/rust_stream.dart';

import 'notification_helper.dart';

// Folder
typedef FolderNotificationCallback = void Function(
  FolderNotification,
  Either<Uint8List, FlowyError>,
);

class FolderNotificationParser
    extends NotificationParser<FolderNotification, FlowyError> {
  FolderNotificationParser({
    super.id,
    required super.callback,
  }) : super(
          tyParser: (ty) => FolderNotification.valueOf(ty),
          errorParser: (bytes) => FlowyError.fromBuffer(bytes),
        );
}

typedef FolderNotificationHandler = Function(
  FolderNotification ty,
  Either<Uint8List, FlowyError> result,
);

class FolderNotificationListener {
  FolderNotificationListener({
    required String objectId,
    required FolderNotificationHandler handler,
  }) : _parser = FolderNotificationParser(
          id: objectId,
          callback: handler,
        ) {
    _subscription =
        RustStreamReceiver.listen((observable) => _parser?.parse(observable));
  }

  FolderNotificationParser? _parser;
  StreamSubscription<SubscribeObject>? _subscription;

  Future<void> stop() async {
    _parser = null;
    await _subscription?.cancel();
  }
}
