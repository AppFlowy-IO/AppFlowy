part of 'cell_service.dart';

typedef GridCellMap = LinkedHashMap<String, GridCell>;

class _GridCellCacheItem {
  GridCellId key;
  dynamic object;
  _GridCellCacheItem({
    required this.key,
    required this.object,
  });
}

class GridCellId {
  final String fieldId;
  final String rowId;
  GridCellId({
    required this.fieldId,
    required this.rowId,
  });
}

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

  void insert<T extends _GridCellCacheItem>(T item) {
    var map = _cellDataByFieldId[item.key.fieldId];
    if (map == null) {
      _cellDataByFieldId[item.key.fieldId] = {};
      map = _cellDataByFieldId[item.key.fieldId];
    }

    map![item.key.rowId] = item.object;
  }

  T? get<T>(GridCellId key) {
    final map = _cellDataByFieldId[key.fieldId];
    if (map == null) {
      return null;
    } else {
      final object = map[key.rowId];
      if (object is T) {
        return object;
      } else {
        if (object != null) {
          Log.error("Cache data type does not match the cache data type");
        }

        return null;
      }
    }
  }

  Future<void> dispose() async {
    _cellDataByFieldId.clear();
  }
}
