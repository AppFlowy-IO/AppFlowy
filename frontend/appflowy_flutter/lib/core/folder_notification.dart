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
    final String? id,
    required final FolderNotificationCallback callback,
  }) : super(
          id: id,
          callback: callback,
          tyParser: (final ty) => FolderNotification.valueOf(ty),
          errorParser: (final bytes) => FlowyError.fromBuffer(bytes),
        );
}

typedef FolderNotificationHandler = Function(
  FolderNotification ty,
  Either<Uint8List, FlowyError> result,
);

class FolderNotificationListener {
  StreamSubscription<SubscribeObject>? _subscription;
  FolderNotificationParser? _parser;

  FolderNotificationListener({
    required final String objectId,
    required final FolderNotificationHandler handler,
  }) : _parser = FolderNotificationParser(
          id: objectId,
          callback: handler,
        ) {
    _subscription =
        RustStreamReceiver.listen((final observable) => _parser?.parse(observable));
  }

  Future<void> stop() async {
    _parser = null;
    await _subscription?.cancel();
  }
}
