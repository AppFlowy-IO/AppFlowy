import 'package:app_flowy/core/grid_notification.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/dart_notification.pb.dart';
import 'package:flowy_infra/notifier.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/row_entities.pb.dart';

typedef UpdateRowNotifiedValue = Either<RowPB, FlowyError>;
typedef UpdateFieldNotifiedValue = Either<List<FieldPB>, FlowyError>;

class RowListener {
  final String rowId;
  PublishNotifier<UpdateRowNotifiedValue>? updateRowNotifier =
      PublishNotifier();
  GridNotificationListener? _listener;

  RowListener({required this.rowId});

  void start() {
    _listener = GridNotificationListener(objectId: rowId, handler: _handler);
  }

  void _handler(GridDartNotification ty, Either<Uint8List, FlowyError> result) {
    switch (ty) {
      case GridDartNotification.DidUpdateRow:
        result.fold(
          (payload) =>
              updateRowNotifier?.value = left(RowPB.fromBuffer(payload)),
          (error) => updateRowNotifier?.value = right(error),
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    await _listener?.stop();
    updateRowNotifier?.dispose();
    updateRowNotifier = null;
  }
}
