import 'dart:async';
import 'package:app_flowy/plugins/grid/application/view/grid_view_listener.dart';
import 'package:flowy_sdk/log.dart';

import '../field/field_controller.dart';
import '../row/row_cache.dart';

/// Read https://appflowy.gitbook.io/docs/essential-documentation/contribute-to-appflowy/architecture/frontend/grid for more information
class GridViewCache {
  final String gridId;
  late GridRowCache _rowCache;
  final GridViewListener _gridViewListener;

  List<RowInfo> get rowInfos => _rowCache.visibleRows;
  GridRowCache get rowCache => _rowCache;

  GridViewCache({
    required this.gridId,
    required GridFieldController fieldController,
  }) : _gridViewListener = GridViewListener(viewId: gridId) {
    _rowCache = GridRowCache(
      gridId: gridId,
      rows: [],
      notifier: GridRowFieldNotifierImpl(fieldController),
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
