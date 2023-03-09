import 'package:flutter/material.dart';
import '../cell/cell_service.dart';
import 'row_cache.dart';

typedef OnRowChanged = void Function(CellByFieldId, RowsChangedReason);

class RowController {
  final String rowId;
  final String viewId;
  final List<VoidCallback> _onRowChangedListeners = [];
  final RowCache _rowCache;

  get cellCache => _rowCache.cellCache;

  RowController({
    required this.rowId,
    required this.viewId,
    required RowCache rowCache,
  }) : _rowCache = rowCache;

  CellByFieldId loadData() {
    return _rowCache.loadGridCells(rowId);
  }

  void addListener({OnRowChanged? onRowChanged}) {
    _onRowChangedListeners.add(_rowCache.addListener(
      rowId: rowId,
      onCellUpdated: onRowChanged,
    ));
  }

  void dispose() {
    for (final fn in _onRowChangedListeners) {
      _rowCache.removeRowListener(fn);
    }
  }
}
