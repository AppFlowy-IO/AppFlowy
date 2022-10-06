import 'dart:collection';

import 'package:appflowy_board/src/utils/log.dart';
import 'package:appflowy_board/src/widgets/reorder_flex/reorder_flex.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

typedef IsDraggable = bool;

/// A item represents the generic data model of each group card.
///
/// Each item displayed in the group required to implement this class.
abstract class AppFlowyGroupItem extends ReoderFlexItem {
  bool get isPhantom => false;

  @override
  String toString() => id;
}

/// [AppFlowyGroupController] is used to handle the [AppFlowyGroupData].
///
/// * Remove an item by calling [removeAt] method.
/// * Move item to another position by calling [move] method.
/// * Insert item to index by calling [insert] method
/// * Replace item at index by calling [replace] method.
///
/// All there operations will notify listeners by default.
///
class AppFlowyGroupController extends ChangeNotifier with EquatableMixin {
  final AppFlowyGroupData groupData;

  AppFlowyGroupController({
    required this.groupData,
  });

  @override
  List<Object?> get props => groupData.props;

  /// Returns the readonly List<AppFlowyGroupItem>
  UnmodifiableListView<AppFlowyGroupItem> get items =>
      UnmodifiableListView(groupData.items);

  void updateGroupName(String newName) {
    if (groupData.headerData.groupName != newName) {
      groupData.headerData.groupName = newName;
      _notify();
    }
  }

  /// Remove the item at [index].
  /// * [index] the index of the item you want to remove
  /// * [notify] the default value of [notify] is true, it will notify the
  /// listener. Set to false if you do not want to notify the listeners.
  ///
  AppFlowyGroupItem removeAt(int index, {bool notify = true}) {
    assert(index >= 0);

    Log.debug('[$AppFlowyGroupController] $groupData remove item at $index');
    final item = groupData._items.removeAt(index);
    if (notify) {
      _notify();
    }
    return item;
  }

  void removeWhere(bool Function(AppFlowyGroupItem) condition) {
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
        '[$AppFlowyGroupController] $groupData move item from $fromIndex to $toIndex');
    final item = groupData._items.removeAt(fromIndex);
    groupData._items.insert(toIndex, item);
    _notify();
    return true;
  }

  /// Insert an item to [index] and notify the listen if the value of [notify]
  /// is true.
  ///
  /// The default value of [notify] is true.
  bool insert(int index, AppFlowyGroupItem item, {bool notify = true}) {
    assert(index >= 0);
    Log.debug('[$AppFlowyGroupController] $groupData insert $item at $index');

    if (_containsItem(item)) {
      return false;
    } else {
      if (groupData._items.length > index) {
        groupData._items.insert(index, item);
      } else {
        groupData._items.add(item);
      }

      if (notify) _notify();
      return true;
    }
  }

  bool add(AppFlowyGroupItem item, {bool notify = true}) {
    if (_containsItem(item)) {
      return false;
    } else {
      groupData._items.add(item);
      if (notify) _notify();
      return true;
    }
  }

  /// Replace the item at index with the [newItem].
  void replace(int index, AppFlowyGroupItem newItem) {
    if (groupData._items.isEmpty) {
      groupData._items.add(newItem);
      Log.debug('[$AppFlowyGroupController] $groupData add $newItem');
    } else {
      if (index >= groupData._items.length) {
        Log.warn(
            '[$AppFlowyGroupController] unexpected items length, index should less than the count of the items. Index: $index, items count: ${items.length}');
        return;
      }

      final removedItem = groupData._items.removeAt(index);
      groupData._items.insert(index, newItem);
      Log.debug(
          '[$AppFlowyGroupController] $groupData replace $removedItem with $newItem at $index');
    }

    _notify();
  }

  void replaceOrInsertItem(AppFlowyGroupItem newItem) {
    final index = groupData._items.indexWhere((item) => item.id == newItem.id);
    if (index != -1) {
      groupData._items.removeAt(index);
      groupData._items.insert(index, newItem);
      _notify();
    } else {
      groupData._items.add(newItem);
      _notify();
    }
  }

  bool _containsItem(AppFlowyGroupItem item) {
    return groupData._items.indexWhere((element) => element.id == item.id) !=
        -1;
  }

  void enableDragging(bool isEnable) {
    groupData.draggable = isEnable;

    for (var item in groupData._items) {
      item.draggable = isEnable;
    }
    _notify();
  }

  void _notify() {
    notifyListeners();
  }
}

/// [AppFlowyGroupData] represents the data of each group of the Board.
class AppFlowyGroupData<CustomData> extends ReoderFlexItem with EquatableMixin {
  @override
  final String id;
  AppFlowyGroupHeaderData headerData;
  final List<AppFlowyGroupItem> _items;
  final CustomData? customData;

  AppFlowyGroupData({
    this.customData,
    required this.id,
    required String name,
    List<AppFlowyGroupItem> items = const [],
  })  : _items = items,
        headerData = AppFlowyGroupHeaderData(
          groupId: id,
          groupName: name,
        );

  /// Returns the readonly List<AppFlowyGroupItem>
  UnmodifiableListView<AppFlowyGroupItem> get items =>
      UnmodifiableListView([..._items]);

  @override
  List<Object?> get props => [id, ..._items];

  @override
  String toString() {
    return 'Group:[$id]';
  }
}

class AppFlowyGroupHeaderData {
  String groupId;
  String groupName;

  AppFlowyGroupHeaderData({required this.groupId, required this.groupName});
}
