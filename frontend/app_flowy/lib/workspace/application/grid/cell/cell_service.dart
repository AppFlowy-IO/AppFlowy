import 'dart:async';
import 'dart:collection';

import 'package:app_flowy/workspace/application/grid/cell/select_option_service.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
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

class GridCellContextBuilder {
  final GridCellCache _cellCache;
  final GridCell _gridCell;
  GridCellContextBuilder({
    required GridCellCache cellCache,
    required GridCell gridCell,
  })  : _cellCache = cellCache,
        _gridCell = gridCell;

  GridCellContext build() {
    switch (_gridCell.field.fieldType) {
      case FieldType.Checkbox:
      case FieldType.DateTime:
      case FieldType.Number:
        return GridDefaultCellContext(
          gridCell: _gridCell,
          cellCache: _cellCache,
          cellDataLoader: DefaultCellDataLoader(gridCell: _gridCell, reloadOnCellChanged: true),
        );
      case FieldType.RichText:
        return GridDefaultCellContext(
          gridCell: _gridCell,
          cellCache: _cellCache,
          cellDataLoader: DefaultCellDataLoader(gridCell: _gridCell),
        );
      case FieldType.MultiSelect:
      case FieldType.SingleSelect:
        return GridSelectOptionCellContext(
          gridCell: _gridCell,
          cellCache: _cellCache,
          cellDataLoader: SelectOptionCellDataLoader(gridCell: _gridCell),
        );
      default:
        throw UnimplementedError;
    }
  }
}

// ignore: must_be_immutable
class GridCellContext<T> extends Equatable {
  final GridCell gridCell;
  final GridCellCache cellCache;
  final GridCellCacheKey _cacheKey;
  final GridCellDataLoader<T> cellDataLoader;
  final CellService _cellService = CellService();

  late final CellListener _cellListener;
  late final ValueNotifier<T?> _cellDataNotifier;
  bool isListening = false;
  VoidCallback? _onFieldChangedFn;
  Timer? _delayOperation;

  GridCellContext({
    required this.gridCell,
    required this.cellCache,
    required this.cellDataLoader,
  }) : _cacheKey = GridCellCacheKey(objectId: gridCell.rowId, fieldId: gridCell.field.id);

  GridCellContext<T> clone() {
    return GridCellContext(
      gridCell: gridCell,
      cellDataLoader: cellDataLoader,
      cellCache: cellCache,
    );
  }

  String get gridId => gridCell.gridId;

  String get rowId => gridCell.rowId;

  String get cellId => gridCell.rowId + gridCell.field.id;

  String get fieldId => gridCell.field.id;

  Field get field => gridCell.field;

  FieldType get fieldType => gridCell.field.fieldType;

  GridCellCacheKey get cacheKey => _cacheKey;

  VoidCallback? startListening({required void Function(T) onCellChanged}) {
    if (isListening) {
      Log.error("Already started. It seems like you should call clone first");
      return null;
    }

    isListening = true;
    _cellDataNotifier = ValueNotifier(cellCache.get(cacheKey));
    _cellListener = CellListener(rowId: gridCell.rowId, fieldId: gridCell.field.id);
    _cellListener.start(onCellChanged: (result) {
      result.fold(
        (_) => _loadData(),
        (err) => Log.error(err),
      );
    });

    if (cellDataLoader.reloadOnFieldChanged) {
      _onFieldChangedFn = () {
        _loadData();
      };
      cellCache.addListener(cacheKey, _onFieldChangedFn!);
    }

    onCellChangedFn() {
      final value = _cellDataNotifier.value;
      if (value is T) {
        onCellChanged(value);
      }

      if (cellDataLoader.reloadOnCellChanged) {
        _loadData();
      }
    }

    _cellDataNotifier.addListener(onCellChangedFn);
    return onCellChangedFn;
  }

  void removeListener(VoidCallback fn) {
    _cellDataNotifier.removeListener(fn);
  }

  T? getCellData() {
    final data = cellCache.get(cacheKey);
    if (data == null) {
      _loadData();
    }
    return data;
  }

  void saveCellData(String data) {
    _cellService.updateCell(gridId: gridId, fieldId: field.id, rowId: rowId, data: data).then((result) {
      result.fold((l) => null, (err) => Log.error(err));
    });
  }

  void _loadData() {
    _delayOperation?.cancel();
    _delayOperation = Timer(const Duration(milliseconds: 10), () {
      cellDataLoader.loadData().then((data) {
        _cellDataNotifier.value = data;
        cellCache.insert(GridCellCacheData(key: cacheKey, object: data));
      });
    });
  }

  void dispose() {
    _delayOperation?.cancel();

    if (_onFieldChangedFn != null) {
      cellCache.removeListener(cacheKey, _onFieldChangedFn!);
      _onFieldChangedFn = null;
    }
  }

  @override
  List<Object> get props => [cellCache.get(cacheKey) ?? "", cellId];
}

abstract class GridCellDataLoader<T> {
  Future<T?> loadData();

  bool get reloadOnFieldChanged => true;
  bool get reloadOnCellChanged => false;
}

abstract class GridCellDataConfig {
  bool get reloadOnFieldChanged => true;
  bool get reloadOnCellChanged => false;
}

class DefaultCellDataLoader extends GridCellDataLoader<Cell> {
  final CellService service = CellService();
  final GridCell gridCell;
  @override
  final bool reloadOnCellChanged;

  DefaultCellDataLoader({
    required this.gridCell,
    this.reloadOnCellChanged = false,
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

  // ignore: unused_element
  const GridCell._();

  String cellId() {
    return rowId + field.id + "${field.fieldType}";
  }
}
