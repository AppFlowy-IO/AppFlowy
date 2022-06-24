part of 'cell_service.dart';

typedef GridCellMap = LinkedHashMap<String, GridCell>;

class _GridCellCacheObject {
  _GridCellCacheKey key;
  dynamic object;
  _GridCellCacheObject({
    required this.key,
    required this.object,
  });
}

class _GridCellCacheKey {
  final String fieldId;
  final String rowId;
  _GridCellCacheKey({
    required this.fieldId,
    required this.rowId,
  });
}

abstract class GridCellFieldDelegate {
  void onFieldChanged(void Function(String) callback);
  void dispose();
}

class GridCellCache {
  final String gridId;
  final GridCellFieldDelegate fieldDelegate;

  /// fieldId: {objectId: callback}
  final Map<String, Map<String, List<VoidCallback>>> _fieldListenerByFieldId = {};

  /// fieldId: {cacheKey: cacheData}
  final Map<String, Map<String, dynamic>> _cellDataByFieldId = {};
  GridCellCache({
    required this.gridId,
    required this.fieldDelegate,
  }) {
    fieldDelegate.onFieldChanged((fieldId) {
      _cellDataByFieldId.remove(fieldId);
      final map = _fieldListenerByFieldId[fieldId];
      if (map != null) {
        for (final callbacks in map.values) {
          for (final callback in callbacks) {
            callback();
          }
        }
      }
    });
  }

  void addFieldListener(_GridCellCacheKey cacheKey, VoidCallback onFieldChanged) {
    var map = _fieldListenerByFieldId[cacheKey.fieldId];
    if (map == null) {
      _fieldListenerByFieldId[cacheKey.fieldId] = {};
      map = _fieldListenerByFieldId[cacheKey.fieldId];
      map![cacheKey.rowId] = [onFieldChanged];
    } else {
      var objects = map[cacheKey.rowId];
      if (objects == null) {
        map[cacheKey.rowId] = [onFieldChanged];
      } else {
        objects.add(onFieldChanged);
      }
    }
  }

  void removeFieldListener(_GridCellCacheKey cacheKey, VoidCallback fn) {
    var callbacks = _fieldListenerByFieldId[cacheKey.fieldId]?[cacheKey.rowId];
    final index = callbacks?.indexWhere((callback) => callback == fn);
    if (index != null && index != -1) {
      callbacks?.removeAt(index);
    }
  }

  void insert<T extends _GridCellCacheObject>(T item) {
    var map = _cellDataByFieldId[item.key.fieldId];
    if (map == null) {
      _cellDataByFieldId[item.key.fieldId] = {};
      map = _cellDataByFieldId[item.key.fieldId];
    }

    map![item.key.rowId] = item.object;
  }

  T? get<T>(_GridCellCacheKey key) {
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
    _fieldListenerByFieldId.clear();
    _cellDataByFieldId.clear();
    fieldDelegate.dispose();
  }
}
