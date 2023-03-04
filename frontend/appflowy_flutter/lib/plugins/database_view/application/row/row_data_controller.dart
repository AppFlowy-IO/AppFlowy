import 'package:flutter/material.dart';
import '../cell/cell_service.dart';
import 'row_cache.dart';

typedef OnRowChanged = void Function(CellByFieldId, RowsChangedReason);

class RowDataController {
  final RowInfo rowInfo;
  final List<VoidCallback> _onRowChangedListeners = [];
  final RowCache _rowCache;

  get cellCache => _rowCache.cellCache;

  RowDataController({
    required this.rowInfo,
    required RowCache rowCache,
  }) : _rowCache = rowCache;

  CellByFieldId loadData() {
    return _rowCache.loadGridCells(rowInfo.rowPB.id);
  }

  void addListener({OnRowChanged? onRowChanged}) {
    _onRowChangedListeners.add(_rowCache.addListener(
      rowId: rowInfo.rowPB.id,
      onCellUpdated: onRowChanged,
    ));
  }

  void dispose() {
    for (final fn in _onRowChangedListeners) {
      _rowCache.removeRowListener(fn);
    }
  }
}
