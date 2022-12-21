import 'package:app_flowy/plugins/board/presentation/card/card_cell_builder.dart';
import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_field_notifier.dart';
import 'package:app_flowy/plugins/grid/application/field/field_controller.dart';
import 'package:app_flowy/plugins/grid/application/row/row_cache.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/row_entities.pb.dart';
import 'package:flutter/foundation.dart';

typedef OnCardChanged = void Function(GridCellMap, RowsChangedReason);

class CardDataController extends BoardCellBuilderDelegate {
  final RowPB rowPB;
  final GridFieldController _fieldController;
  final GridRowCache _rowCache;
  final List<VoidCallback> _onCardChangedListeners = [];

  CardDataController({
    required this.rowPB,
    required GridFieldController fieldController,
    required GridRowCache rowCache,
  })  : _fieldController = fieldController,
        _rowCache = rowCache;

  GridCellMap loadData() {
    return _rowCache.loadGridCells(rowPB.id);
  }

  void addListener({OnCardChanged? onRowChanged}) {
    _onCardChangedListeners.add(_rowCache.addListener(
      rowId: rowPB.id,
      onCellUpdated: onRowChanged,
    ));
  }

  void dispose() {
    for (final fn in _onCardChangedListeners) {
      _rowCache.removeRowListener(fn);
    }
  }

  @override
  GridCellFieldNotifier buildFieldNotifier() {
    return GridCellFieldNotifier(
        notifier: GridCellFieldNotifierImpl(_fieldController));
  }

  @override
  GridCellCache get cellCache => _rowCache.cellCache;
}
