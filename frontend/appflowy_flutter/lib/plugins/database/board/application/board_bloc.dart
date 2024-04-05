import 'dart:async';
import 'dart:collection';

import 'package:appflowy/plugins/database/application/defines.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/domain/group_service.dart';
import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_board/appflowy_board.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';
import 'package:protobuf/protobuf.dart' hide FieldInfo;

import '../../application/database_controller.dart';
import '../../application/field/field_controller.dart';
import '../../application/row/row_cache.dart';
import 'group_controller.dart';

part 'board_bloc.freezed.dart';

class BoardBloc extends Bloc<BoardEvent, BoardState> {
  BoardBloc({
    required ViewPB view,
    required this.databaseController,
  }) : super(BoardState.initial(view.id)) {
    groupBackendSvc = GroupBackendService(viewId);
    boardController = AppFlowyBoardController(
      onMoveGroup: (fromGroupId, fromIndex, toGroupId, toIndex) =>
          databaseController.moveGroup(
        fromGroupId: fromGroupId,
        toGroupId: toGroupId,
      ),
      onMoveGroupItem: (groupId, fromIndex, toIndex) {
        final fromRow = groupControllers[groupId]?.rowAtIndex(fromIndex);
        final toRow = groupControllers[groupId]?.rowAtIndex(toIndex);
        if (fromRow != null) {
          databaseController.moveGroupRow(
            fromRow: fromRow,
            toRow: toRow,
            fromGroupId: groupId,
            toGroupId: groupId,
          );
        }
      },
      onMoveGroupItemToGroup: (fromGroupId, fromIndex, toGroupId, toIndex) {
        final fromRow = groupControllers[fromGroupId]?.rowAtIndex(fromIndex);
        final toRow = groupControllers[toGroupId]?.rowAtIndex(toIndex);
        if (fromRow != null) {
          databaseController.moveGroupRow(
            fromRow: fromRow,
            toRow: toRow,
            fromGroupId: fromGroupId,
            toGroupId: toGroupId,
          );
        }
      },
    );

    _dispatch();
  }

  final DatabaseController databaseController;
  final LinkedHashMap<String, GroupController> groupControllers =
      LinkedHashMap();
  final List<GroupPB> groupList = [];

  late final AppFlowyBoardController boardController;
  late final GroupBackendService groupBackendSvc;

  FieldController get fieldController => databaseController.fieldController;
  String get viewId => databaseController.viewId;

