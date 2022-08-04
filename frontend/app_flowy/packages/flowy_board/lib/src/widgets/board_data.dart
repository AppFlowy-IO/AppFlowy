import 'dart:collection';

import 'package:equatable/equatable.dart';

import '../../flowy_board.dart';
import 'flex/reorder_flex.dart';
import 'package:flutter/material.dart';
import 'phantom/phantom_controller.dart';

class BoardDataController extends ChangeNotifier
    with EquatableMixin, BoardPhantomControllerDelegate, ReoderFlextDataSource {
  final List<BoardColumnData> _columnDatas = [];

  List<BoardColumnData> get columnDatas => _columnDatas;

  List<String> get columnIds =>
      _columnDatas.map((columnData) => columnData.id).toList();

  final LinkedHashMap<String, BoardColumnDataController> _columnControllers =
      LinkedHashMap();

  BoardDataController();

  void setColumnData(BoardColumnData columnData) {
    final controller = BoardColumnDataController(columnData: columnData);
    _columnDatas.add(columnData);
    _columnControllers[columnData.id] = controller;
  }

  BoardColumnDataController columnController(String columnId) {
    return _columnControllers[columnId]!;
  }

  void onReorder(int fromIndex, int toIndex) {
    final columnData = _columnDatas.removeAt(fromIndex);
    _columnDatas.insert(toIndex, columnData);
    notifyListeners();
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
  List<ReoderFlexItem> get items => _columnDatas;
}
