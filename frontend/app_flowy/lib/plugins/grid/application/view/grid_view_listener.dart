import 'dart:async';
import 'dart:typed_data';
import 'package:app_flowy/core/grid_notification.dart';
import 'package:appflowy_backend/protobuf/flowy-database/sort_entities.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/view_entities.pb.dart';

typedef GridRowsVisibilityNotifierValue
    = Either<ViewRowsVisibilityChangesetPB, FlowyError>;

typedef GridViewRowsNotifierValue = Either<ViewRowsChangesetPB, FlowyError>;
typedef GridViewReorderAllRowsNotifierValue = Either<List<String>, FlowyError>;
typedef GridViewSingleRowNotifierValue = Either<ReorderSingleRowPB, FlowyError>;

class GridViewListener {
  final String viewId;
  PublishNotifier<GridViewRowsNotifierValue>? _rowsNotifier = PublishNotifier();
  PublishNotifier<GridViewReorderAllRowsNotifierValue>? _reorderAllRows =
      PublishNotifier();
  PublishNotifier<GridViewSingleRowNotifierValue>? _reorderSingleRow =
      PublishNotifier();
  PublishNotifier<GridRowsVisibilityNotifierValue>? _rowsVisibility =
      PublishNotifier();

  DatabaseNotificationListener? _listener;
  GridViewListener({required this.viewId});

  void start({
    required void Function(GridViewRowsNotifierValue) onRowsChanged,
    required void Function(GridViewReorderAllRowsNotifierValue)
        onReorderAllRows,
    required void Function(GridViewSingleRowNotifierValue) onReorderSingleRow,
    required void Function(GridRowsVisibilityNotifierValue)
        onRowsVisibilityChanged,
  }) {
    if (_listener != null) {
      _listener?.stop();
    }

    _listener = DatabaseNotificationListener(
      objectId: viewId,
      handler: _handler,
    );

    _rowsNotifier?.addPublishListener(onRowsChanged);
    _rowsVisibility?.addPublishListener(onRowsVisibilityChanged);
    _reorderAllRows?.addPublishListener(onReorderAllRows);
    _reorderSingleRow?.addPublishListener(onReorderSingleRow);
  }

  void _handler(DatabaseNotification ty, Either<Uint8List, FlowyError> result) {
    switch (ty) {
      case DatabaseNotification.DidUpdateViewRowsVisibility:
        result.fold(
          (payload) => _rowsVisibility?.value =
              left(ViewRowsVisibilityChangesetPB.fromBuffer(payload)),
          (error) => _rowsVisibility?.value = right(error),
        );
        break;
      case DatabaseNotification.DidUpdateViewRows:
        result.fold(
          (payload) => _rowsNotifier?.value =
              left(ViewRowsChangesetPB.fromBuffer(payload)),
          (error) => _rowsNotifier?.value = right(error),
        );
        break;
      case DatabaseNotification.DidReorderRows:
        result.fold(
          (payload) => _reorderAllRows?.value =
              left(ReorderAllRowsPB.fromBuffer(payload).rowOrders),
          (error) => _reorderAllRows?.value = right(error),
        );
        break;
      case DatabaseNotification.DidReorderSingleRow:
        result.fold(
          (payload) => _reorderSingleRow?.value =
              left(ReorderSingleRowPB.fromBuffer(payload)),
          (error) => _reorderSingleRow?.value = right(error),
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    await _listener?.stop();
    _rowsVisibility?.dispose();
    _rowsVisibility = null;

    _rowsNotifier?.dispose();
    _rowsNotifier = null;

    _reorderAllRows?.dispose();
    _reorderAllRows = null;

    _reorderSingleRow?.dispose();
    _reorderSingleRow = null;
  }
}
