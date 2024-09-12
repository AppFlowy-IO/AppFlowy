import 'dart:async';
import 'dart:collection';

import 'package:appflowy/plugins/database/application/defines.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy/plugins/database/board/group_ext.dart';
import 'package:appflowy/plugins/database/domain/group_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_board/appflowy_board.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:protobuf/protobuf.dart' hide FieldInfo;
import 'package:universal_platform/universal_platform.dart';

import '../../application/database_controller.dart';
import '../../application/field/field_controller.dart';
import '../../application/row/row_cache.dart';
import 'group_controller.dart';

part 'board_bloc.freezed.dart';

class BoardBloc extends Bloc<BoardEvent, BoardState> {
  BoardBloc({
    required this.databaseController,
    this.didCreateRow,
    AppFlowyBoardController? boardController,
  }) : super(const BoardState.loading()) {
    groupBackendSvc = GroupBackendService(viewId);
    _initBoardController(boardController);
    _dispatch();
  }

  final DatabaseController databaseController;
  late final AppFlowyBoardController boardController;
  final LinkedHashMap<String, GroupController> groupControllers =
      LinkedHashMap();
  final List<GroupPB> groupList = [];

  final ValueNotifier<DidCreateRowResult?>? didCreateRow;

  late final GroupBackendService groupBackendSvc;

  FieldController get fieldController => databaseController.fieldController;
  String get viewId => databaseController.viewId;

