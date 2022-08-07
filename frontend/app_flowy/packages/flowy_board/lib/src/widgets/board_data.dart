import 'dart:collection';

import 'package:equatable/equatable.dart';

import '../utils/log.dart';
import 'board_column/board_column_data.dart';
import 'flex/reorder_flex.dart';
import 'package:flutter/material.dart';
import 'phantom/phantom_controller.dart';

typedef OnMoveColumn = void Function(int fromIndex, int toIndex);

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

class BoardDataController extends ChangeNotifier
    with EquatableMixin, BoardPhantomControllerDelegate, ReoderFlextDataSource {
  final List<BoardColumnData> _columnDatas = [];
  final OnMoveColumn? onMoveColumn;
  final OnMoveColumnItem? onMoveColumnItem;
  final OnMoveColumnItemToColumn? onMoveColumnItemToColumn;

  List<BoardColumnData> get columnDatas => _columnDatas;

  List<String> get columnIds =>
      _columnDatas.map((columnData) => columnData.id).toList();

  final LinkedHashMap<String, BoardColumnDataController> _columnControllers =
      LinkedHashMap();

  BoardDataController({
    this.onMoveColumn,
    this.onMoveColumnItem,
    this.onMoveColumnItemToColumn,
  });

  void addColumn(BoardColumnData columnData) {
    final controller = BoardColumnDataController(columnData: columnData);
    _columnDatas.add(columnData);
    _columnControllers[columnData.id] = controller;
  }

  BoardColumnDataController columnController(String columnId) {
    return _columnControllers[columnId]!;
  }

  void moveColumn(int fromIndex, int toIndex) {
    final columnData = _columnDatas.removeAt(fromIndex);
    _columnDatas.insert(toIndex, columnData);
    onMoveColumn?.call(fromIndex, toIndex);
    notifyListeners();
  }

  void moveColumnItem(String columnId, int fromIndex, int toIndex) {
    final columnController = _columnControllers[columnId];
    assert(columnController != null);
    if (columnController != null) {
      columnController.move(fromIndex, toIndex);
      onMoveColumnItem?.call(columnId, fromIndex, toIndex);
    }
  }

  @override
  @protected
  void swapColumnItem(
    String fromColumnId,
    int fromColumnIndex,
    String toColumnId,
    int toColumnIndex,
  ) {
    final item = columnController(fromColumnId).removeAt(fromColumnIndex);
    assert(
        columnController(toColumnId).items[toColumnIndex] is PhantomColumnItem);

    columnController(toColumnId).replace(toColumnIndex, item);

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
  BoardColumnDataController? controller(String columnId) {
    return _columnControllers[columnId];
  }

  @override
  String get identifier => '$BoardDataController';

  @override
  UnmodifiableListView<ReoderFlexItem> get items =>
      UnmodifiableListView(_columnDatas);

  @override
  @protected
  bool removePhantom(String columnId) {
    final columnController = this.columnController(columnId);
    final index = columnController.items.indexWhere((item) => item.isPhantom);

    final isExist = index != -1;
    if (isExist) {
      columnController.removeAt(index);

      Log.debug(
          '[$BoardPhantomController] Column$columnId remove phantom, current count: ${columnController.items.length}');
    }
    return isExist;
  }

  @override
  @protected
  void updatePhantom(String columnId, int newIndex) {
    final columnDataController = columnController(columnId);
    final index =
        columnDataController.items.indexWhere((item) => item.isPhantom);

    assert(index != -1);
    if (index != -1) {
      if (index != newIndex) {
        // Log.debug('[$BoardPhantomController] update $toColumnId:$index to $toColumnId:$phantomIndex');
        final item = columnDataController.removeAt(index, notify: false);
        columnDataController.insert(newIndex, item, notify: false);
      }
    }
  }

  @override
  @protected
  void insertPhantom(String columnId, int index, PhantomColumnItem item) {
    columnController(columnId).insert(index, item);
  }
}
