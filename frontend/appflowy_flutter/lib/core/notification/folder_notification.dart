import 'dart:async';
import 'dart:typed_data';

import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-notification/protobuf.dart';
import 'package:appflowy_backend/rust_stream.dart';
import 'package:appflowy_result/appflowy_result.dart';

import 'notification_helper.dart';

// This value should be the same as the FOLDER_OBSERVABLE_SOURCE value
const String _source = 'Workspace';

class FolderNotificationParser
    extends NotificationParser<FolderNotification, FlowyError> {
  FolderNotificationParser({
    super.id,
    required super.callback,
  }) : super(
          tyParser: (ty, source) =>
              source == _source ? FolderNotification.valueOf(ty) : null,
          errorParser: (bytes) => FlowyError.fromBuffer(bytes),
        );
}

typedef FolderNotificationHandler = Function(
  FolderNotification ty,
  FlowyResult<Uint8List, FlowyError> result,
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
