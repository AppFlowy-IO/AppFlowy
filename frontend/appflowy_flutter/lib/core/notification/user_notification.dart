import 'dart:async';
import 'dart:typed_data';
import 'package:appflowy_backend/protobuf/flowy-notification/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/rust_stream.dart';

import 'notification_helper.dart';

// User
typedef UserNotificationCallback = void Function(
  UserNotification,
  Either<Uint8List, FlowyError>,
);

class UserNotificationParser
    extends NotificationParser<UserNotification, FlowyError> {
  UserNotificationParser({
    required String super.id,
    required super.callback,
  }) : super(
          tyParser: (ty) => UserNotification.valueOf(ty),
          errorParser: (bytes) => FlowyError.fromBuffer(bytes),
        );
}

typedef UserNotificationHandler = Function(
  UserNotification ty,
  Either<Uint8List, FlowyError> result,
);

class UserNotificationListener {
  UserNotificationListener({
    required String objectId,
    required UserNotificationHandler handler,
  }) : _parser = UserNotificationParser(id: objectId, callback: handler) {
    _subscription =
        RustStreamReceiver.listen((observable) => _parser?.parse(observable));
  }

  UserNotificationParser? _parser;
  StreamSubscription<SubscribeObject>? _subscription;

  Future<void> stop() async {
    _parser = null;
    await _subscription?.cancel();
  }
}
