import 'package:appflowy/core/notification/notification_helper.dart';
import 'package:appflowy_backend/protobuf/flowy-document/notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';

class DocumentNotificationParser
    extends NotificationParser<DocumentNotification, FlowyError> {
  DocumentNotificationParser({
    super.id,
    required super.callback,
  }) : super(
          tyParser: (ty) => DocumentNotification.valueOf(ty),
          errorParser: (bytes) => FlowyError.fromBuffer(bytes),
        );
}
