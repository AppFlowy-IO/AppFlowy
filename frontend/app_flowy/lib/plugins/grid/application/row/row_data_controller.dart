import 'package:flutter/material.dart';
import '../cell/cell_service/cell_service.dart';
import '../grid_service.dart';
import 'row_service.dart';

typedef OnRowChanged = void Function(GridCellMap, GridRowChangeReason);

class GridRowDataController {
  final String rowId;
  VoidCallback? _onRowChangedListener;
  final GridFieldCache _fieldCache;
  final GridRowCache _rowCache;

  GridFieldCache get fieldCache => _fieldCache;

  GridRowCache get rowCache => _rowCache;

  GridRowDataController({
    required this.rowId,
    required GridFieldCache fieldCache,
    required GridRowCache rowCache,
  })  : _fieldCache = fieldCache,
        _rowCache = rowCache;

  GridCellMap loadData() {
    return _rowCache.loadGridCells(rowId);
  }

  void addListener({OnRowChanged? onRowChanged}) {
    _onRowChangedListener = _rowCache.addListener(
      rowId: rowId,
      onCellUpdated: onRowChanged,
    );
  }

  void dispose() {
    if (_onRowChangedListener != null) {
      _rowCache.removeRowListener(_onRowChangedListener!);
    }
  }
}
