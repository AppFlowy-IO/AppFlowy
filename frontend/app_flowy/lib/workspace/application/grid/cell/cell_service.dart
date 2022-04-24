import 'dart:async';
import 'dart:collection';

import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/dispatch/dispatch.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/cell_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/selection_type_option.pb.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app_flowy/workspace/application/grid/cell/cell_listener.dart';

part 'cell_service.freezed.dart';

typedef GridDefaultCellContext = GridCellContext<Cell>;
typedef GridSelectOptionCellContext = GridCellContext<SelectOptionContext>;

class GridCellContext<T> {
  final GridCell gridCell;
  final GridCellCache cellCache;
  final GridCellCacheKey _cacheKey;
  final GridCellDataLoader<T> cellDataLoader;

  final CellListener _cellListener;
  final CellService _cellService = CellService();
  late final ValueNotifier<T?> _cellDataNotifier;
  Timer? _delayOperation;

  GridCellContext({
    required this.gridCell,
    required this.cellCache,
    required this.cellDataLoader,
  })  : _cellListener = CellListener(rowId: gridCell.rowId, fieldId: gridCell.field.id),
        _cacheKey = GridCellCacheKey(objectId: gridCell.rowId, fieldId: gridCell.field.id) {
    _cellDataNotifier = ValueNotifier(cellCache.get(cacheKey));

    _cellListener.updateCellNotifier?.addPublishListener((result) {
      result.fold(
        (notification) => _loadData(),
        (err) => Log.error(err),
      );
    });

    _cellListener.start();

    if (cellDataLoader.reloadOnFieldChanged) {
      cellCache.addListener(cacheKey, () => reloadCellData());
    }
  }

  String get gridId => gridCell.gridId;

  String get rowId => gridCell.rowId;

  String get cellId => gridCell.rowId + gridCell.field.id;

  String get fieldId => gridCell.field.id;

  Field get field => gridCell.field;

  FieldType get fieldType => gridCell.field.fieldType;

  GridCellCacheKey get cacheKey => _cacheKey;

  T? getCellData() {
    final data = cellCache.get(cacheKey);
    if (data == null) {
      _loadData();
    }
    return data;
  }

  void setCellData(T? data) {
    cellCache.insert(GridCellCacheData(key: cacheKey, object: data));
  }

  void saveCellData(String data) {
    _cellService.updateCell(gridId: gridId, fieldId: field.id, rowId: rowId, data: data).then((result) {
      result.fold((l) => null, (err) => Log.error(err));
    });
  }

  void reloadCellData() {
    _loadData();
  }

  void _loadData() {
    _delayOperation?.cancel();
    _delayOperation = Timer(const Duration(milliseconds: 10), () {
      cellDataLoader.loadData().then((data) {
        _cellDataNotifier.value = data;
        setCellData(data);
      });
    });
  }

  void onCellChanged(void Function(T) callback) {
    _cellDataNotifier.addListener(() {
      final value = _cellDataNotifier.value;
      if (value is T) {
        callback(value);
      }
    });
  }

  void dispose() {
    _delayOperation?.cancel();
  }
}

abstract class GridCellDataLoader<T> {
  Future<T?> loadData();

  bool get reloadOnFieldChanged => true;
}

class DefaultCellDataLoader implements GridCellDataLoader<Cell> {
  final CellService service = CellService();
  final GridCell gridCell;

  DefaultCellDataLoader({
    required this.gridCell,
  });

  @override
  Future<Cell?> loadData() {
    final fut = service.getCell(
      gridId: gridCell.gridId,
      fieldId: gridCell.field.id,
      rowId: gridCell.rowId,
    );
    return fut.then((result) {
      return result.fold((data) => data, (err) {
        Log.error(err);
        return null;
      });
    });
  }

  @override
  bool get reloadOnFieldChanged => true;
}

// key: rowId
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

  void addListener(GridCellCacheKey cacheKey, VoidCallback callback) {
    var map = _cellListenerByFieldId[cacheKey.fieldId];
    if (map == null) {
      _cellListenerByFieldId[cacheKey.fieldId] = {};
      map = _cellListenerByFieldId[cacheKey.fieldId];
    }

    map![cacheKey.objectId] = callback;
  }

  void removeListener(GridCellCacheKey cacheKey) {
    _cellListenerByFieldId[cacheKey.fieldId]?.remove(cacheKey.objectId);
  }

  void insert<T extends GridCellCacheData>(T item) {
    var map = _cellCacheByFieldId[item.key.fieldId];
    if (map == null) {
      _cellCacheByFieldId[item.key.fieldId] = {};
      map = _cellCacheByFieldId[item.key.fieldId];
    }

    map![item.key.objectId] = item.object;
  }

  T? get<T>(GridCellCacheKey key) {
    final map = _cellCacheByFieldId[key.fieldId];
    if (map == null) {
      return null;
    } else {
      final object = map[key.objectId];
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

@freezed
class GridCell with _$GridCell {
  const factory GridCell({
    required String gridId,
    required String rowId,
    required Field field,
    Cell? cell,
  }) = _GridCell;
}
