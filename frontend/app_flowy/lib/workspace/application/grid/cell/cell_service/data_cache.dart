part of 'cell_service.dart';

typedef GridCellMap = LinkedHashMap<String, GridCell>;

class GridCellCacheData {
  GridCellCacheKey key;
  dynamic object;
  GridCellCacheData({
    required this.key,
    required this.object,
  });
}

class GridCellCacheKey {
  final String fieldId;
  final String objectId;
  GridCellCacheKey({
    required this.fieldId,
    required this.objectId,
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
  final Map<String, Map<String, List<VoidCallback>>> _listenerByFieldId = {};

  /// fieldId: {cacheKey: cacheData}
  final Map<String, Map<String, dynamic>> _cellDataByFieldId = {};
  GridCellCache({
    required this.gridId,
    required this.fieldDelegate,
  }) {
    fieldDelegate.onFieldChanged((fieldId) {
      _cellDataByFieldId.remove(fieldId);
      final map = _listenerByFieldId[fieldId];
      if (map != null) {
        for (final callbacks in map.values) {
          for (final callback in callbacks) {
            callback();
          }
        }
      }
    });
  }

  void addListener(GridCellCacheKey cacheKey, VoidCallback callback) {
    var map = _listenerByFieldId[cacheKey.fieldId];
    if (map == null) {
      _listenerByFieldId[cacheKey.fieldId] = {};
      map = _listenerByFieldId[cacheKey.fieldId];
      map![cacheKey.objectId] = [callback];
    } else {
      var objects = map[cacheKey.objectId];
      if (objects == null) {
        map[cacheKey.objectId] = [callback];
      } else {
        objects.add(callback);
      }
    }
  }

  void removeListener(GridCellCacheKey cacheKey, VoidCallback fn) {
    var callbacks = _listenerByFieldId[cacheKey.fieldId]?[cacheKey.objectId];
    final index = callbacks?.indexWhere((callback) => callback == fn);
    if (index != null && index != -1) {
      callbacks?.removeAt(index);
    }
  }

  void insert<T extends GridCellCacheData>(T item) {
    var map = _cellDataByFieldId[item.key.fieldId];
    if (map == null) {
      _cellDataByFieldId[item.key.fieldId] = {};
      map = _cellDataByFieldId[item.key.fieldId];
    }

    map![item.key.objectId] = item.object;
  }

  T? get<T>(GridCellCacheKey key) {
    final map = _cellDataByFieldId[key.fieldId];
    if (map == null) {
      return null;
    } else {
      final object = map[key.objectId];
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
    fieldDelegate.dispose();
  }
}
