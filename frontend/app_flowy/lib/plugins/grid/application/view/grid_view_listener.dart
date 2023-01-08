import 'dart:async';
import 'dart:typed_data';
import 'package:app_flowy/core/grid_notification.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/dart_notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-grid/view_entities.pb.dart';

typedef GridRowsVisibilityNotifierValue
    = Either<GridRowsVisibilityChangesetPB, FlowyError>;

typedef GridViewRowsNotifierValue = Either<GridViewRowsChangesetPB, FlowyError>;

class GridViewListener {
  final String viewId;
  PublishNotifier<GridViewRowsNotifierValue>? _rowsNotifier = PublishNotifier();
  PublishNotifier<GridRowsVisibilityNotifierValue>? _rowsVisibilityNotifier =
      PublishNotifier();

  GridNotificationListener? _listener;
  GridViewListener({required this.viewId});

  void start({
    required void Function(GridViewRowsNotifierValue) onRowsChanged,
    required void Function(GridRowsVisibilityNotifierValue)
        onRowsVisibilityChanged,
  }) {
    if (_listener != null) {
      _listener?.stop();
    }

    _listener = GridNotificationListener(
      objectId: viewId,
      handler: _handler,
    );

    _rowsNotifier?.addPublishListener(onRowsChanged);
    _rowsVisibilityNotifier?.addPublishListener(onRowsVisibilityChanged);
  }

  void _handler(GridDartNotification ty, Either<Uint8List, FlowyError> result) {
    switch (ty) {
      case GridDartNotification.DidUpdateGridViewRowsVisibility:
        result.fold(
          (payload) => _rowsVisibilityNotifier?.value =
              left(GridRowsVisibilityChangesetPB.fromBuffer(payload)),
          (error) => _rowsVisibilityNotifier?.value = right(error),
        );
        break;
      case GridDartNotification.DidUpdateGridViewRows:
        result.fold(
          (payload) => _rowsNotifier?.value =
              left(GridViewRowsChangesetPB.fromBuffer(payload)),
          (error) => _rowsNotifier?.value = right(error),
        );
        break;

      default:
        break;
    }
  }

  Future<void> stop() async {
    await _listener?.stop();
    _rowsVisibilityNotifier?.dispose();
    _rowsVisibilityNotifier = null;

    _rowsNotifier?.dispose();
    _rowsNotifier = null;
  }
}
