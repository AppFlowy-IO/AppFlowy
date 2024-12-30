import 'dart:async';
import 'dart:typed_data';

import 'package:appflowy_backend/protobuf/flowy-database2/notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-notification/protobuf.dart';
import 'package:appflowy_backend/rust_stream.dart';
import 'package:appflowy_result/appflowy_result.dart';

import 'notification_helper.dart';

// This value should be the same as the DATABASE_OBSERVABLE_SOURCE value
const String _source = 'Database';

class DatabaseNotificationParser
    extends NotificationParser<DatabaseNotification, FlowyError> {
  DatabaseNotificationParser({
    super.id,
    required super.callback,
  }) : super(
          tyParser: (ty, source) =>
              source == _source ? DatabaseNotification.valueOf(ty) : null,
          errorParser: (bytes) => FlowyError.fromBuffer(bytes),
        );
}

typedef DatabaseNotificationHandler = Function(
  DatabaseNotification ty,
  FlowyResult<Uint8List, FlowyError> result,
);

class DatabaseNotificationListener {
  DatabaseNotificationListener({
    required String objectId,
    required DatabaseNotificationHandler handler,
  }) : _parser = DatabaseNotificationParser(id: objectId, callback: handler) {
    _subscription =
        RustStreamReceiver.listen((observable) => _parser?.parse(observable));
  }

  DatabaseNotificationParser? _parser;
  StreamSubscription<SubscribeObject>? _subscription;

  Future<void> stop() async {
    _parser = null;
    await _subscription?.cancel();
    _subscription = null;
  }
}
