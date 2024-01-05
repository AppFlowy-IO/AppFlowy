import 'dart:async';
import 'dart:typed_data';
import 'package:appflowy/core/notification/grid_notification.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/sort_entities.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/view_entities.pb.dart';

typedef RowsVisibilityNotifierValue
    = Either<RowsVisibilityChangePB, FlowyError>;

typedef NumberOfRowsNotifierValue = Either<RowsChangePB, FlowyError>;
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
    required void Function(NumberOfRowsNotifierValue) onRowsChanged,
    required void Function(ReorderAllRowsNotifierValue) onReorderAllRows,
    required void Function(SingleRowNotifierValue) onReorderSingleRow,
    required void Function(RowsVisibilityNotifierValue) onRowsVisibilityChanged,
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
              left(RowsVisibilityChangePB.fromBuffer(payload)),
          (error) => _rowsVisibility?.value = right(error),
        );
        break;
      case DatabaseNotification.DidUpdateViewRows:
        result.fold(
          (payload) =>
              _rowsNotifier?.value = left(RowsChangePB.fromBuffer(payload)),
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
