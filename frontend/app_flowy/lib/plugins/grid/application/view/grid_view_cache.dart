import 'dart:async';
import 'package:app_flowy/plugins/grid/application/view/grid_view_listener.dart';
import 'package:appflowy_backend/log.dart';

import '../field/field_controller.dart';
import '../row/row_cache.dart';

/// Read https://appflowy.gitbook.io/docs/essential-documentation/contribute-to-appflowy/architecture/frontend/grid for more information
class DatabaseViewCache {
  final String viewId;
  late RowCache _rowCache;
  final GridViewListener _gridViewListener;

  List<RowInfo> get rowInfos => _rowCache.visibleRows;
  RowCache get rowCache => _rowCache;

  DatabaseViewCache({
    required this.viewId,
    required GridFieldController fieldController,
  }) : _gridViewListener = GridViewListener(viewId: viewId) {
    final delegate = GridRowFieldNotifierImpl(fieldController);
    _rowCache = RowCache(
      viewId: viewId,
      notifier: delegate,
      delegate: delegate,
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
