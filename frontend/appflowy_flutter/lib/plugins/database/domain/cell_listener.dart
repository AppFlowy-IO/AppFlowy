import 'dart:async';
import 'dart:typed_data';

import 'package:appflowy/core/notification/grid_notification.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flowy_infra/notifier.dart';

import '../application/row/row_service.dart';

typedef UpdateFieldNotifiedValue = FlowyResult<void, FlowyError>;

class CellListener {
  CellListener({required this.rowId, required this.fieldId});

  final RowId rowId;
  final String fieldId;

  PublishNotifier<UpdateFieldNotifiedValue>? _updateCellNotifier =
      PublishNotifier();
  DatabaseNotificationListener? _listener;

  void start({required void Function(UpdateFieldNotifiedValue) onCellChanged}) {
    _updateCellNotifier?.addPublishListener(onCellChanged);
    _listener = DatabaseNotificationListener(
      objectId: "$rowId:$fieldId",
      handler: _handler,
    );
  }

  void _handler(
    DatabaseNotification ty,
    FlowyResult<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case DatabaseNotification.DidUpdateCell:
        result.fold(
          (payload) => _updateCellNotifier?.value = FlowyResult.success(null),
          (error) => _updateCellNotifier?.value = FlowyResult.failure(error),
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    await _listener?.stop();
    _updateCellNotifier?.dispose();
    _updateCellNotifier = null;
  }
}
