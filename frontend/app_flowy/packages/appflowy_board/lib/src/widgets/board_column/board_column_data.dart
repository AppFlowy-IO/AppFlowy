import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../utils/log.dart';
import '../reorder_flex/reorder_flex.dart';

abstract class ColumnItem extends ReoderFlexItem {
  bool get isPhantom => false;

  @override
  String toString() => id;
}

/// [BoardColumnDataController] is used to handle the [BoardColumnData].
/// * Remove an item by calling [removeAt] method.
/// * Move item to another position by calling [move] method.
/// * Insert item to index by calling [insert] method
/// * Replace item at index by calling [replace] method.
///
/// All there operations will notify listeners by default.
///
class BoardColumnDataController extends ChangeNotifier with EquatableMixin {
  final BoardColumnData columnData;

  BoardColumnDataController({
    required this.columnData,
  });

  @override
  List<Object?> get props => columnData.props;

  /// Returns the readonly List<ColumnItem>
  UnmodifiableListView<ColumnItem> get items =>
      UnmodifiableListView(columnData.items);

  /// Remove the item at [index].
  /// * [index] the index of the item you want to remove
  /// * [notify] the default value of [notify] is true, it will notify the
  /// listener. Set to [false] if you do not want to notify the listeners.
  ///
  ColumnItem removeAt(int index, {bool notify = true}) {
    assert(index >= 0);

    Log.debug('[$BoardColumnDataController] $columnData remove item at $index');
    final item = columnData._items.removeAt(index);
    if (notify) {
      notifyListeners();
    }
    return item;
  }

  int removeWhere(bool Function(ColumnItem) condition) {
    return items.indexWhere(condition);
  }

  /// Move the item from [fromIndex] to [toIndex]. It will do nothing if the
  /// [fromIndex] equal to the [toIndex].
  void move(int fromIndex, int toIndex) {
    assert(fromIndex >= 0);
    assert(toIndex >= 0);

    if (fromIndex == toIndex) {
      return;
    }
    Log.debug(
        '[$BoardColumnDataController] $columnData move item from $fromIndex to $toIndex');
    final item = columnData._items.removeAt(fromIndex);
    columnData._items.insert(toIndex, item);
    notifyListeners();
  }

  /// Insert an item to [index] and notify the listen if the value of [notify]
  /// is true.
  ///
  /// The default value of [notify] is true.
  void insert(int index, ColumnItem item, {bool notify = true}) {
    assert(index >= 0);
    Log.debug(
        '[$BoardColumnDataController] $columnData insert $item at $index');

    if (columnData._items.length > index) {
      columnData._items.insert(index, item);
    } else {
      columnData._items.add(item);
    }

    if (notify) {
      notifyListeners();
    }
  }

  /// Replace the item at index with the [newItem].
  void replace(int index, ColumnItem newItem) {
    if (columnData._items.isEmpty) {
      columnData._items.add(newItem);
      Log.debug('[$BoardColumnDataController] $columnData add $newItem');
    } else {
      final removedItem = columnData._items.removeAt(index);
      columnData._items.insert(index, newItem);
      Log.debug(
          '[$BoardColumnDataController] $columnData replace $removedItem with $newItem at $index');
    }

    notifyListeners();
  }
}

/// [BoardColumnData] represents the data of each Column of the Board.
class BoardColumnData extends ReoderFlexItem with EquatableMixin {
  @override
  final String id;
  final List<ColumnItem> _items;

  BoardColumnData({
    required this.id,
    required List<ColumnItem> items,
  }) : _items = items;

  /// Returns the readonly List<ColumnItem>
  UnmodifiableListView<ColumnItem> get items => UnmodifiableListView(_items);

  @override
  List<Object?> get props => [id, ..._items];

  @override
  String toString() {
    return 'Column:[$id]';
  }
}