  void _dispatch() {
    on<BoardEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _startListening();
            await _openGrid(emit);
          },
          createHeaderRow: (groupId) async {
            final rowId = groupControllers[groupId]?.firstRow()?.id;
            final position = rowId == null
                ? OrderObjectPositionTypePB.Start
                : OrderObjectPositionTypePB.Before;
            final result = await RowBackendService.createRow(
              viewId: databaseController.viewId,
              groupId: groupId,
              position: position,
              targetRowId: rowId,
            );

            result.fold(
              (rowMeta) => emit(state.copyWith(recentAddedRowMeta: rowMeta)),
              (err) => Log.error(err),
            );
          },
          createBottomRow: (groupId) async {
            final rowId = groupControllers[groupId]?.lastRow()?.id;
            final position = rowId == null
                ? OrderObjectPositionTypePB.End
                : OrderObjectPositionTypePB.After;
            final result = await RowBackendService.createRow(
              viewId: databaseController.viewId,
              groupId: groupId,
              position: position,
              targetRowId: rowId,
            );

            result.fold(
              (rowMeta) => emit(state.copyWith(recentAddedRowMeta: rowMeta)),
              (err) => Log.error(err),
            );
          },
          createGroup: (name) async {
            final result = await groupBackendSvc.createGroup(name: name);
            result.fold((_) {}, (err) => Log.error(err));
          },
          deleteGroup: (groupId) async {
            final result = await groupBackendSvc.deleteGroup(groupId: groupId);
            result.fold((_) {}, (err) => Log.error(err));
          },
          didCreateRow: (group, row, int? index) {
            emit(
              state.copyWith(
                isEditingRow: true,
                editingRow: BoardEditingRow(
                  group: group,
                  row: row,
                  index: index,
                ),
              ),
            );
            _groupItemStartEditing(group, row, true);
          },
          didReceiveGridUpdate: (DatabasePB grid) {
            emit(state.copyWith(grid: grid));
          },
          didReceiveError: (FlowyError error) {
            emit(state.copyWith(noneOrError: error));
          },
          didReceiveGroups: (List<GroupPB> groups) {
            final hiddenGroups = _filterHiddenGroups(hideUngrouped, groups);
            emit(
              state.copyWith(
                hiddenGroups: hiddenGroups,
                groupIds: groups.map((group) => group.groupId).toList(),
              ),
            );
          },
          didUpdateLayoutSettings: (layoutSettings) {
            final hiddenGroups = _filterHiddenGroups(hideUngrouped, groupList);
            emit(
              state.copyWith(
                layoutSettings: layoutSettings,
                hiddenGroups: hiddenGroups,
              ),
            );
          },
          toggleGroupVisibility: (GroupPB group, bool isVisible) async {
            await _toggleGroupVisibility(group, isVisible);
          },
          toggleHiddenSectionVisibility: (isVisible) async {
            final newLayoutSettings = state.layoutSettings!;
            newLayoutSettings.freeze();

            final newLayoutSetting = newLayoutSettings.rebuild(
              (message) => message.collapseHiddenGroups = isVisible,
            );

            await databaseController.updateLayoutSetting(
              boardLayoutSetting: newLayoutSetting,
            );
          },
          reorderGroup: (fromGroupId, toGroupId) async {
            _reorderGroup(fromGroupId, toGroupId, emit);
          },
          startEditingRow: (group, row) {
            emit(
              state.copyWith(
                isEditingRow: true,
                editingRow: BoardEditingRow(
                  group: group,
                  row: row,
                  index: null,
                ),
              ),
            );
            _groupItemStartEditing(group, row, true);
          },
          endEditingRow: (rowId) {
            if (state.editingRow != null && state.isEditingRow) {
              assert(state.editingRow!.row.id == rowId);
              _groupItemStartEditing(
                state.editingRow!.group,
                state.editingRow!.row,
                false,
              );

              emit(state.copyWith(isEditingRow: false, editingRow: null));
            }
          },
          startEditingHeader: (String groupId) {
            emit(
              state.copyWith(isEditingHeader: true, editingHeaderId: groupId),
            );
          },
          endEditingHeader: (String groupId, String? groupName) async {
            await groupBackendSvc.updateGroup(
              fieldId: groupControllers.values.first.group.fieldId,
              groupId: groupId,
              name: groupName,
            );
            emit(state.copyWith(isEditingHeader: false));
          },
        );
      },
    );
  }

  void _groupItemStartEditing(GroupPB group, RowMetaPB row, bool isEdit) {
    final fieldInfo = fieldController.getField(group.fieldId);
    if (fieldInfo == null) {
      return Log.warn("fieldInfo should not be null");
    }

    boardController.enableGroupDragging(!isEdit);
  }

  Future<void> _toggleGroupVisibility(GroupPB group, bool isVisible) async {
    if (group.isDefault) {
      final newLayoutSettings = state.layoutSettings!;
      newLayoutSettings.freeze();

      final newLayoutSetting = newLayoutSettings.rebuild(
        (message) => message.hideUngroupedColumn = !isVisible,
      );

      return databaseController.updateLayoutSetting(
        boardLayoutSetting: newLayoutSetting,
      );
    }

    await groupBackendSvc.updateGroup(
      fieldId: groupControllers.values.first.group.fieldId,
      groupId: group.groupId,
      visible: isVisible,
    );
  }

  void _reorderGroup(
    String fromGroupId,
    String toGroupId,
    Emitter<BoardState> emit,
  ) async {
    final fromIndex = groupList.indexWhere((g) => g.groupId == fromGroupId);
    final toIndex = groupList.indexWhere((g) => g.groupId == toGroupId);
    final group = groupList.removeAt(fromIndex);
    groupList.insert(toIndex, group);
    add(BoardEvent.didReceiveGroups(groupList));
    final result = await databaseController.moveGroup(
      fromGroupId: fromGroupId,
      toGroupId: toGroupId,
    );
    result.fold((l) => {}, (err) => Log.error(err));
  }

  @override
  Future<void> close() async {
    for (final controller in groupControllers.values) {
      await controller.dispose();
    }
    return super.close();
  }

  bool get hideUngrouped =>
      databaseController.databaseLayoutSetting?.board.hideUngroupedColumn ??
      false;

  FieldType get groupingFieldType {
    final fieldInfo =
        databaseController.fieldController.getField(groupList.first.fieldId)!;

    return fieldInfo.fieldType;
  }

  void initializeGroups(List<GroupPB> groups) {
    for (final controller in groupControllers.values) {
      controller.dispose();
    }

    groupControllers.clear();
    boardController.clear();
    groupList.clear();
    groupList.addAll(groups);

    boardController.addGroups(
      groups
          .where((group) {
            final field = fieldController.getField(group.fieldId);
            return field != null &&
                (!group.isDefault && group.isVisible ||
                    group.isDefault &&
                        !hideUngrouped &&
                        field.fieldType != FieldType.Checkbox);
          })
          .map((group) => _initializeGroupData(group))
          .toList(),
    );

    for (final group in groups) {
      final controller = _initializeGroupController(group);
      groupControllers[controller.group.groupId] = controller;
    }
  }

  RowCache? getRowCache() => databaseController.rowCache;

  void _startListening() {
    final onDatabaseChanged = DatabaseCallbacks(
      onDatabaseChanged: (database) {
        if (!isClosed) {
          add(BoardEvent.didReceiveGridUpdate(database));
        }
      },
    );
    final onLayoutSettingsChanged = DatabaseLayoutSettingCallbacks(
      onLayoutSettingsChanged: (layoutSettings) {
        if (isClosed) {
          return;
        }
        final index = groupList.indexWhere((element) => element.isDefault);
        if (index != -1) {
          if (layoutSettings.board.hideUngroupedColumn) {
            boardController.removeGroup(groupList[index].fieldId);
          } else {
            final newGroup = _initializeGroupData(groupList[index]);
            final visibleGroups = [...groupList]
              ..retainWhere((g) => g.isVisible || g.isDefault);
            final indexInVisibleGroups =
                visibleGroups.indexWhere((g) => g.isDefault);
            if (indexInVisibleGroups != -1) {
              boardController.insertGroup(indexInVisibleGroups, newGroup);
            }
          }
        }
        add(BoardEvent.didUpdateLayoutSettings(layoutSettings.board));
      },
    );
    final onGroupChanged = GroupCallbacks(
      onGroupByField: (groups) {
        if (isClosed) {
          return;
        }

        initializeGroups(groups);
        add(BoardEvent.didReceiveGroups(groups));
      },
      onDeleteGroup: (groupIds) {
        if (isClosed) {
          return;
        }

        boardController.removeGroups(groupIds);
        groupList.removeWhere((group) => groupIds.contains(group.groupId));
        add(BoardEvent.didReceiveGroups(groupList));
      },
      onInsertGroup: (insertGroups) {
        if (isClosed) {
          return;
        }

        final group = insertGroups.group;
        final newGroup = _initializeGroupData(group);
        final controller = _initializeGroupController(group);
        groupControllers[controller.group.groupId] = controller;
        boardController.addGroup(newGroup);
        groupList.insert(insertGroups.index, group);
        add(BoardEvent.didReceiveGroups(groupList));
      },
      onUpdateGroup: (updatedGroups) async {
        if (isClosed) {
          return;
        }

        // workaround: update group most of the time gets called before fields in
        // field controller are updated. For single and multi-select group
        // renames, this is required before generating the new group name.
        await Future.delayed(const Duration(milliseconds: 50));

        for (final group in updatedGroups) {
          // see if the column is already in the board
          final index = groupList.indexWhere((g) => g.groupId == group.groupId);
          if (index == -1) {
            continue;
          }

          final columnController =
              boardController.getGroupController(group.groupId);
          if (columnController != null) {
            // remove the group or update its name
            columnController.updateGroupName(generateGroupNameFromGroup(group));
            if (!group.isVisible) {
              boardController.removeGroup(group.groupId);
            }
          } else {
            final newGroup = _initializeGroupData(group);
            final visibleGroups = [...groupList]..retainWhere(
                (g) =>
                    g.isVisible ||
                    g.isDefault && !hideUngrouped ||
                    g.groupId == group.groupId,
              );
            final indexInVisibleGroups =
                visibleGroups.indexWhere((g) => g.groupId == group.groupId);
            if (indexInVisibleGroups != -1) {
              boardController.insertGroup(indexInVisibleGroups, newGroup);
            }
          }

          groupList.removeAt(index);
          groupList.insert(index, group);
        }
        add(BoardEvent.didReceiveGroups(groupList));
      },
    );

    databaseController.addListener(
      onDatabaseChanged: onDatabaseChanged,
      onLayoutSettingsChanged: onLayoutSettingsChanged,
      onGroupChanged: onGroupChanged,
    );
  }

  List<AppFlowyGroupItem> _buildGroupItems(GroupPB group) {
    final items = group.rows.map((row) {
      final fieldInfo = fieldController.getField(group.fieldId);
      return GroupItem(
        row: row,
        fieldInfo: fieldInfo!,
      );
    }).toList();

    return <AppFlowyGroupItem>[...items];
  }

  Future<void> _openGrid(Emitter<BoardState> emit) async {
    final result = await databaseController.open();
    result.fold(
      (grid) {
        databaseController.setIsLoading(false);
        emit(
          state.copyWith(
            loadingState: LoadingState.finish(FlowyResult.success(null)),
          ),
        );
      },
      (err) => emit(
        state.copyWith(
          loadingState: LoadingState.finish(FlowyResult.failure(err)),
        ),
      ),
    );
  }

  GroupController _initializeGroupController(GroupPB group) {
    final delegate = GroupControllerDelegateImpl(
      controller: boardController,
      fieldController: fieldController,
      onNewColumnItem: (groupId, row, index) =>
          add(BoardEvent.didCreateRow(group, row, index)),
    );

    final controller = GroupController(
      group: group,
      delegate: delegate,
      onGroupChanged: (newGroup) {
        if (isClosed) return;

        final index =
            groupList.indexWhere((g) => g.groupId == newGroup.groupId);
        if (index != -1) {
          groupList.removeAt(index);
          groupList.insert(index, newGroup);
          add(BoardEvent.didReceiveGroups(groupList));
        }
      },
    );

    return controller..startListening();
  }

  AppFlowyGroupData _initializeGroupData(GroupPB group) {
    return AppFlowyGroupData(
      id: group.groupId,
      name: generateGroupNameFromGroup(group),
      items: _buildGroupItems(group),
      customData: GroupData(
        group: group,
        fieldInfo: fieldController.getField(group.fieldId)!,
      ),
    );
  }

  String generateGroupNameFromGroup(GroupPB group) {
    final field = fieldController.getField(group.fieldId);
    if (field == null) {
      return "";
    }

    // if the group is the default group, then
    if (group.isDefault) {
      return "No ${field.name}";
    }

    switch (field.fieldType) {
      case FieldType.SingleSelect:
        final options =
            SingleSelectTypeOptionPB.fromBuffer(field.field.typeOptionData)
                .options;
        final option =
            options.firstWhereOrNull((option) => option.id == group.groupId);
        return option == null ? "" : option.name;
      case FieldType.MultiSelect:
        final options =
            MultiSelectTypeOptionPB.fromBuffer(field.field.typeOptionData)
                .options;
        final option =
            options.firstWhereOrNull((option) => option.id == group.groupId);
        return option == null ? "" : option.name;
      case FieldType.Checkbox:
        return group.groupId;
      case FieldType.URL:
        return group.groupId;
      case FieldType.DateTime:
        // Assume DateCondition::Relative as there isn't an option for this
        // right now.
        final dateFormat = DateFormat("y/MM/dd");
        try {
          final targetDateTime = dateFormat.parseLoose(group.groupId);
          final targetDateTimeDay = DateTime(
            targetDateTime.year,
            targetDateTime.month,
            targetDateTime.day,
          );
          final now = DateTime.now();
          final nowDay = DateTime(
            now.year,
            now.month,
            now.day,
          );
          final diff = targetDateTimeDay.difference(nowDay).inDays;
          return switch (diff) {
            0 => "Today",
            -1 => "Yesterday",
            1 => "Tomorrow",
            -7 => "Last 7 days",
            2 => "Next 7 days",
            -30 => "Last 30 days",
            8 => "Next 30 days",
            _ => DateFormat("MMM y").format(targetDateTimeDay)
          };
        } on FormatException {
          return "";
        }
      default:
        return "";
    }
  }
}

