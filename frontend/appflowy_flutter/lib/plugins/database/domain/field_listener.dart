import 'dart:async';
import 'dart:typed_data';

import 'package:appflowy/core/notification/grid_notification.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flowy_infra/notifier.dart';

typedef UpdateFieldNotifiedValue = FieldPB;

class SingleFieldListener {
  SingleFieldListener({required this.fieldId});

  final String fieldId;

  void Function(UpdateFieldNotifiedValue)? _updateFieldNotifier;
  DatabaseNotificationListener? _listener;

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
    FlowyResult<Uint8List, FlowyError> result,
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
    = FlowyResult<DatabaseFieldChangesetPB, FlowyError>;

class FieldsListener {
  FieldsListener({required this.viewId});

  final String viewId;

  PublishNotifier<UpdateFieldsNotifiedValue>? updateFieldsNotifier =
      PublishNotifier();
  DatabaseNotificationListener? _listener;

  void start({
    required void Function(UpdateFieldsNotifiedValue) onFieldsChanged,
  }) {
    updateFieldsNotifier?.addPublishListener(onFieldsChanged);
    _listener = DatabaseNotificationListener(
      objectId: viewId,
      handler: _handler,
    );
  }

  void _handler(
    DatabaseNotification ty,
    FlowyResult<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case DatabaseNotification.DidUpdateFields:
        result.fold(
          (payload) => updateFieldsNotifier?.value =
              FlowyResult.success(DatabaseFieldChangesetPB.fromBuffer(payload)),
          (error) => updateFieldsNotifier?.value = FlowyResult.failure(error),
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
