import 'dart:async';
import 'package:app_flowy/workspace/application/grid/grid_service.dart';
import 'package:app_flowy/workspace/application/grid/row/row_service.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/block_entities.pb.dart';

import 'block_listener.dart';

/// Read https://appflowy.gitbook.io/docs/essential-documentation/contribute-to-appflowy/architecture/frontend/grid for more information
class GridBlockCache {
  final String gridId;
  final GridBlock block;
  late GridRowCache _rowCache;
  late GridBlockListener _listener;

  List<GridRow> get rows => _rowCache.rows;
  GridRowCache get rowCache => _rowCache;

  GridBlockCache({
    required this.gridId,
    required this.block,
    required GridFieldCache fieldCache,
  }) {
    _rowCache = GridRowCache(
      gridId: gridId,
      block: block,
      notifier: GridRowCacheFieldNotifierImpl(fieldCache),
    );

    _listener = GridBlockListener(blockId: block.id);
    _listener.start((result) {
      result.fold(
        (changesets) => _rowCache.applyChangesets(changesets),
        (err) => Log.error(err),
      );
    });
  }

  Future<void> dispose() async {
    await _listener.stop();
    await _rowCache.dispose();
  }

  void addListener({
    required void Function(GridRowChangeReason) onChangeReason,
    bool Function()? listenWhen,
  }) {
    _rowCache.onRowsChanged((reason) {
      if (listenWhen != null && listenWhen() == false) {
        return;
      }

      onChangeReason(reason);
    });
  }
}
