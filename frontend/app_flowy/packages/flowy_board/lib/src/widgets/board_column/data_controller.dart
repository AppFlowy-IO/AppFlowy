import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../utils/log.dart';
import '../flex/reorder_flex.dart';

abstract class ColumnItem extends ReoderFlextItem {
  String get id;

  bool get isPhantom => false;

  @override
  String toString() {
    return id;
  }
}

class BoardColumnData extends ReoderFlextItem with EquatableMixin {
  final String id;
  final List<ColumnItem> items;

  BoardColumnData({
    required this.id,
    required this.items,
  });

  @override
  List<Object?> get props => [id, ...items];

  @override
  String toString() {
    return 'Column$id';
  }
}

class BoardColumnDataController extends ChangeNotifier
    with EquatableMixin, ReoderFlextDataSource {
  final BoardColumnData columnData;

  BoardColumnDataController({
    required this.columnData,
  });

  @override
  List<Object?> get props => columnData.props;

  ColumnItem removeAt(int index) {
    Log.debug('[$BoardColumnDataController] $columnData remove item at $index');
    final item = columnData.items.removeAt(index);
    notifyListeners();
    return item;
  }

  void move(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) {
      return;
    }
    Log.debug(
        '[$BoardColumnDataController] $columnData move item from $fromIndex to $toIndex');
    final item = columnData.items.removeAt(fromIndex);
    columnData.items.insert(toIndex, item);
    notifyListeners();
  }

  void insert(int index, ColumnItem item, {bool notify = true}) {
    Log.debug('[$BoardColumnDataController] $columnData insert item at $index');
    columnData.items.insert(index, item);
    if (notify) {
      notifyListeners();
    }
  }

  void replace(int index, ColumnItem item) {
    Log.debug(
        '[$BoardColumnDataController] $columnData replace item at $index');
    columnData.items.removeAt(index);
    columnData.items.insert(index, item);
    notifyListeners();
  }

  @override
  List<ColumnItem> get items => columnData.items;

  @override
  String get identifier => columnData.id;
}
