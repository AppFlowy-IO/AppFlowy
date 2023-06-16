import 'package:appflowy_backend/protobuf/flowy-database2/row_entities.pb.dart';
import 'package:flutter/material.dart';
import '../cell/cell_service.dart';
import 'row_cache.dart';

typedef OnRowChanged = void Function(CellContextByFieldId, RowsChangedReason);

class RowController {
  final RowMetaPB rowMeta;
  final String? groupId;
  final String viewId;
  final List<VoidCallback> _onRowChangedListeners = [];
  final RowCache _rowCache;

  get cellCache => _rowCache.cellCache;

  get rowId => rowMeta.id;

  RowController({
    required this.rowMeta,
    required this.viewId,
    required RowCache rowCache,
    this.groupId,
  }) : _rowCache = rowCache;

  CellContextByFieldId loadData() {
    return _rowCache.loadGridCells(rowMeta);
  }

  void addListener({OnRowChanged? onRowChanged}) {
    final fn = _rowCache.addListener(
      rowId: rowMeta.id,
      onCellUpdated: onRowChanged,
    );

    // Add the listener to the list so that we can remove it later.
    _onRowChangedListeners.add(fn);
  }

  void dispose() {
    for (final fn in _onRowChangedListeners) {
      _rowCache.removeRowListener(fn);
    }
  }
}