@freezed
class BoardEvent with _$BoardEvent {
  const factory BoardEvent.initial() = _InitialBoard;
  const factory BoardEvent.createBottomRow(String groupId) = _CreateBottomRow;
  const factory BoardEvent.createHeaderRow(String groupId) = _CreateHeaderRow;
  const factory BoardEvent.createGroup(String name) = _CreateGroup;
  const factory BoardEvent.startEditingHeader(String groupId) =
      _StartEditingHeader;
  const factory BoardEvent.endEditingHeader(String groupId, String? groupName) =
      _EndEditingHeader;
  const factory BoardEvent.didCreateRow(
    GroupPB group,
    RowMetaPB row,
    int? index,
  ) = _DidCreateRow;
  const factory BoardEvent.startEditingRow(
    GroupPB group,
    RowMetaPB row,
  ) = _StartEditRow;
  const factory BoardEvent.endEditingRow(RowId rowId) = _EndEditRow;
  const factory BoardEvent.toggleGroupVisibility(
    GroupPB group,
    bool isVisible,
  ) = _ToggleGroupVisibility;
  const factory BoardEvent.toggleHiddenSectionVisibility(bool isVisible) =
      _ToggleHiddenSectionVisibility;
  const factory BoardEvent.deleteGroup(String groupId) = _DeleteGroup;
  const factory BoardEvent.reorderGroup(String fromGroupId, String toGroupId) =
      _ReorderGroup;
  const factory BoardEvent.didReceiveError(FlowyError error) = _DidReceiveError;
  const factory BoardEvent.didReceiveGridUpdate(
    DatabasePB grid,
  ) = _DidReceiveGridUpdate;
  const factory BoardEvent.didReceiveGroups(List<GroupPB> groups) =
      _DidReceiveGroups;
  const factory BoardEvent.didUpdateLayoutSettings(
    BoardLayoutSettingPB layoutSettings,
  ) = _DidUpdateLayoutSettings;
}

