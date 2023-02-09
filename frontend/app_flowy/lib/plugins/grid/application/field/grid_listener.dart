import 'package:app_flowy/core/grid_notification.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/notification.pb.dart';
import 'package:flowy_infra/notifier.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:appflowy_backend/protobuf/flowy-database/field_entities.pb.dart';

typedef UpdateFieldNotifiedValue = Either<DatabaseFieldChangesetPB, FlowyError>;

class DatabaseFieldsListener {
  final String databaseId;
  PublishNotifier<UpdateFieldNotifiedValue>? updateFieldsNotifier =
      PublishNotifier();
  DatabaseNotificationListener? _listener;
  DatabaseFieldsListener({required this.databaseId});

  void start(
      {required void Function(UpdateFieldNotifiedValue) onFieldsChanged}) {
    updateFieldsNotifier?.addPublishListener(onFieldsChanged);
    _listener = DatabaseNotificationListener(
      objectId: databaseId,
      handler: _handler,
    );
  }

  void _handler(DatabaseNotification ty, Either<Uint8List, FlowyError> result) {
    switch (ty) {
      case DatabaseNotification.DidUpdateFields:
        result.fold(
          (payload) => updateFieldsNotifier?.value =
              left(DatabaseFieldChangesetPB.fromBuffer(payload)),
          (error) => updateFieldsNotifier?.value = right(error),
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    await _listener?.stop();
    updateFieldsNotifier?.dispose();
    updateFieldsNotifier = null;
  }
}
