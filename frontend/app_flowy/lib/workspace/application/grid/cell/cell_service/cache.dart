part of 'cell_service.dart';

typedef GridCellMap = LinkedHashMap<String, GridCellIdentifier>;

class _GridCellCacheValue {
  GridCellCacheKey key;
  dynamic object;
  _GridCellCacheValue({
    required this.key,
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

/// GridCellsCache is used to cache cell data of each Grid.
/// We use GridCellCacheKey to index the cell in the cache.
class GridCellsCache {
  final String gridId;

  /// fieldId: {cacheKey: cacheData}
  final Map<String, Map<String, dynamic>> _cellDataByFieldId = {};
  GridCellsCache({
    required this.gridId,
  });

  void remove(String fieldId) {
    _cellDataByFieldId.remove(fieldId);
  }

  void insert<T extends _GridCellCacheValue>(T value) {
    var map = _cellDataByFieldId[value.key.fieldId];
    if (map == null) {
      _cellDataByFieldId[value.key.fieldId] = {};
      map = _cellDataByFieldId[value.key.fieldId];
    }

    map![value.key.rowId] = value.object;
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