@freezed
class BoardState with _$BoardState {
  const factory BoardState({
    required String viewId,
    required DatabasePB? grid,
    required List<String> groupIds,
    required bool isEditingHeader,
    required bool isEditingRow,
    required LoadingState loadingState,
    required FlowyError? noneOrError,
    required BoardLayoutSettingPB? layoutSettings,
    String? editingHeaderId,
    BoardEditingRow? editingRow,
    RowMetaPB? recentAddedRowMeta,
    required List<GroupPB> hiddenGroups,
  }) = _BoardState;

  factory BoardState.initial(String viewId) => BoardState(
        grid: null,
        viewId: viewId,
        groupIds: [],
        isEditingHeader: false,
        isEditingRow: false,
        noneOrError: null,
        loadingState: const LoadingState.loading(),
        layoutSettings: null,
        hiddenGroups: [],
      );
}

List<GroupPB> _filterHiddenGroups(bool hideUngrouped, List<GroupPB> groups) {
  return [...groups]..retainWhere(
      (group) => !group.isVisible || group.isDefault && hideUngrouped,
    );
}

class GroupItem extends AppFlowyGroupItem {
  GroupItem({
    required this.row,
    required this.fieldInfo,
    bool draggable = true,
  }) {
    super.draggable = draggable;
  }

