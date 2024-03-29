import 'dart:typed_data';

import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';

import 'notification_helper.dart';

// This value should be the same as the USER_OBSERVABLE_SOURCE value
const String _source = 'User';

// User
typedef UserNotificationCallback = void Function(
  UserNotification,
  FlowyResult<Uint8List, FlowyError>,
);

class UserNotificationParser
    extends NotificationParser<UserNotification, FlowyError> {
  UserNotificationParser({
    required String super.id,
    required super.callback,
  }) : super(
          tyParser: (ty, source) =>
              source == _source ? UserNotification.valueOf(ty) : null,
          errorParser: (bytes) => FlowyError.fromBuffer(bytes),
        );
}
