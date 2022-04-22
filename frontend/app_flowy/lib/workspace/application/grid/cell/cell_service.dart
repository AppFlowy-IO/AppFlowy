import 'dart:collection';

import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/cell_entities.pb.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'cell_service.freezed.dart';

class GridCellContext {
  GridCell cellData;
  GridCellCache cellCache;
  GridCellContext({
    required this.cellData,
    required this.cellCache,
  });

  String get gridId => cellData.gridId;

  String get cellId => cellData.rowId + (cellData.cell?.fieldId ?? "");

  String get rowId => cellData.rowId;

  String get fieldId => cellData.field.id;

  FieldType get fieldType => cellData.field.fieldType;

  Field get field => cellData.field;

  GridCellCacheKey get cacheKey => GridCellCacheKey(rowId: cellData.rowId, fieldId: cellData.field.id);

  T? getCacheData<T>() {
    return cellCache.get(cacheKey);
  }

  void setCacheData(dynamic data) {
    cellCache.insert(GridCellCacheData(key: cacheKey, value: data));
  }

  void onFieldChanged(VoidCallback callback) {
    cellCache.addListener(fieldId, rowId, callback);
  }

  void removeListener() {
    cellCache.removeListener(fieldId, rowId);
  }
}

// key: rowId
typedef CellDataMap = LinkedHashMap<String, GridCell>;

class GridCellCacheData {
  GridCellCacheKey key;
  dynamic value;
  GridCellCacheData({
    required this.key,
    required this.value,
  });
}

class GridCellCacheKey {
  final String fieldId;
  final String rowId;
  GridCellCacheKey({
    required this.fieldId,
    required this.rowId,
  });

  String get cellId => "$rowId + $fieldId";
}

abstract class GridCellFieldDelegate {
  void onFieldChanged(void Function(String) callback);
}

class GridCellCache {
  final String gridId;
  final GridCellFieldDelegate fieldDelegate;

  /// fieldId: {rowId: callback}
  final Map<String, Map<String, VoidCallback>> _cellListenerByFieldId = {};

  /// fieldId: {cacheKey: cacheData}
  final Map<String, Map<String, dynamic>> _cellCacheByFieldId = {};
  GridCellCache({
    required this.gridId,
    required this.fieldDelegate,
  }) {
    fieldDelegate.onFieldChanged((fieldId) {
      _cellCacheByFieldId.remove(fieldId);
      final map = _cellListenerByFieldId[fieldId];
      if (map != null) {
        for (final callback in map.values) {
          callback();
        }
      }
    });
  }

  void addListener(String fieldId, String rowId, VoidCallback callback) {
    var map = _cellListenerByFieldId[fieldId];
    if (map == null) {
      _cellListenerByFieldId[fieldId] = {};
      map = _cellListenerByFieldId[fieldId];
    }

    map![rowId] = callback;
  }

  void removeListener(String fieldId, String rowId) {
    _cellListenerByFieldId[fieldId]?.remove(rowId);
  }

  void insert<T extends GridCellCacheData>(T item) {
    var map = _cellCacheByFieldId[item.key.fieldId];
    if (map == null) {
      _cellCacheByFieldId[item.key.fieldId] = {};
      map = _cellCacheByFieldId[item.key.fieldId];
    }

    map![item.key.cellId] = item.value;
  }

  T? get<T>(GridCellCacheKey key) {
    final map = _cellCacheByFieldId[key.fieldId];
    if (map == null) {
      return null;
    } else {
      final object = map[key.cellId];
      if (object is T) {
        return object;
      } else {
        Log.error("Cache data type does not match the cache data type");
        return null;
      }
    }
  }
}

class CellService {
  CellService();

  Future<Either<void, FlowyError>> updateCell({
    required String gridId,
    required String fieldId,
    required String rowId,
    required String data,
  }) {
    final payload = CellChangeset.create()
      ..gridId = gridId
      ..fieldId = fieldId
      ..rowId = rowId
      ..data = data;
    return GridEventUpdateCell(payload).send();
  }

  Future<Either<Cell, FlowyError>> getCell({
    required String gridId,
    required String fieldId,
    required String rowId,
  }) {
    final payload = CellIdentifierPayload.create()
      ..gridId = gridId
      ..fieldId = fieldId
      ..rowId = rowId;
    return GridEventGetCell(payload).send();
  }
}

class CellCache {
  final CellService _cellService;
  final HashMap<String, Cell> _cellDataMap = HashMap();

  CellCache() : _cellService = CellService();

  Future<Option<Cell>> getCellData(GridCell identifier) async {
    final cellId = _cellId(identifier);
    final Cell? data = _cellDataMap[cellId];
    if (data != null) {
      return Future(() => Some(data));
    }

    final result = await _cellService.getCell(
      gridId: identifier.gridId,
      fieldId: identifier.field.id,
      rowId: identifier.rowId,
    );

    return result.fold(
      (cell) {
        _cellDataMap[_cellId(identifier)] = cell;
        return Some(cell);
      },
      (err) {
        Log.error(err);
        return none();
      },
    );
  }

  String _cellId(GridCell identifier) {
    return "${identifier.rowId}/${identifier.field.id}";
  }
}

@freezed
class GridCell with _$GridCell {
  const factory GridCell({
    required String gridId,
    required String rowId,
    required Field field,
    Cell? cell,
  }) = _GridCell;
}
