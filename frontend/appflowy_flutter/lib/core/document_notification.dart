import 'dart:typed_data';

import 'package:appflowy/core/notification_helper.dart';
import 'package:appflowy_backend/protobuf/flowy-document2/notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:dartz/dartz.dart';

typedef DocumentNotificationCallback = void Function(
  DocumentNotification,
  Either<Uint8List, FlowyError>,
);

class DocumentNotificationParser
    extends NotificationParser<DocumentNotification, FlowyError> {
  DocumentNotificationParser({
    String? id,
    required DocumentNotificationCallback callback,
  }) : super(
          id: id,
          callback: callback,
          tyParser: (ty) => DocumentNotification.valueOf(ty),
          errorParser: (bytes) => FlowyError.fromBuffer(bytes),
        );
}
