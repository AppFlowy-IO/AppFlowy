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

class GridCellDataContext {
  GridCell cellData;
  GridCellCache cellCache;
  GridCellDataContext({
    required this.cellData,
    required this.cellCache,
  });

  String get gridId => cellData.gridId;

  String get cellId => cellData.rowId + (cellData.cell?.fieldId ?? "");

  String get rowId => cellData.rowId;

  String get fieldId => cellData.field.id;

  FieldType get fieldType => cellData.field.fieldType;

  Field get field => cellData.field;
}

// key: rowId
typedef CellDataMap = LinkedHashMap<String, GridCell>;

abstract class GridCellCacheData {
  String get fieldId;
  String get cacheKey;
  dynamic get cacheData;
}

abstract class GridCellFieldDelegate {
  void onFieldChanged(void Function(String) callback);
}

class GridCellCache {
  final String gridId;
  final GridCellFieldDelegate fieldDelegate;

  /// fieldId: {cacheKey: cacheData}
  final Map<String, Map<String, dynamic>> _cells = {};
  GridCellCache({
    required this.gridId,
    required this.fieldDelegate,
  }) {
    fieldDelegate.onFieldChanged((fieldId) {
      _cells.remove(fieldId);
    });
  }

  void insert<T extends GridCellCacheData>(T cacheData) {
    var map = _cells[cacheData.fieldId];
    if (map == null) {
      _cells[cacheData.fieldId] = {};
      map = _cells[cacheData.fieldId];
    }

    map![cacheData.cacheKey] = cacheData.cacheData;
  }

  T? get<T>(String fieldId, String cacheKey) {
    final map = _cells[fieldId];
    if (map == null) {
      return null;
    } else {
      final object = map[cacheKey];
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
