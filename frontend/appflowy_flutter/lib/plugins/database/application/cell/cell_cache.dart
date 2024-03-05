import 'package:appflowy/plugins/database/application/row/row_service.dart';

import 'cell_controller.dart';

/// CellMemCache is used to cache cell data of each block.
/// We use CellContext to index the cell in the cache.
/// Read https://docs.appflowy.io/docs/documentation/software-contributions/architecture/frontend/frontend/grid
/// for more information
class CellMemCache {
  CellMemCache();

  /// fieldId: {rowId: cellData}
  final Map<String, Map<RowId, dynamic>> _cellByFieldId = {};

  void removeCellWithFieldId(String fieldId) {
    _cellByFieldId.remove(fieldId);
  }

  void remove(CellContext context) {
    _cellByFieldId[context.fieldId]?.remove(context.rowId);
  }

  void insert<T>(CellContext context, T data) {
    _cellByFieldId.putIfAbsent(context.fieldId, () => {});
    _cellByFieldId[context.fieldId]![context.rowId] = data;
  }

  T? get<T>(CellContext context) {
    final value = _cellByFieldId[context.fieldId]?[context.rowId];
    return value is T ? value : null;
  }

  void dispose() {
    _cellByFieldId.clear();
  }
}
