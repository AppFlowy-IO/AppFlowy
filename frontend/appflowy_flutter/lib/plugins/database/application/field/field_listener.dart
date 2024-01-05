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

typedef UpdateFieldsNotifiedValue
    = Either<DatabaseFieldChangesetPB, FlowyError>;

class FieldsListener {
  final String viewId;
  PublishNotifier<UpdateFieldsNotifiedValue>? updateFieldsNotifier =
      PublishNotifier();
  DatabaseNotificationListener? _listener;
  FieldsListener({required this.viewId});

  void start({
    required void Function(UpdateFieldsNotifiedValue) onFieldsChanged,
  }) {
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
