import 'dart:collection';

import 'package:equatable/equatable.dart';

import '../utils/log.dart';
import 'board_column/board_column_data.dart';
import 'reorder_flex/reorder_flex.dart';
import 'package:flutter/material.dart';
import 'reorder_phantom/phantom_controller.dart';

typedef OnMoveColumn = void Function(
  String fromColumnId,
  int fromIndex,
  String toColumnId,
  int toIndex,
);

typedef OnMoveColumnItem = void Function(
  String columnId,
  int fromIndex,
  int toIndex,
);

typedef OnMoveColumnItemToColumn = void Function(
  String fromColumnId,
  int fromIndex,
  String toColumnId,
  int toIndex,
);

class AFBoardDataController extends ChangeNotifier
    with EquatableMixin, BoardPhantomControllerDelegate, ReoderFlexDataSource {
  final List<AFBoardColumnData> _columnDatas = [];
  final OnMoveColumn? onMoveColumn;
  final OnMoveColumnItem? onMoveColumnItem;
  final OnMoveColumnItemToColumn? onMoveColumnItemToColumn;

  List<AFBoardColumnData> get columnDatas => _columnDatas;

  List<String> get columnIds =>
      _columnDatas.map((columnData) => columnData.id).toList();

  final LinkedHashMap<String, AFBoardColumnDataController> _columnControllers =
      LinkedHashMap();

  AFBoardDataController({
    this.onMoveColumn,
    this.onMoveColumnItem,
    this.onMoveColumnItemToColumn,
  });

  void addColumn(AFBoardColumnData columnData, {bool notify = true}) {
    if (_columnControllers[columnData.id] != null) return;

    final controller = AFBoardColumnDataController(columnData: columnData);
    _columnDatas.add(columnData);
    _columnControllers[columnData.id] = controller;
    if (notify) notifyListeners();
  }

  void addColumns(List<AFBoardColumnData> columns, {bool notify = true}) {
    for (final column in columns) {
      addColumn(column, notify: false);
    }

    if (columns.isNotEmpty && notify) notifyListeners();
  }

  void removeColumn(String columnId, {bool notify = true}) {
    final index = _columnDatas.indexWhere((column) => column.id == columnId);
    if (index == -1) {
      Log.warn(
          'Try to remove Column:[$columnId] failed. Column:[$columnId] not exist');
    }

    if (index != -1) {
      _columnDatas.removeAt(index);
      _columnControllers.remove(columnId);

      if (notify) notifyListeners();
    }
  }

  void removeColumns(List<String> columnIds, {bool notify = true}) {
    for (final columnId in columnIds) {
      removeColumn(columnId, notify: false);
    }

    if (columnIds.isNotEmpty && notify) notifyListeners();
  }

  AFBoardColumnDataController? getColumnController(String columnId) {
    final columnController = _columnControllers[columnId];
    if (columnController == null) {
      Log.warn('Column:[$columnId] \'s controller is not exist');
    }

    return columnController;
  }

  void moveColumn(int fromIndex, int toIndex, {bool notify = true}) {
    final toColumnData = _columnDatas[toIndex];
    final fromColumnData = _columnDatas.removeAt(fromIndex);

    _columnDatas.insert(toIndex, fromColumnData);
    onMoveColumn?.call(fromColumnData.id, fromIndex, toColumnData.id, toIndex);
    if (notify) notifyListeners();
  }

  void moveColumnItem(String columnId, int fromIndex, int toIndex) {
    if (getColumnController(columnId)?.move(fromIndex, toIndex) ?? false) {
      onMoveColumnItem?.call(columnId, fromIndex, toIndex);
    }
  }

  void addColumnItem(String columnId, AFColumnItem item) {
    getColumnController(columnId)?.add(item);
  }

  void insertColumnItem(String columnId, int index, AFColumnItem item) {
    getColumnController(columnId)?.insert(index, item);
  }

  void removeColumnItem(String columnId, String itemId) {
    getColumnController(columnId)?.removeWhere((item) => item.id == itemId);
  }

  void updateColumnItem(String columnId, AFColumnItem item) {
    getColumnController(columnId)?.replaceOrInsertItem(item);
  }

  @override
  @protected
  void swapColumnItem(
    String fromColumnId,
    int fromColumnIndex,
    String toColumnId,
    int toColumnIndex,
  ) {
    final fromColumnController = getColumnController(fromColumnId)!;
    final toColumnController = getColumnController(toColumnId)!;
    final item = fromColumnController.removeAt(fromColumnIndex);
    if (toColumnController.items.length > toColumnIndex) {
      assert(toColumnController.items[toColumnIndex] is PhantomColumnItem);
    }

    toColumnController.replace(toColumnIndex, item);
    onMoveColumnItemToColumn?.call(
      fromColumnId,
      fromColumnIndex,
      toColumnId,
      toColumnIndex,
    );
  }

  @override
  List<Object?> get props {
    return [_columnDatas];
  }

  @override
  AFBoardColumnDataController? controller(String columnId) {
    return _columnControllers[columnId];
  }

  @override
  String get identifier => '$AFBoardDataController';

  @override
  UnmodifiableListView<ReoderFlexItem> get items =>
      UnmodifiableListView(_columnDatas);

  @override
  @protected
  bool removePhantom(String columnId) {
    final columnController = getColumnController(columnId);
    if (columnController == null) {
      Log.warn('Can not find the column controller with columnId: $columnId');
      return false;
    }
    final index = columnController.items.indexWhere((item) => item.isPhantom);
    final isExist = index != -1;
    if (isExist) {
      columnController.removeAt(index);

      Log.debug(
          '[$AFBoardDataController] Column:[$columnId] remove phantom, current count: ${columnController.items.length}');
    }
    return isExist;
  }

  @override
  @protected
  void updatePhantom(String columnId, int newIndex) {
    final columnDataController = getColumnController(columnId)!;
    final index =
        columnDataController.items.indexWhere((item) => item.isPhantom);

    if (index != -1) {
      if (index != newIndex) {
        Log.trace(
            '[$BoardPhantomController] update $columnId:$index to $columnId:$newIndex');
        final item = columnDataController.removeAt(index, notify: false);
        columnDataController.insert(newIndex, item, notify: false);
      }
    }
  }

  @override
  @protected
  void insertPhantom(String columnId, int index, PhantomColumnItem item) {
    getColumnController(columnId)!.insert(index, item);
  }
}
