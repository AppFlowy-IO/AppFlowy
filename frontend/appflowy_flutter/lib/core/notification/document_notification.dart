import 'package:appflowy/core/notification/notification_helper.dart';
import 'package:appflowy_backend/protobuf/flowy-document/notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';

// This value should be the same as the DOCUMENT_OBSERVABLE_SOURCE value
const String _source = 'Document';

class DocumentNotificationParser
    extends NotificationParser<DocumentNotification, FlowyError> {
  DocumentNotificationParser({
    super.id,
    required super.callback,
  }) : super(
          tyParser: (ty, source) =>
              source == _source ? DocumentNotification.valueOf(ty) : null,
          errorParser: (bytes) => FlowyError.fromBuffer(bytes),
        );
}
