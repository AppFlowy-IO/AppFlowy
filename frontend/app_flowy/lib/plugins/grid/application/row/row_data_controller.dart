import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_field_notifier.dart';
import 'package:flutter/material.dart';
import '../../presentation/widgets/cell/cell_builder.dart';
import '../cell/cell_service/cell_service.dart';
import '../field/field_controller.dart';
import 'row_cache.dart';

typedef OnRowChanged = void Function(GridCellMap, RowsChangedReason);

class RowDataController extends GridCellBuilderDelegate {
  final RowInfo rowInfo;
  final List<VoidCallback> _onRowChangedListeners = [];
  final GridFieldController _fieldController;
  final GridRowCache _rowCache;

  RowDataController({
    required this.rowInfo,
    required GridFieldController fieldController,
    required GridRowCache rowCache,
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
  GridCellFieldNotifier buildFieldNotifier() {
    return GridCellFieldNotifier(
        notifier: GridCellFieldNotifierImpl(_fieldController));
  }

  @override
  GridCellCache get cellCache => _rowCache.cellCache;
}
