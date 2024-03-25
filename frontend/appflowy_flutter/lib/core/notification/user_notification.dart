import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';

import 'notification_helper.dart';

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
