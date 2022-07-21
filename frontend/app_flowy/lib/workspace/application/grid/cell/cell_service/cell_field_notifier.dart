import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flutter/foundation.dart';

import 'cell_service.dart';

abstract class GridFieldChangedNotifier {
  void onFieldChanged(void Function(GridFieldPB) callback);
  void dispose();
}

/// GridPB's cell helper wrapper that enables each cell will get notified when the corresponding field was changed.
/// You Register an onFieldChanged callback to listen to the cell changes, and unregister if you don't want to listen.
class GridCellFieldNotifier {
  /// fieldId: {objectId: callback}
  final Map<String, Map<String, List<VoidCallback>>> _fieldListenerByFieldId = {};

  GridCellFieldNotifier({required GridFieldChangedNotifier notifier}) {
    notifier.onFieldChanged(
      (field) {
        final map = _fieldListenerByFieldId[field.id];
        if (map != null) {
          for (final callbacks in map.values) {
            for (final callback in callbacks) {
              callback();
            }
          }
        }
      },
    );
  }

  ///
  void register(GridCellCacheKey cacheKey, VoidCallback onFieldChanged) {
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

  void unregister(GridCellCacheKey cacheKey, VoidCallback fn) {
    var callbacks = _fieldListenerByFieldId[cacheKey.fieldId]?[cacheKey.rowId];
    final index = callbacks?.indexWhere((callback) => callback == fn);
    if (index != null && index != -1) {
      callbacks?.removeAt(index);
    }
  }

  Future<void> dispose() async {
    _fieldListenerByFieldId.clear();
  }
}