  final RowMetaPB row;
  final FieldInfo fieldInfo;

  @override
  String get id => row.id.toString();
}

class GroupControllerDelegateImpl extends GroupControllerDelegate {
  GroupControllerDelegateImpl({
    required this.controller,
    required this.fieldController,
    required this.onNewColumnItem,
  });

  final FieldController fieldController;
  final AppFlowyBoardController controller;
  final void Function(String, RowMetaPB, int?) onNewColumnItem;

  @override
  bool hasGroup(String groupId) => controller.groupIds.contains(groupId);

  @override
  void insertRow(GroupPB group, RowMetaPB row, int? index) {
    final fieldInfo = fieldController.getField(group.fieldId);
    if (fieldInfo == null) {
      return Log.warn("fieldInfo should not be null");
    }

    if (index != null) {
      final item = GroupItem(
        row: row,
        fieldInfo: fieldInfo,
      );
      controller.insertGroupItem(group.groupId, index, item);
    } else {
      final item = GroupItem(
        row: row,
        fieldInfo: fieldInfo,
      );
      controller.addGroupItem(group.groupId, item);
    }
  }

  @override
  void removeRow(GroupPB group, RowId rowId) =>
      controller.removeGroupItem(group.groupId, rowId.toString());

  @override
  void updateRow(GroupPB group, RowMetaPB row) {
    final fieldInfo = fieldController.getField(group.fieldId);
    if (fieldInfo == null) {
      return Log.warn("fieldInfo should not be null");
    }

    controller.updateGroupItem(
      group.groupId,
      GroupItem(
        row: row,
        fieldInfo: fieldInfo,
      ),
    );
  }

