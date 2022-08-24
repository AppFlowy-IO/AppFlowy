import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../utils/log.dart';
import '../reorder_flex/reorder_flex.dart';

abstract class AFColumnItem extends ReoderFlexItem {
  bool get isPhantom => false;

  @override
  String toString() => id;
}

/// [AFBoardColumnDataController] is used to handle the [AFBoardColumnData].
/// * Remove an item by calling [removeAt] method.
/// * Move item to another position by calling [move] method.
/// * Insert item to index by calling [insert] method
/// * Replace item at index by calling [replace] method.
///
/// All there operations will notify listeners by default.
///
class AFBoardColumnDataController extends ChangeNotifier with EquatableMixin {
  final AFBoardColumnData columnData;

  AFBoardColumnDataController({
    required this.columnData,
  });

  @override
  List<Object?> get props => columnData.props;

  /// Returns the readonly List<ColumnItem>
  UnmodifiableListView<AFColumnItem> get items =>
      UnmodifiableListView(columnData.items);

  void updateColumnName(String newName) {
    if (columnData.headerData.columnName != newName) {
      columnData.headerData.columnName = newName;
      notifyListeners();
    }
  }

  /// Remove the item at [index].
  /// * [index] the index of the item you want to remove
  /// * [notify] the default value of [notify] is true, it will notify the
  /// listener. Set to [false] if you do not want to notify the listeners.
  ///
  AFColumnItem removeAt(int index, {bool notify = true}) {
    assert(index >= 0);

    Log.debug(
        '[$AFBoardColumnDataController] $columnData remove item at $index');
    final item = columnData._items.removeAt(index);
    if (notify) {
      notifyListeners();
    }
    return item;
  }

  void removeWhere(bool Function(AFColumnItem) condition) {
    final index = items.indexWhere(condition);
    if (index != -1) {
      removeAt(index);
    }
  }

  /// Move the item from [fromIndex] to [toIndex]. It will do nothing if the
  /// [fromIndex] equal to the [toIndex].
  bool move(int fromIndex, int toIndex) {
    assert(fromIndex >= 0);
    assert(toIndex >= 0);

    if (fromIndex == toIndex) {
      return false;
    }
    Log.debug(
        '[$AFBoardColumnDataController] $columnData move item from $fromIndex to $toIndex');
    final item = columnData._items.removeAt(fromIndex);
    columnData._items.insert(toIndex, item);
    notifyListeners();
    return true;
  }

  /// Insert an item to [index] and notify the listen if the value of [notify]
  /// is true.
  ///
  /// The default value of [notify] is true.
  bool insert(int index, AFColumnItem item, {bool notify = true}) {
    assert(index >= 0);
    Log.debug(
        '[$AFBoardColumnDataController] $columnData insert $item at $index');

    if (_containsItem(item)) {
      return false;
    } else {
      if (columnData._items.length > index) {
        columnData._items.insert(index, item);
      } else {
        columnData._items.add(item);
      }

      if (notify) notifyListeners();
      return true;
    }
  }

  bool add(AFColumnItem item, {bool notify = true}) {
    if (_containsItem(item)) {
      return false;
    } else {
      columnData._items.add(item);
      if (notify) notifyListeners();
      return true;
    }
  }

  /// Replace the item at index with the [newItem].
  void replace(int index, AFColumnItem newItem) {
    if (columnData._items.isEmpty) {
      columnData._items.add(newItem);
      Log.debug('[$AFBoardColumnDataController] $columnData add $newItem');
    } else {
      final removedItem = columnData._items.removeAt(index);
      columnData._items.insert(index, newItem);
      Log.debug(
          '[$AFBoardColumnDataController] $columnData replace $removedItem with $newItem at $index');
    }

    notifyListeners();
  }

  void replaceOrInsertItem(AFColumnItem newItem) {
    final index = columnData._items.indexWhere((item) => item.id == newItem.id);
    if (index != -1) {
      removeAt(index);

      columnData._items.removeAt(index);
      columnData._items.insert(index, newItem);
      notifyListeners();
    } else {
      columnData._items.add(newItem);
      notifyListeners();
    }
  }

  bool _containsItem(AFColumnItem item) {
    return columnData._items.indexWhere((element) => element.id == item.id) !=
        -1;
  }
}

/// [AFBoardColumnData] represents the data of each Column of the Board.
class AFBoardColumnData<CustomData> extends ReoderFlexItem with EquatableMixin {
  @override
  final String id;
  AFBoardColumnHeaderData headerData;
  final List<AFColumnItem> _items;
  final CustomData? customData;

  AFBoardColumnData({
    this.customData,
    required this.id,
    required String name,
    List<AFColumnItem> items = const [],
  })  : _items = items,
        headerData = AFBoardColumnHeaderData(
          columnId: id,
          columnName: name,
        );

  /// Returns the readonly List<ColumnItem>
  UnmodifiableListView<AFColumnItem> get items =>
      UnmodifiableListView([..._items]);

  @override
  List<Object?> get props => [id, ..._items];

  @override
  String toString() {
    return 'Column:[$id]';
  }
}

class AFBoardColumnHeaderData {
  String columnId;
  String columnName;

  AFBoardColumnHeaderData({required this.columnId, required this.columnName});
}
