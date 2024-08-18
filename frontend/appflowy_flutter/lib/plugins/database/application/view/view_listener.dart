import 'dart:async';
import 'dart:typed_data';

import 'package:appflowy/core/notification/grid_notification.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/sort_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/view_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

typedef RowsVisibilityCallback = void Function(
  FlowyResult<RowsVisibilityChangePB, FlowyError>,
);
typedef NumberOfRowsCallback = void Function(
  FlowyResult<RowsChangePB, FlowyError>,
);
typedef ReorderAllRowsCallback = void Function(
  FlowyResult<List<String>, FlowyError>,
);
typedef SingleRowCallback = void Function(
  FlowyResult<ReorderSingleRowPB, FlowyError>,
);

class DatabaseViewListener {
  DatabaseViewListener({required this.viewId});

  final String viewId;
  DatabaseNotificationListener? _listener;

  void start({
    required NumberOfRowsCallback onRowsChanged,
    required ReorderAllRowsCallback onReorderAllRows,
    required SingleRowCallback onReorderSingleRow,
    required RowsVisibilityCallback onRowsVisibilityChanged,
    required void Function() onReloadRows,
  }) {
    // Stop any existing listener
    _listener?.stop();

    // Initialize the notification listener
    _listener = DatabaseNotificationListener(
      objectId: viewId,
      handler: (ty, result) => _handler(
        ty,
        result,
        onRowsChanged,
        onReorderAllRows,
        onReorderSingleRow,
        onRowsVisibilityChanged,
        onReloadRows,
      ),
    );
  }

  void _handler(
    DatabaseNotification ty,
    FlowyResult<Uint8List, FlowyError> result,
    NumberOfRowsCallback onRowsChanged,
    ReorderAllRowsCallback onReorderAllRows,
    SingleRowCallback onReorderSingleRow,
    RowsVisibilityCallback onRowsVisibilityChanged,
    void Function() onReloadRows,
  ) {
    switch (ty) {
      case DatabaseNotification.DidUpdateViewRowsVisibility:
        result.fold(
          (payload) => onRowsVisibilityChanged(
            FlowyResult.success(RowsVisibilityChangePB.fromBuffer(payload)),
          ),
          (error) => onRowsVisibilityChanged(FlowyResult.failure(error)),
        );
        break;
      case DatabaseNotification.DidUpdateRow:
        result.fold(
          (payload) => onRowsChanged(
            FlowyResult.success(RowsChangePB.fromBuffer(payload)),
          ),
          (error) => onRowsChanged(FlowyResult.failure(error)),
        );
        break;
      case DatabaseNotification.DidReorderRows:
        result.fold(
          (payload) => onReorderAllRows(
            FlowyResult.success(ReorderAllRowsPB.fromBuffer(payload).rowOrders),
          ),
          (error) => onReorderAllRows(FlowyResult.failure(error)),
        );
        break;
      case DatabaseNotification.DidReorderSingleRow:
        result.fold(
          (payload) => onReorderSingleRow(
            FlowyResult.success(ReorderSingleRowPB.fromBuffer(payload)),
          ),
          (error) => onReorderSingleRow(FlowyResult.failure(error)),
        );
        break;
      case DatabaseNotification.ReloadRows:
        onReloadRows();
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    await _listener?.stop();
    _listener = null;
  }
}
