import 'package:appflowy/core/notification/grid_notification.dart';
import 'package:appflowy_backend/log.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/notification.pb.dart';
import 'package:flowy_infra/notifier.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';

typedef UpdateFieldNotifiedValue = FieldPB;

class SingleFieldListener {
  final String fieldId;
  void Function(UpdateFieldNotifiedValue)? _updateFieldNotifier;
  DatabaseNotificationListener? _listener;

  SingleFieldListener({required this.fieldId});

  void start({
    required void Function(UpdateFieldNotifiedValue) onFieldChanged,
  }) {
    _updateFieldNotifier = onFieldChanged;
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
          (payload) => _updateFieldNotifier?.call(FieldPB.fromBuffer(payload)),
          (error) => Log.error(error),
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    await _listener?.stop();
    _updateFieldNotifier = null;
  }
}

typedef InsertFieldsNotifiedValue = Either<RepeatedIndexFieldPB, FlowyError>;
typedef UpdateFieldsNotifiedValue
    = Either<DatabaseFieldChangesetPB, FlowyError>;
typedef DeleteFieldsNotifiedValue = Either<RepeatedFieldIdPB, FlowyError>;

class FieldsListener {
  final String viewId;
  PublishNotifier<InsertFieldsNotifiedValue>? _insertFieldsNotifier =
      PublishNotifier();
  PublishNotifier<UpdateFieldsNotifiedValue>? _updateFieldsNotifier =
      PublishNotifier();
  PublishNotifier<DeleteFieldsNotifiedValue>? _deleteFieldsNotifier =
      PublishNotifier();
  DatabaseNotificationListener? _listener;
  FieldsListener({required this.viewId});

  void start({
    required void Function(InsertFieldsNotifiedValue) onFieldsInserted,
    required void Function(UpdateFieldsNotifiedValue) onFieldsUpdated,
    required void Function(DeleteFieldsNotifiedValue) onFieldsDeleted,
  }) {
    _insertFieldsNotifier?.addPublishListener(onFieldsInserted);
    _updateFieldsNotifier?.addPublishListener(onFieldsUpdated);
    _deleteFieldsNotifier?.addPublishListener(onFieldsDeleted);
    _listener = DatabaseNotificationListener(
      objectId: viewId,
      handler: _handler,
    );
  }

  void _handler(DatabaseNotification ty, Either<Uint8List, FlowyError> result) {
    switch (ty) {
      case DatabaseNotification.DidInsertFields:
        result.fold(
          (payload) => _insertFieldsNotifier?.value =
              left(RepeatedIndexFieldPB.fromBuffer(payload)),
          (error) => _insertFieldsNotifier?.value = right(error),
        );
        break;
      case DatabaseNotification.DidUpdateFields:
        result.fold(
          (payload) => _updateFieldsNotifier?.value =
              left(DatabaseFieldChangesetPB.fromBuffer(payload)),
          (error) => _updateFieldsNotifier?.value = right(error),
        );
        break;
      case DatabaseNotification.DidDeleteFields:
        result.fold(
          (payload) => _deleteFieldsNotifier?.value =
              left(RepeatedFieldIdPB.fromBuffer(payload)),
          (error) => _deleteFieldsNotifier?.value = right(error),
        );
      default:
        break;
    }
  }

  Future<void> stop() async {
    await _listener?.stop();
    _insertFieldsNotifier?.dispose();
    _insertFieldsNotifier = null;
    _updateFieldsNotifier?.dispose();
    _updateFieldsNotifier = null;
    _deleteFieldsNotifier?.dispose();
    _deleteFieldsNotifier = null;
  }
}
