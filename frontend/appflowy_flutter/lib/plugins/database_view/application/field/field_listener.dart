import 'package:appflowy/core/grid_notification.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/notification.pb.dart';
import 'package:flowy_infra/notifier.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:appflowy_backend/protobuf/flowy-database/field_entities.pb.dart';

typedef UpdateFieldNotifiedValue = Either<FieldPB, FlowyError>;

class SingleFieldListener {
  final String fieldId;
  PublishNotifier<UpdateFieldNotifiedValue>? _updateFieldNotifier =
      PublishNotifier();
  DatabaseNotificationListener? _listener;

  SingleFieldListener({required this.fieldId});

  void start(
      {required void Function(UpdateFieldNotifiedValue) onFieldChanged}) {
    _updateFieldNotifier?.addPublishListener(onFieldChanged);
    _listener = DatabaseNotificationListener(
      objectId: fieldId,
      handler: _handler,
    );
  }

  void _handler(
    DatabaseNotification ty,
    Either<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case DatabaseNotification.DidUpdateField:
        result.fold(
          (payload) =>
              _updateFieldNotifier?.value = left(FieldPB.fromBuffer(payload)),
          (error) => _updateFieldNotifier?.value = right(error),
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    await _listener?.stop();
    _updateFieldNotifier?.dispose();
    _updateFieldNotifier = null;
  }
}

typedef UpdateFieldsNotifiedValue
    = Either<DatabaseFieldChangesetPB, FlowyError>;

class FieldsListener {
  final String viewId;
  PublishNotifier<UpdateFieldsNotifiedValue>? updateFieldsNotifier =
      PublishNotifier();
  DatabaseNotificationListener? _listener;
  FieldsListener({required this.viewId});

  void start(
      {required void Function(UpdateFieldsNotifiedValue) onFieldsChanged}) {
    updateFieldsNotifier?.addPublishListener(onFieldsChanged);
    _listener = DatabaseNotificationListener(
      objectId: viewId,
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
