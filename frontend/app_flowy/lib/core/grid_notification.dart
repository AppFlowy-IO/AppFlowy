import 'dart:async';
import 'dart:typed_data';
import 'package:appflowy_backend/protobuf/flowy-notification/protobuf.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/notification.pb.dart';
import 'package:appflowy_backend/rust_stream.dart';

import 'notification_helper.dart';

// GridPB
typedef GridNotificationCallback = void Function(
    GridNotification, Either<Uint8List, FlowyError>);

class GridNotificationParser
    extends NotificationParser<GridNotification, FlowyError> {
  GridNotificationParser(
      {String? id, required GridNotificationCallback callback})
      : super(
          id: id,
          callback: callback,
          tyParser: (ty) => GridNotification.valueOf(ty),
          errorParser: (bytes) => FlowyError.fromBuffer(bytes),
        );
}

typedef GridNotificationHandler = Function(
    GridNotification ty, Either<Uint8List, FlowyError> result);

class GridNotificationListener {
  StreamSubscription<SubscribeObject>? _subscription;
  GridNotificationParser? _parser;

  GridNotificationListener(
      {required String objectId, required GridNotificationHandler handler})
      : _parser = GridNotificationParser(id: objectId, callback: handler) {
    _subscription =
        RustStreamReceiver.listen((observable) => _parser?.parse(observable));
  }

  Future<void> stop() async {
    _parser = null;
    await _subscription?.cancel();
    _subscription = null;
  }
}
