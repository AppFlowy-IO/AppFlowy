import 'dart:async';
import 'package:app_flowy/plugins/grid/application/view/grid_view_listener.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/block_entities.pb.dart';

import '../field/field_controller.dart';
import '../row/row_cache.dart';

/// Read https://appflowy.gitbook.io/docs/essential-documentation/contribute-to-appflowy/architecture/frontend/grid for more information
class GridBlockCache {
  final String gridId;
  final BlockPB block;
  late GridRowCache _rowCache;
  final GridViewListener _gridViewListener;

  List<RowInfo> get rows => _rowCache.visibleRows;
  GridRowCache get rowCache => _rowCache;

  GridBlockCache({
    required this.gridId,
    required this.block,
    required GridFieldController fieldController,
  }) : _gridViewListener = GridViewListener(viewId: gridId) {
    _rowCache = GridRowCache(
      gridId: gridId,
      block: block,
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
