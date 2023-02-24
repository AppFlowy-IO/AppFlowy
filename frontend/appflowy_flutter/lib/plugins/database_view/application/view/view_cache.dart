import 'dart:async';
import 'package:appflowy_backend/log.dart';
import '../field/field_controller.dart';
import '../row/row_cache.dart';
import 'view_listener.dart';

/// Read https://appflowy.gitbook.io/docs/essential-documentation/contribute-to-appflowy/architecture/frontend/grid for more information
class DatabaseViewCache {
  final String viewId;
  late RowCache _rowCache;
  final DatabaseViewListener _gridViewListener;

  List<RowInfo> get rowInfos => _rowCache.visibleRows;
  RowCache get rowCache => _rowCache;

  DatabaseViewCache({
    required this.viewId,
    required FieldController fieldController,
  }) : _gridViewListener = DatabaseViewListener(viewId: viewId) {
    final delegate = RowDelegatesImpl(fieldController);
    _rowCache = RowCache(
      viewId: viewId,
      fieldsDelegate: delegate,
      cacheDelegate: delegate,
    );

    _gridViewListener.start(
      onRowsChanged: (result) {
        result.fold(
          (changeset) => _rowCache.applyRowsChanged(changeset),
          (err) => Log.error(err),
        );
      },
      onRowsVisibilityChanged: (result) {
        result.fold(
          (changeset) => _rowCache.applyRowsVisibility(changeset),
          (err) => Log.error(err),
        );
      },
      onReorderAllRows: (result) {
        result.fold(
          (rowIds) => _rowCache.reorderAllRows(rowIds),
          (err) => Log.error(err),
        );
      },
      onReorderSingleRow: (result) {
        result.fold(
          (reorderRow) => _rowCache.reorderSingleRow(reorderRow),
          (err) => Log.error(err),
        );
      },
    );
  }

  Future<void> dispose() async {
    await _gridViewListener.stop();
    await _rowCache.dispose();
  }

  void addListener({
    required void Function(RowsChangedReason) onRowsChanged,
    bool Function()? listenWhen,
  }) {
    _rowCache.onRowsChanged((reason) {
      if (listenWhen != null && listenWhen() == false) {
        return;
      }

      onRowsChanged(reason);
    });
  }
}