  void _initBoardController(AppFlowyBoardController? controller) {
    boardController = controller ??
        AppFlowyBoardController(
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
            final fromRow =
                groupControllers[fromGroupId]?.rowAtIndex(fromIndex);
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
  }

  void _dispatch() {
    on<BoardEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            emit(BoardState.initial(viewId));
            _startListening();
            await _openDatabase(emit);
          },
          createRow: (groupId, position, title, targetRowId) async {
            final primaryField = databaseController.fieldController.fieldInfos
                .firstWhereOrNull((element) => element.isPrimary)!;
            final void Function(RowDataBuilder)? cellBuilder = title == null
                ? null
                : (builder) => builder.insertText(primaryField, title);

            final result = await RowBackendService.createRow(
              viewId: databaseController.viewId,
              groupId: groupId,
              position: position,
              targetRowId: targetRowId,
              withCells: cellBuilder,
            );

            final startEditing = position != OrderObjectPositionTypePB.End;
            final action = UniversalPlatform.isMobile
                ? DidCreateRowAction.openAsPage
                : startEditing
                    ? DidCreateRowAction.startEditing
                    : DidCreateRowAction.none;

            result.fold(
              (rowMeta) {
                state.maybeMap(
                  ready: (value) {
                    didCreateRow?.value = DidCreateRowResult(
                      action: action,
                      rowMeta: rowMeta,
                      groupId: groupId,
                    );
                  },
                  orElse: () {},
                );
              },
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
          renameGroup: (groupId, name) async {
            final result = await groupBackendSvc.updateGroup(
              groupId: groupId,
              name: name,
            );
            result.fold((_) {}, (err) => Log.error(err));
          },
          didReceiveError: (error) {
            emit(BoardState.error(error: error));
          },
          didReceiveGroups: (List<GroupPB> groups) {
            state.maybeMap(
              ready: (state) {
                emit(
                  state.copyWith(
                    hiddenGroups: _filterHiddenGroups(hideUngrouped, groups),
                    groupIds: groups.map((group) => group.groupId).toList(),
                  ),
                );
              },
              orElse: () {},
            );
          },
          didUpdateLayoutSettings: (layoutSettings) {
            state.maybeMap(
              ready: (state) {
                emit(
                  state.copyWith(
                    layoutSettings: layoutSettings,
                    hiddenGroups: _filterHiddenGroups(hideUngrouped, groupList),
                  ),
                );
              },
              orElse: () {},
            );
          },
          setGroupVisibility: (GroupPB group, bool isVisible) async {
            await _setGroupVisibility(group, isVisible);
          },
          toggleHiddenSectionVisibility: (isVisible) async {
            await state.maybeMap(
              ready: (state) async {
                final newLayoutSettings = state.layoutSettings!;
                newLayoutSettings.freeze();

                final newLayoutSetting = newLayoutSettings.rebuild(
                  (message) => message.collapseHiddenGroups = isVisible,
                );

                await databaseController.updateLayoutSetting(
                  boardLayoutSetting: newLayoutSetting,
                );
              },
              orElse: () {},
            );
          },
          reorderGroup: (fromGroupId, toGroupId) async {
            _reorderGroup(fromGroupId, toGroupId, emit);
          },
          startEditingHeader: (String groupId) {
            state.maybeMap(
              ready: (state) => emit(state.copyWith(editingHeaderId: groupId)),
              orElse: () {},
            );
          },
          endEditingHeader: (String groupId, String? groupName) async {
            final group = groupControllers[groupId]?.group;
            if (group != null) {
              final currentName = group.generateGroupName(databaseController);
              if (currentName != groupName) {
                await groupBackendSvc.updateGroup(
                  groupId: groupId,
                  name: groupName,
                );
              }
            }

            state.maybeMap(
              ready: (state) => emit(state.copyWith(editingHeaderId: null)),
              orElse: () {},
            );
          },
          deleteCards: (groupedRowIds) async {
            final rowIds = groupedRowIds.map((e) => e.rowId).toList();
            await RowBackendService.deleteRows(viewId, rowIds);
          },
          moveGroupToAdjacentGroup: (groupedRowId, toPrevious) async {
            final fromRow =
                databaseController.rowCache.getRow(groupedRowId.rowId)?.rowMeta;
            final currentGroupIndex =
                boardController.groupIds.indexOf(groupedRowId.groupId);
            final toGroupIndex =
                toPrevious ? currentGroupIndex - 1 : currentGroupIndex + 1;
            if (fromRow != null &&
                toGroupIndex > -1 &&
                toGroupIndex < boardController.groupIds.length) {
              final toGroupId = boardController.groupDatas[toGroupIndex].id;
              final result = await databaseController.moveGroupRow(
                fromRow: fromRow,
                fromGroupId: groupedRowId.groupId,
                toGroupId: toGroupId,
              );
              result.fold(
                (s) {
                  final previousState = state;
                  emit(
                    BoardState.setFocus(
                      groupedRowIds: [
                        GroupedRowId(
                          groupId: toGroupId,
                          rowId: groupedRowId.rowId,
                        ),
                      ],
                    ),
                  );
                  emit(previousState);
                },
                (f) {},
              );
            }
          },
        );
      },
    );
  }

  Future<void> _setGroupVisibility(GroupPB group, bool isVisible) async {
    if (group.isDefault) {
      await state.maybeMap(
        ready: (state) async {
          final newLayoutSettings = state.layoutSettings!;
          newLayoutSettings.freeze();

          final newLayoutSetting = newLayoutSettings.rebuild(
            (message) => message.hideUngroupedColumn = !isVisible,
          );

          await databaseController.updateLayoutSetting(
            boardLayoutSetting: newLayoutSetting,
          );
        },
        orElse: () {},
      );
    } else {
      await groupBackendSvc.updateGroup(
        groupId: group.groupId,
        visible: isVisible,
      );
    }
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
    boardController.dispose();
    return super.close();
  }

  bool get hideUngrouped =>
      databaseController.databaseLayoutSetting?.board.hideUngroupedColumn ??
      false;

  FieldType? get groupingFieldType {
    if (groupList.isEmpty) {
      return null;
    }
    return databaseController.fieldController
        .getField(groupList.first.fieldId)
        ?.fieldType;
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

  RowCache get rowCache => databaseController.rowCache;

  void _startListening() {
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
            columnController.updateGroupName(
              group.generateGroupName(databaseController),
            );
            if (!group.isVisible) {
              boardController.removeGroup(group.groupId);
            }
          } else {
            final newGroup = _initializeGroupData(group);
            final visibleGroups = [...groupList]..retainWhere(
                (g) =>
                    (g.isVisible && !g.isDefault) ||
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

  Future<void> _openDatabase(Emitter<BoardState> emit) {
    return databaseController.open().fold(
          (datbasePB) => databaseController.setIsLoading(false),
          (err) => emit(BoardState.error(error: err)),
        );
  }

  GroupController _initializeGroupController(GroupPB group) {
    group.freeze();

    final delegate = GroupControllerDelegateImpl(
      controller: boardController,
      fieldController: fieldController,
      onNewColumnItem: (groupId, row, index) {},
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
      name: group.generateGroupName(databaseController),
      items: _buildGroupItems(group),
      customData: GroupData(
        group: group,
        fieldInfo: fieldController.getField(group.fieldId)!,
      ),
    );
  }
}

@freezed
class BoardEvent with _$BoardEvent {
  const factory BoardEvent.initial() = _InitialBoard;
  const factory BoardEvent.createRow(
    String groupId,
    OrderObjectPositionTypePB position,
    String? title,
    String? targetRowId,
  ) = _CreateRow;
  const factory BoardEvent.createGroup(String name) = _CreateGroup;
  const factory BoardEvent.startEditingHeader(String groupId) =
      _StartEditingHeader;
  const factory BoardEvent.endEditingHeader(String groupId, String? groupName) =
      _EndEditingHeader;
  const factory BoardEvent.setGroupVisibility(
    GroupPB group,
    bool isVisible,
  ) = _SetGroupVisibility;
  const factory BoardEvent.toggleHiddenSectionVisibility(bool isVisible) =
      _ToggleHiddenSectionVisibility;
  const factory BoardEvent.renameGroup(String groupId, String name) =
      _RenameGroup;
  const factory BoardEvent.deleteGroup(String groupId) = _DeleteGroup;
  const factory BoardEvent.reorderGroup(String fromGroupId, String toGroupId) =
      _ReorderGroup;
  const factory BoardEvent.didReceiveError(FlowyError error) = _DidReceiveError;
  const factory BoardEvent.didReceiveGroups(List<GroupPB> groups) =
      _DidReceiveGroups;
  const factory BoardEvent.didUpdateLayoutSettings(
    BoardLayoutSettingPB layoutSettings,
  ) = _DidUpdateLayoutSettings;
  const factory BoardEvent.deleteCards(List<GroupedRowId> groupedRowIds) =
      _DeleteCards;
  const factory BoardEvent.moveGroupToAdjacentGroup(
    GroupedRowId groupedRowId,
    bool toPrevious,
  ) = _MoveGroupToAdjacentGroup;
}

@freezed
class BoardState with _$BoardState {
  const BoardState._();

  const factory BoardState.loading() = _BoardLoadingState;

  const factory BoardState.error({
    required FlowyError error,
  }) = _BoardErrorState;

  const factory BoardState.ready({
    required String viewId,
    required List<String> groupIds,
    required LoadingState loadingState,
    required FlowyError? noneOrError,
    required BoardLayoutSettingPB? layoutSettings,
    required List<GroupPB> hiddenGroups,
    String? editingHeaderId,
  }) = _BoardReadyState;

  const factory BoardState.setFocus({
    required List<GroupedRowId> groupedRowIds,
  }) = _BoardSetFocusState;

  factory BoardState.initial(String viewId) => BoardState.ready(
        viewId: viewId,
        groupIds: [],
        noneOrError: null,
        loadingState: const LoadingState.loading(),
        layoutSettings: null,
        hiddenGroups: [],
      );

  bool get isLoading => maybeMap(loading: (_) => true, orElse: () => false);
  bool get isError => maybeMap(error: (_) => true, orElse: () => false);
  bool get isReady => maybeMap(ready: (_) => true, orElse: () => false);
  bool get isSetFocus => maybeMap(setFocus: (_) => true, orElse: () => false);
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
  });

  final RowMetaPB row;
  final FieldInfo fieldInfo;

  @override
  String get id => row.id.toString();
}

/// Identifies a card in a database view that has grouping. To support cases
/// in which a card can belong to more than one group at the same time (e.g.
/// FieldType.Multiselect), we include the card's group id as well.
///
class GroupedRowId extends Equatable {
  const GroupedRowId({
    required this.rowId,
    required this.groupId,
  });

  final String rowId;
  final String groupId;

  @override
  List<Object?> get props => [rowId, groupId];
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

    final item = GroupItem(row: row, fieldInfo: fieldInfo);

    if (index != null) {
      controller.insertGroupItem(group.groupId, index, item);
    } else {
      controller.addGroupItem(group.groupId, item);
    }

    onNewColumnItem(group.groupId, row, index);
  }
}

class GroupData {
  const GroupData({
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

enum DidCreateRowAction {
  none,
  openAsPage,
  startEditing,
}

class DidCreateRowResult {
  DidCreateRowResult({
    required this.action,
    required this.rowMeta,
    required this.groupId,
  });

  final DidCreateRowAction action;
  final RowMetaPB rowMeta;
  final String groupId;
}
