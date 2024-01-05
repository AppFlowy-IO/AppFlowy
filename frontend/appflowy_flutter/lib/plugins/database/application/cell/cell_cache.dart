import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy_backend/log.dart';

import 'cell_controller.dart';

class DatabaseCell {
  dynamic object;
  DatabaseCell({
    required this.object,
  });
}

/// GridCellCache is used to cache cell data of each block.
/// We use GridCellCacheKey to index the cell in the cache.
/// Read https://appflowy.gitbook.io/docs/essential-documentation/contribute-to-appflowy/architecture/frontend/grid
/// for more information
class CellMemCache {
  final String viewId;

  /// fieldId: {cacheKey: GridCell}
  final Map<String, Map<RowId, dynamic>> _cellByFieldId = {};
  CellMemCache({
    required this.viewId,
  });

  void removeCellWithFieldId(String fieldId) {
    _cellByFieldId.remove(fieldId);
  }

  void remove(CellContext context) {
    final map = _cellByFieldId[context.fieldId];
    if (map != null) {
      map.remove(context.rowId);
    }
  }

  void insert<T extends DatabaseCell>(CellContext context, T value) {
    var map = _cellByFieldId[context.fieldId];
    if (map == null) {
      _cellByFieldId[context.fieldId] = {};
      map = _cellByFieldId[context.fieldId];
    }

    map![context.rowId] = value.object;
  }

  T? get<T>(CellContext context) {
    final map = _cellByFieldId[context.fieldId];
    if (map == null) {
      return null;
    } else {
      final value = map[context.rowId];
      if (value is T) {
        return value;
      } else {
        if (value != null) {
          Log.error("Expected value type: $T, but receive $value");
        }
        return null;
      }
    }
  }

  Future<void> dispose() async {
    _cellByFieldId.clear();
  }
}
