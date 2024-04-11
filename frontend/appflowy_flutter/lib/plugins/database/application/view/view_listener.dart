import 'dart:async';
import 'dart:typed_data';

import 'package:appflowy/core/notification/grid_notification.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/sort_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/view_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flowy_infra/notifier.dart';

typedef RowsVisibilityNotifierValue
    = FlowyResult<RowsVisibilityChangePB, FlowyError>;

typedef NumberOfRowsNotifierValue = FlowyResult<RowsChangePB, FlowyError>;
typedef ReorderAllRowsNotifierValue = FlowyResult<List<String>, FlowyError>;
typedef SingleRowNotifierValue = FlowyResult<ReorderSingleRowPB, FlowyError>;

class DatabaseViewListener {
  DatabaseViewListener({required this.viewId});

  final String viewId;

  PublishNotifier<NumberOfRowsNotifierValue>? _rowsNotifier = PublishNotifier();
  PublishNotifier<ReorderAllRowsNotifierValue>? _reorderAllRows =
      PublishNotifier();
  PublishNotifier<SingleRowNotifierValue>? _reorderSingleRow =
      PublishNotifier();
  PublishNotifier<RowsVisibilityNotifierValue>? _rowsVisibility =
      PublishNotifier();

  DatabaseNotificationListener? _listener;

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

  void _handler(
    DatabaseNotification ty,
    FlowyResult<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case DatabaseNotification.DidUpdateViewRowsVisibility:
        result.fold(
          (payload) => _rowsVisibility?.value =
              FlowyResult.success(RowsVisibilityChangePB.fromBuffer(payload)),
          (error) => _rowsVisibility?.value = FlowyResult.failure(error),
        );
        break;
      case DatabaseNotification.DidUpdateViewRows:
        result.fold(
          (payload) => _rowsNotifier?.value =
              FlowyResult.success(RowsChangePB.fromBuffer(payload)),
          (error) => _rowsNotifier?.value = FlowyResult.failure(error),
        );
        break;
      case DatabaseNotification.DidReorderRows:
        result.fold(
          (payload) => _reorderAllRows?.value = FlowyResult.success(
            ReorderAllRowsPB.fromBuffer(payload).rowOrders,
          ),
          (error) => _reorderAllRows?.value = FlowyResult.failure(error),
        );
        break;
      case DatabaseNotification.DidReorderSingleRow:
        result.fold(
          (payload) => _reorderSingleRow?.value =
              FlowyResult.success(ReorderSingleRowPB.fromBuffer(payload)),
          (error) => _reorderSingleRow?.value = FlowyResult.failure(error),
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
