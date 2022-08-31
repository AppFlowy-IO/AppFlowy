part of 'cell_service.dart';

typedef GridCellMap = LinkedHashMap<String, GridCellIdentifier>;

class GridCell {
  dynamic object;
  GridCell({
    required this.object,
  });
}

/// Use to index the cell in the grid.
/// We use [fieldId + rowId] to identify the cell.
class GridCellCacheKey {
  final String fieldId;
  final String rowId;
  GridCellCacheKey({
    required this.fieldId,
    required this.rowId,
  });
}

/// GridCellCache is used to cache cell data of each block.
/// We use GridCellCacheKey to index the cell in the cache.
/// Read https://appflowy.gitbook.io/docs/essential-documentation/contribute-to-appflowy/architecture/frontend/grid
/// for more information
class GridCellCache {
  final String gridId;

  /// fieldId: {cacheKey: GridCell}
  final Map<String, Map<String, dynamic>> _cellDataByFieldId = {};
  GridCellCache({
    required this.gridId,
  });

  void removeCellWithFieldId(String fieldId) {
    _cellDataByFieldId.remove(fieldId);
  }

  void remove(GridCellCacheKey key) {
    var map = _cellDataByFieldId[key.fieldId];
    if (map != null) {
      map.remove(key.rowId);
    }
  }

  void insert<T extends GridCell>(GridCellCacheKey key, T value) {
    var map = _cellDataByFieldId[key.fieldId];
    if (map == null) {
      _cellDataByFieldId[key.fieldId] = {};
      map = _cellDataByFieldId[key.fieldId];
    }

    map![key.rowId] = value.object;
  }

  T? get<T>(GridCellCacheKey key) {
    final map = _cellDataByFieldId[key.fieldId];
    if (map == null) {
      return null;
    } else {
      final value = map[key.rowId];
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
    _cellDataByFieldId.clear();
  }
}
