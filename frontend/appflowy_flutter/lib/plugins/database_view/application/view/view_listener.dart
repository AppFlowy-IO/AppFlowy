import 'dart:async';
import 'dart:typed_data';
import 'package:appflowy/core/grid_notification.dart';
import 'package:appflowy_backend/protobuf/flowy-database/sort_entities.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/view_entities.pb.dart';

typedef RowsVisibilityNotifierValue
    = Either<RowsVisibilityChangesetPB, FlowyError>;

typedef NumberOfRowsNotifierValue = Either<RowsChangesetPB, FlowyError>;
typedef ReorderAllRowsNotifierValue = Either<List<String>, FlowyError>;
typedef SingleRowNotifierValue = Either<ReorderSingleRowPB, FlowyError>;

class DatabaseViewListener {
  final String viewId;
  PublishNotifier<NumberOfRowsNotifierValue>? _rowsNotifier = PublishNotifier();
  PublishNotifier<ReorderAllRowsNotifierValue>? _reorderAllRows =
      PublishNotifier();
  PublishNotifier<SingleRowNotifierValue>? _reorderSingleRow =
      PublishNotifier();
  PublishNotifier<RowsVisibilityNotifierValue>? _rowsVisibility =
      PublishNotifier();

  DatabaseNotificationListener? _listener;
  DatabaseViewListener({required this.viewId});

  void start({
    required final void Function(NumberOfRowsNotifierValue) onRowsChanged,
    required final void Function(ReorderAllRowsNotifierValue) onReorderAllRows,
    required final void Function(SingleRowNotifierValue) onReorderSingleRow,
    required final void Function(RowsVisibilityNotifierValue) onRowsVisibilityChanged,
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

  void _handler(final DatabaseNotification ty, final Either<Uint8List, FlowyError> result) {
    switch (ty) {
      case DatabaseNotification.DidUpdateViewRowsVisibility:
        result.fold(
          (final payload) => _rowsVisibility?.value =
              left(RowsVisibilityChangesetPB.fromBuffer(payload)),
          (final error) => _rowsVisibility?.value = right(error),
        );
        break;
      case DatabaseNotification.DidUpdateViewRows:
        result.fold(
          (final payload) =>
              _rowsNotifier?.value = left(RowsChangesetPB.fromBuffer(payload)),
          (final error) => _rowsNotifier?.value = right(error),
        );
        break;
      case DatabaseNotification.DidReorderRows:
        result.fold(
          (final payload) => _reorderAllRows?.value =
              left(ReorderAllRowsPB.fromBuffer(payload).rowOrders),
          (final error) => _reorderAllRows?.value = right(error),
        );
        break;
      case DatabaseNotification.DidReorderSingleRow:
        result.fold(
          (final payload) => _reorderSingleRow?.value =
              left(ReorderSingleRowPB.fromBuffer(payload)),
          (final error) => _reorderSingleRow?.value = right(error),
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
