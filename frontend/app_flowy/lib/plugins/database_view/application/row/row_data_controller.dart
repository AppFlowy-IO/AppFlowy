import 'package:flutter/material.dart';
import '../../grid/presentation/widgets/cell/cell_builder.dart';
import '../cell/cell_field_notifier.dart';
import '../cell/cell_service.dart';
import '../field/field_controller.dart';
import 'row_cache.dart';

typedef OnRowChanged = void Function(GridCellMap, RowsChangedReason);

class RowDataController extends GridCellBuilderDelegate {
  final RowInfo rowInfo;
  final List<VoidCallback> _onRowChangedListeners = [];
  final FieldController _fieldController;
  final RowCache _rowCache;

  RowDataController({
    required this.rowInfo,
    required FieldController fieldController,
    required RowCache rowCache,
  })  : _fieldController = fieldController,
        _rowCache = rowCache;

  GridCellMap loadData() {
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

  // GridCellBuilderDelegate implementation
  @override
  CellFieldNotifier buildFieldNotifier() {
    return CellFieldNotifier(
        notifier: GridCellFieldNotifierImpl(_fieldController));
  }

  @override
  CellCache get cellCache => _rowCache.cellCache;
}
