import 'dart:collection';

import 'package:equatable/equatable.dart';

import '../utils/log.dart';
import 'board_column/board_column_data.dart';
import 'reorder_flex/reorder_flex.dart';
import 'package:flutter/material.dart';
import 'reorder_phantom/phantom_controller.dart';

typedef OnMoveGroup = void Function(
  String fromGroupId,
  int fromIndex,
  String toGroupId,
  int toIndex,
);

typedef OnMoveGroupItem = void Function(
  String groupId,
  int fromIndex,
  int toIndex,
);

typedef OnMoveGroupItemToGroup = void Function(
  String fromGroupId,
  int fromIndex,
  String toGroupId,
  int toIndex,
);

class AppFlowyBoardDataController extends ChangeNotifier
    with EquatableMixin, BoardPhantomControllerDelegate, ReoderFlexDataSource {
  final List<AppFlowyBoardGroupData> _groupDatas = [];
  final OnMoveGroup? onMoveGroup;
  final OnMoveGroupItem? onMoveGroupItem;
  final OnMoveGroupItemToGroup? onMoveGroupItemToGroup;

  UnmodifiableListView<AppFlowyBoardGroupData> get groupDatas =>
      UnmodifiableListView(_groupDatas);

  List<String> get groupIds =>
      _groupDatas.map((groupData) => groupData.id).toList();

  final LinkedHashMap<String, AFBoardGroupDataController> _groupControllers =
      LinkedHashMap();

  AppFlowyBoardDataController({
    this.onMoveGroup,
    this.onMoveGroupItem,
    this.onMoveGroupItemToGroup,
  });

  void addGroup(AppFlowyBoardGroupData groupData, {bool notify = true}) {
    if (_groupControllers[groupData.id] != null) return;

    final controller = AFBoardGroupDataController(groupData: groupData);
    _groupDatas.add(groupData);
    _groupControllers[groupData.id] = controller;
    if (notify) notifyListeners();
  }

  void addGroups(List<AppFlowyBoardGroupData> groups, {bool notify = true}) {
    for (final column in groups) {
      addGroup(column, notify: false);
    }

    if (groups.isNotEmpty && notify) notifyListeners();
  }

  void removeGroup(String groupId, {bool notify = true}) {
    final index = _groupDatas.indexWhere((group) => group.id == groupId);
    if (index == -1) {
      Log.warn(
          'Try to remove Group:[$groupId] failed. Group:[$groupId] not exist');
    }

    if (index != -1) {
      _groupDatas.removeAt(index);
      _groupControllers.remove(groupId);

      if (notify) notifyListeners();
    }
  }

  void removeGroups(List<String> groupIds, {bool notify = true}) {
    for (final groupId in groupIds) {
      removeGroup(groupId, notify: false);
    }

    if (groupIds.isNotEmpty && notify) notifyListeners();
  }

  void clear() {
    _groupDatas.clear();
    _groupControllers.clear();
    notifyListeners();
  }

  AFBoardGroupDataController? getGroupController(String groupId) {
    final groupController = _groupControllers[groupId];
    if (groupController == null) {
      Log.warn('Group:[$groupId] \'s controller is not exist');
    }

    return groupController;
  }

  void moveGroup(int fromIndex, int toIndex, {bool notify = true}) {
    final toGroupData = _groupDatas[toIndex];
    final fromGroupData = _groupDatas.removeAt(fromIndex);

    _groupDatas.insert(toIndex, fromGroupData);
    onMoveGroup?.call(fromGroupData.id, fromIndex, toGroupData.id, toIndex);
    if (notify) notifyListeners();
  }

  void moveGroupItem(String groupId, int fromIndex, int toIndex) {
    if (getGroupController(groupId)?.move(fromIndex, toIndex) ?? false) {
      onMoveGroupItem?.call(groupId, fromIndex, toIndex);
    }
  }

  void addGroupItem(String groupId, AppFlowyGroupItem item) {
    getGroupController(groupId)?.add(item);
  }

  void insertGroupItem(String groupId, int index, AppFlowyGroupItem item) {
    getGroupController(groupId)?.insert(index, item);
  }

  void removeGroupItem(String groupId, String itemId) {
    getGroupController(groupId)?.removeWhere((item) => item.id == itemId);
  }

  void updateGroupItem(String groupId, AppFlowyGroupItem item) {
    getGroupController(groupId)?.replaceOrInsertItem(item);
  }

  @override
  @protected
  void swapGroupItem(
    String fromGroupId,
    int fromGroupIndex,
    String toGroupId,
    int toGroupIndex,
  ) {
    final fromGroupController = getGroupController(fromGroupId)!;
    final toGroupController = getGroupController(toGroupId)!;
    final item = fromGroupController.removeAt(fromGroupIndex);
    if (toGroupController.items.length > toGroupIndex) {
      assert(toGroupController.items[toGroupIndex] is PhantomGroupItem);
    }

    toGroupController.replace(toGroupIndex, item);
    onMoveGroupItemToGroup?.call(
      fromGroupId,
      fromGroupIndex,
      toGroupId,
      toGroupIndex,
    );
  }

  @override
  List<Object?> get props {
    return [_groupDatas];
  }

  @override
  AFBoardGroupDataController? controller(String groupId) {
    return _groupControllers[groupId];
  }

  @override
  String get identifier => '$AppFlowyBoardDataController';

  @override
  UnmodifiableListView<ReoderFlexItem> get items =>
      UnmodifiableListView(_groupDatas);

  @override
  @protected
  bool removePhantom(String groupId) {
    final groupController = getGroupController(groupId);
    if (groupController == null) {
      Log.warn('Can not find the group controller with groupId: $groupId');
      return false;
    }
    final index = groupController.items.indexWhere((item) => item.isPhantom);
    final isExist = index != -1;
    if (isExist) {
      groupController.removeAt(index);

      Log.debug(
          '[$AppFlowyBoardDataController] Group:[$groupId] remove phantom, current count: ${groupController.items.length}');
    }
    return isExist;
  }

  @override
  @protected
  void updatePhantom(String groupId, int newIndex) {
    final groupController = getGroupController(groupId)!;
    final index = groupController.items.indexWhere((item) => item.isPhantom);

    if (index != -1) {
      if (index != newIndex) {
        Log.trace(
            '[$BoardPhantomController] update $groupId:$index to $groupId:$newIndex');
        final item = groupController.removeAt(index, notify: false);
        groupController.insert(newIndex, item, notify: false);
      }
    }
  }

  @override
  @protected
  void insertPhantom(String groupId, int index, PhantomGroupItem item) {
    getGroupController(groupId)!.insert(index, item);
  }
}
