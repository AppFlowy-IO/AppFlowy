import 'package:appflowy/core/grid_notification.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/notification.pb.dart';
import 'package:flowy_infra/notifier.dart';
import 'dart:async';
import 'dart:typed_data';

typedef UpdateFieldNotifiedValue = Either<Unit, FlowyError>;

class CellListener {
  final String rowId;
  final String fieldId;
  PublishNotifier<UpdateFieldNotifiedValue>? _updateCellNotifier =
      PublishNotifier();
  DatabaseNotificationListener? _listener;
  CellListener({required this.rowId, required this.fieldId});

  void start({required void Function(UpdateFieldNotifiedValue) onCellChanged}) {
    _updateCellNotifier?.addPublishListener(onCellChanged);
    _listener = DatabaseNotificationListener(
      objectId: "$rowId:$fieldId",
      handler: _handler,
    );
  }

  void _handler(DatabaseNotification ty, Either<Uint8List, FlowyError> result) {
    switch (ty) {
      case DatabaseNotification.DidUpdateCell:
        result.fold(
          (payload) => _updateCellNotifier?.value = left(unit),
          (error) => _updateCellNotifier?.value = right(error),
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
