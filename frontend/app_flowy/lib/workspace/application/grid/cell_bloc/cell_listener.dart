import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/dart_notification.pb.dart';
import 'package:flowy_infra/notifier.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:app_flowy/core/notification_helper.dart';

typedef UpdateFieldNotifiedValue = Either<CellNotificationData, FlowyError>;

class CellListener {
  final String rowId;
  final String fieldId;
  PublishNotifier<UpdateFieldNotifiedValue> updateCellNotifier = PublishNotifier();
  GridNotificationListener? _listener;
  CellListener({required this.rowId, required this.fieldId});

  void start() {
    _listener = GridNotificationListener(objectId: "$rowId:$fieldId", handler: _handler);
  }

  void _handler(GridNotification ty, Either<Uint8List, FlowyError> result) {
    switch (ty) {
      case GridNotification.DidUpdateCell:
        result.fold(
          (payload) => updateCellNotifier.value = left(CellNotificationData.fromBuffer(payload)),
          (error) => updateCellNotifier.value = right(error),
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    await _listener?.stop();
    updateCellNotifier.dispose();
  }
}