  @override
  void addNewRow(GroupPB group, RowMetaPB row, int? index) {
    final fieldInfo = fieldController.getField(group.fieldId);
    if (fieldInfo == null) {
      return Log.warn("fieldInfo should not be null");
    }

    final item = GroupItem(row: row, fieldInfo: fieldInfo, draggable: false);

    if (index != null) {
      controller.insertGroupItem(group.groupId, index, item);
    } else {
      controller.addGroupItem(group.groupId, item);
    }

    onNewColumnItem(group.groupId, row, index);
  }
}

class BoardEditingRow {
  BoardEditingRow({
    required this.group,
    required this.row,
    required this.index,
  });

  GroupPB group;
  RowMetaPB row;
  int? index;
}

class GroupData {
  GroupData({
    required this.group,
    required this.fieldInfo,
  });

  final GroupPB group;
  final FieldInfo fieldInfo;

  CheckboxGroup? asCheckboxGroup() =>
      fieldType == FieldType.Checkbox ? CheckboxGroup(group) : null;

  FieldType get fieldType => fieldInfo.fieldType;
}

class CheckboxGroup {
  const CheckboxGroup(this.group);

  final GroupPB group;

  // Hardcode value: "Yes" that equal to the value defined in Rust
  // pub const CHECK: &str = "Yes";
  bool get isCheck => group.groupId == "Yes";
}
