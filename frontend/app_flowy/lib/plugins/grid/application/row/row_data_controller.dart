import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_field_notifier.dart';
import 'package:flutter/material.dart';
import '../../presentation/widgets/cell/cell_builder.dart';
import '../cell/cell_service/cell_service.dart';
import '../field/field_cache.dart';
import 'row_cache.dart';

typedef OnRowChanged = void Function(GridCellMap, GridRowChangeReason);

class GridRowDataController extends GridCellBuilderDelegate {
  final GridRowInfo rowInfo;
  final List<VoidCallback> _onRowChangedListeners = [];
  final GridFieldCache _fieldCache;
  final GridRowCache _rowCache;

  GridFieldCache get fieldCache => _fieldCache;

  GridRowCache get rowCache => _rowCache;

  GridRowDataController({
    required this.rowInfo,
    required GridFieldCache fieldCache,
    required GridRowCache rowCache,
  })  : _fieldCache = fieldCache,
        _rowCache = rowCache;

  GridCellMap loadData() {
    return _rowCache.loadGridCells(rowInfo.id);
  }

  void addListener({OnRowChanged? onRowChanged}) {
    _onRowChangedListeners.add(_rowCache.addListener(
      rowId: rowInfo.id,
      onCellUpdated: onRowChanged,
    ));
  }

  void dispose() {
    for (final fn in _onRowChangedListeners) {
      _rowCache.removeRowListener(fn);
    }
  }

  // GridCellBuilderDelegate implementation
  @override
  GridCellFieldNotifier buildFieldNotifier() {
    return GridCellFieldNotifier(
        notifier: GridCellFieldNotifierImpl(_fieldCache));
  }

  @override
  GridCellCache get cellCache => rowCache.cellCache;
}
