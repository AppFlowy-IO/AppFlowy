import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../utils/log.dart';
import '../reorder_flex/reorder_flex.dart';

abstract class AppFlowyGroupItem extends ReoderFlexItem {
  bool get isPhantom => false;

  @override
  String toString() => id;
}

/// [AFBoardGroupDataController] is used to handle the [AppFlowyBoardGroupData].
/// * Remove an item by calling [removeAt] method.
/// * Move item to another position by calling [move] method.
/// * Insert item to index by calling [insert] method
/// * Replace item at index by calling [replace] method.
///
/// All there operations will notify listeners by default.
///
class AFBoardGroupDataController extends ChangeNotifier with EquatableMixin {
  final AppFlowyBoardGroupData groupData;

  AFBoardGroupDataController({
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
      notifyListeners();
    }
  }

  /// Remove the item at [index].
  /// * [index] the index of the item you want to remove
  /// * [notify] the default value of [notify] is true, it will notify the
  /// listener. Set to [false] if you do not want to notify the listeners.
  ///
  AppFlowyGroupItem removeAt(int index, {bool notify = true}) {
    assert(index >= 0);

    Log.debug('[$AFBoardGroupDataController] $groupData remove item at $index');
    final item = groupData._items.removeAt(index);
    if (notify) {
      notifyListeners();
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
        '[$AFBoardGroupDataController] $groupData move item from $fromIndex to $toIndex');
    final item = groupData._items.removeAt(fromIndex);
    groupData._items.insert(toIndex, item);
    notifyListeners();
    return true;
  }

  /// Insert an item to [index] and notify the listen if the value of [notify]
  /// is true.
  ///
  /// The default value of [notify] is true.
  bool insert(int index, AppFlowyGroupItem item, {bool notify = true}) {
    assert(index >= 0);
    Log.debug(
        '[$AFBoardGroupDataController] $groupData insert $item at $index');

    if (_containsItem(item)) {
      return false;
    } else {
      if (groupData._items.length > index) {
        groupData._items.insert(index, item);
      } else {
        groupData._items.add(item);
      }

      if (notify) notifyListeners();
      return true;
    }
  }

  bool add(AppFlowyGroupItem item, {bool notify = true}) {
    if (_containsItem(item)) {
      return false;
    } else {
      groupData._items.add(item);
      if (notify) notifyListeners();
      return true;
    }
  }

  /// Replace the item at index with the [newItem].
  void replace(int index, AppFlowyGroupItem newItem) {
    if (groupData._items.isEmpty) {
      groupData._items.add(newItem);
      Log.debug('[$AFBoardGroupDataController] $groupData add $newItem');
    } else {
      if (index >= groupData._items.length) {
        return;
      }

      final removedItem = groupData._items.removeAt(index);
      groupData._items.insert(index, newItem);
      Log.debug(
          '[$AFBoardGroupDataController] $groupData replace $removedItem with $newItem at $index');
    }

    notifyListeners();
  }

  void replaceOrInsertItem(AppFlowyGroupItem newItem) {
    final index = groupData._items.indexWhere((item) => item.id == newItem.id);
    if (index != -1) {
      groupData._items.removeAt(index);
      groupData._items.insert(index, newItem);
      notifyListeners();
    } else {
      groupData._items.add(newItem);
      notifyListeners();
    }
  }

  bool _containsItem(AppFlowyGroupItem item) {
    return groupData._items.indexWhere((element) => element.id == item.id) !=
        -1;
  }
}

/// [AppFlowyBoardGroupData] represents the data of each group of the Board.
class AppFlowyBoardGroupData<CustomData> extends ReoderFlexItem
    with EquatableMixin {
  @override
  final String id;
  AppFlowyBoardGroupHeaderData headerData;
  final List<AppFlowyGroupItem> _items;
  final CustomData? customData;

  AppFlowyBoardGroupData({
    this.customData,
    required this.id,
    required String name,
    List<AppFlowyGroupItem> items = const [],
  })  : _items = items,
        headerData = AppFlowyBoardGroupHeaderData(
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

class AppFlowyBoardGroupHeaderData {
  String groupId;
  String groupName;

  AppFlowyBoardGroupHeaderData(
      {required this.groupId, required this.groupName});
}
