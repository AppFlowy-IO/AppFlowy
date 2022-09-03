import 'dart:async';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/block_entities.pb.dart';

import '../field/field_cache.dart';
import '../row/row_cache.dart';
import 'block_listener.dart';

/// Read https://appflowy.gitbook.io/docs/essential-documentation/contribute-to-appflowy/architecture/frontend/grid for more information
class GridBlockCache {
  final String gridId;
  final BlockPB block;
  late GridRowCache _rowCache;
  late GridBlockListener _listener;

  List<RowInfo> get rows => _rowCache.rows;
  GridRowCache get rowCache => _rowCache;

  GridBlockCache({
    required this.gridId,
    required this.block,
    required GridFieldController fieldController,
  }) {
    _rowCache = GridRowCache(
      gridId: gridId,
      block: block,
      notifier: GridRowFieldNotifierImpl(fieldController),
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
