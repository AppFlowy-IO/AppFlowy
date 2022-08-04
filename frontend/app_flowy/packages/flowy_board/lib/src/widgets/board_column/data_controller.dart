import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../utils/log.dart';
import '../flex/reorder_flex.dart';

abstract class ColumnItem extends ReoderFlexItem {
  bool get isPhantom => false;

  @override
  String toString() {
    if (isPhantom) {
      return 'phantom:$id';
    } else {
      return id;
    }
  }
}

class BoardColumnData extends ReoderFlexItem with EquatableMixin {
  @override
  final String id;
  final List<ColumnItem> _items;

  BoardColumnData({
    required this.id,
    required List<ColumnItem> items,
  }) : _items = items;

  @override
  List<Object?> get props => [id, ..._items];

  @override
  String toString() {
    return 'Column$id';
  }
}

class BoardColumnDataController extends ChangeNotifier with EquatableMixin, ReoderFlextDataSource {
  final BoardColumnData columnData;

  BoardColumnDataController({
    required this.columnData,
  });

  @override
  List<Object?> get props => columnData.props;

  ColumnItem removeAt(int index, {bool notify = true}) {
    Log.debug('[$BoardColumnDataController] $columnData remove item at $index');
    final item = columnData._items.removeAt(index);
    if (notify) {
      notifyListeners();
    }
    return item;
  }

  void move(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) {
      return;
    }
    Log.debug('[$BoardColumnDataController] $columnData move item from $fromIndex to $toIndex');
    final item = columnData._items.removeAt(fromIndex);
    columnData._items.insert(toIndex, item);
    notifyListeners();
  }

  void insert(int index, ColumnItem item, {bool notify = true}) {
    Log.debug('[$BoardColumnDataController] $columnData insert $item at $index');
    columnData._items.insert(index, item);
    if (notify) {
      notifyListeners();
    }
  }

  void replace(int index, ColumnItem item) {
    final removedItem = columnData._items.removeAt(index);
    columnData._items.insert(index, item);
    Log.debug('[$BoardColumnDataController] $columnData replace $removedItem with $item at $index');
    notifyListeners();
  }

  @override
  List<ColumnItem> get items => UnmodifiableListView(columnData._items);

  @override
  String get identifier => columnData.id;
}
