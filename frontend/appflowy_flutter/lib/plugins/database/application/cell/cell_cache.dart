import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy_backend/log.dart';

import 'cell_controller.dart';

class DatabaseCell {
  final dynamic object;

  const DatabaseCell({
    required this.object,
  });
}

/// CellMemCache is used to cache cell data of each block.
/// We use CellContext to index the cell in the cache.
/// Read https://appflowy.gitbook.io/docs/essential-documentation/contribute-to-appflowy/architecture/frontend/grid
/// for more information
class CellMemCache {
  /// fieldId: {rowId: GridCell}
  final Map<String, Map<RowId, dynamic>> _cellByFieldId = {};

  CellMemCache();

  void removeCellWithFieldId(String fieldId) {
    _cellByFieldId.remove(fieldId);
  }

  void remove(CellContext context) {
    if (_cellByFieldId.containsKey(context.fieldId)) {
      _cellByFieldId[context.fieldId]!.remove(context.rowId);
    }
  }

  void insert<T extends DatabaseCell>(CellContext context, T value) {
    _cellByFieldId.putIfAbsent(context.fieldId, () => {});
    _cellByFieldId[context.fieldId]!.putIfAbsent(context.rowId, () => value.object);
  }

  T? get<T>(CellContext context) {
    if (!_cellByFieldId.containsKey(context.fieldId)) {
      return null;
    }
    final value = _cellByFieldId[context.fieldId]![context.rowId];
    if (value == null) {
      return null;
    }
    if (value !is T) {
      Log.error("Expected value of type: $T, but received type $value");
      return null;
    }
    return value;
  }

  void dispose() {
    _cellByFieldId.clear();
  }
}
