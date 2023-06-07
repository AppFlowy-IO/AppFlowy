import 'dart:async';
import 'dart:collection';

import 'package:appflowy/plugins/database_view/application/row/row_service.dart';
import 'package:appflowy_board/appflowy_board.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../application/field/field_controller.dart';
import '../../application/row/row_cache.dart';
import '../../application/database_controller.dart';
import 'group_controller.dart';

part 'board_bloc.freezed.dart';

class BoardBloc extends Bloc<BoardEvent, BoardState> {
  final DatabaseController databaseController;
  late final AppFlowyBoardController boardController;
  final LinkedHashMap<String, GroupController> groupControllers =
      LinkedHashMap();

  FieldController get fieldController => databaseController.fieldController;
  String get viewId => databaseController.viewId;

  BoardBloc({required ViewPB view})
      : databaseController = DatabaseController(
          view: view,
        ),
        super(BoardState.initial(view.id)) {
    boardController = AppFlowyBoardController(
      onMoveGroup: (
        fromGroupId,
        fromIndex,
        toGroupId,
        toIndex,
      ) {
        databaseController.moveGroup(
          fromGroupId: fromGroupId,
          toGroupId: toGroupId,
        );
      },
      onMoveGroupItem: (
        groupId,
        fromIndex,
        toIndex,
      ) {
        final fromRow = groupControllers[groupId]?.rowAtIndex(fromIndex);
        final toRow = groupControllers[groupId]?.rowAtIndex(toIndex);
        if (fromRow != null) {
          databaseController.moveGroupRow(
            fromRow: fromRow,
            toRow: toRow,
            groupId: groupId,
          );
        }
      },
      onMoveGroupItemToGroup: (
        fromGroupId,
        fromIndex,
        toGroupId,
        toIndex,
      ) {
        final fromRow = groupControllers[fromGroupId]?.rowAtIndex(fromIndex);
        final toRow = groupControllers[toGroupId]?.rowAtIndex(toIndex);
        if (fromRow != null) {
          databaseController.moveGroupRow(
            fromRow: fromRow,
            toRow: toRow,
            groupId: toGroupId,
          );
        }
      },
    );

    on<BoardEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _startListening();
            await _openGrid(emit);
          },
          createBottomRow: (groupId) async {
            final startRowId = groupControllers[groupId]?.lastRow()?.id;
            final result = await databaseController.createRow(
              groupId: groupId,
              startRowId: startRowId,
            );
            result.fold(
              (_) {},
              (err) => Log.error(err),
            );
          },
          createHeaderRow: (String groupId) async {
            final result = await databaseController.createRow(groupId: groupId);
            result.fold(
              (_) {},
              (err) => Log.error(err),
            );
          },
          didCreateRow: (group, row, int? index) {
            emit(
              state.copyWith(
                editingRow: Some(
                  BoardEditingRow(
                    group: group,
                    row: row,
                    index: index,
                  ),
                ),
              ),
            );
            _groupItemStartEditing(group, row, true);
          },
          startEditingRow: (group, row) {
            emit(
              state.copyWith(
                editingRow: Some(
                  BoardEditingRow(
                    group: group,
                    row: row,
                    index: null,
                  ),
                ),
              ),
            );
            _groupItemStartEditing(group, row, true);
          },
          endEditingRow: (rowId) {
            state.editingRow.fold(() => null, (editingRow) {
              assert(editingRow.row.id == rowId);
              _groupItemStartEditing(editingRow.group, editingRow.row, false);
              emit(state.copyWith(editingRow: none()));
            });
          },
          didReceiveGridUpdate: (DatabasePB grid) {
            emit(state.copyWith(grid: Some(grid)));
          },
          didReceiveError: (FlowyError error) {
            emit(state.copyWith(noneOrError: some(error)));
          },
          didReceiveGroups: (List<GroupPB> groups) {
            emit(
              state.copyWith(
                groupIds: groups.map((group) => group.groupId).toList(),
              ),
            );
          },
        );
      },
    );
  }

  void _groupItemStartEditing(GroupPB group, RowPB row, bool isEdit) {
    final fieldInfo = fieldController.getField(group.fieldId);
    if (fieldInfo == null) {
      Log.warn("fieldInfo should not be null");
      return;
    }

    boardController.enableGroupDragging(!isEdit);
  }

  @override
  Future<void> close() async {
    await databaseController.dispose();
    for (final controller in groupControllers.values) {
      controller.dispose();
    }
    return super.close();
  }

  void initializeGroups(List<GroupPB> groups) {
    for (final controller in groupControllers.values) {
      controller.dispose();
    }
    groupControllers.clear();
    boardController.clear();

    boardController.addGroups(
      groups
          .where((group) => fieldController.getField(group.fieldId) != null)
          .map((group) => initializeGroupData(group))
          .toList(),
    );

    for (final group in groups) {
      final controller = initializeGroupController(group);
      groupControllers[controller.group.groupId] = (controller);
    }
  }

  RowCache? getRowCache() {
    return databaseController.rowCache;
  }

  void _startListening() {
    final onDatabaseChanged = DatabaseCallbacks(
      onDatabaseChanged: (database) {
        if (!isClosed) {
          add(BoardEvent.didReceiveGridUpdate(database));
        }
      },
    );
    final onGroupChanged = GroupCallbacks(
      onGroupByField: (groups) {
        if (isClosed) return;
        initializeGroups(groups);
        add(BoardEvent.didReceiveGroups(groups));
      },
      onDeleteGroup: (groupIds) {
        if (isClosed) return;
        boardController.removeGroups(groupIds);
      },
      onInsertGroup: (insertGroups) {
        if (isClosed) return;
        final group = insertGroups.group;
        final newGroup = initializeGroupData(group);
        final controller = initializeGroupController(group);
        groupControllers[controller.group.groupId] = (controller);
        boardController.addGroup(newGroup);
      },
      onUpdateGroup: (updatedGroups) {
        if (isClosed) return;
        for (final group in updatedGroups) {
          final columnController =
              boardController.getGroupController(group.groupId);
          columnController?.updateGroupName(group.desc);
        }
      },
    );

    databaseController.setListener(
      onDatabaseChanged: onDatabaseChanged,
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
      (grid) => emit(
        state.copyWith(loadingState: GridLoadingState.finish(left(unit))),
      ),
      (err) => emit(
        state.copyWith(loadingState: GridLoadingState.finish(right(err))),
      ),
    );
  }

  GroupController initializeGroupController(GroupPB group) {
    final delegate = GroupControllerDelegateImpl(
      controller: boardController,
      fieldController: fieldController,
      onNewColumnItem: (groupId, row, index) {
        add(BoardEvent.didCreateRow(group, row, index));
      },
    );
    final controller = GroupController(
      viewId: state.viewId,
      group: group,
      delegate: delegate,
    );
    controller.startListening();
    return controller;
  }

  AppFlowyGroupData initializeGroupData(GroupPB group) {
    return AppFlowyGroupData(
      id: group.groupId,
      name: group.desc,
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
  const factory BoardEvent.createBottomRow(String groupId) = _CreateBottomRow;
  const factory BoardEvent.createHeaderRow(String groupId) = _CreateHeaderRow;
  const factory BoardEvent.didCreateRow(
    GroupPB group,
    RowPB row,
    int? index,
  ) = _DidCreateRow;
  const factory BoardEvent.startEditingRow(
    GroupPB group,
    RowPB row,
  ) = _StartEditRow;
  const factory BoardEvent.endEditingRow(RowId rowId) = _EndEditRow;
  const factory BoardEvent.didReceiveError(FlowyError error) = _DidReceiveError;
  const factory BoardEvent.didReceiveGridUpdate(
    DatabasePB grid,
  ) = _DidReceiveGridUpdate;
  const factory BoardEvent.didReceiveGroups(List<GroupPB> groups) =
      _DidReceiveGroups;
}

@freezed
class BoardState with _$BoardState {
  const factory BoardState({
    required String viewId,
    required Option<DatabasePB> grid,
    required List<String> groupIds,
    required Option<BoardEditingRow> editingRow,
    required GridLoadingState loadingState,
    required Option<FlowyError> noneOrError,
  }) = _BoardState;

  factory BoardState.initial(String viewId) => BoardState(
        grid: none(),
        viewId: viewId,
        groupIds: [],
        editingRow: none(),
        noneOrError: none(),
        loadingState: const _Loading(),
      );
}

@freezed
class GridLoadingState with _$GridLoadingState {
  const factory GridLoadingState.loading() = _Loading;
  const factory GridLoadingState.finish(
    Either<Unit, FlowyError> successOrFail,
  ) = _Finish;
}

class GridFieldEquatable extends Equatable {
  final UnmodifiableListView<FieldPB> _fields;
  const GridFieldEquatable(
    UnmodifiableListView<FieldPB> fields,
  ) : _fields = fields;

  @override
  List<Object?> get props {
    if (_fields.isEmpty) {
      return [];
    }

    return [
      _fields.length,
      _fields
          .map((field) => field.width)
          .reduce((value, element) => value + element),
    ];
  }

  UnmodifiableListView<FieldPB> get value => UnmodifiableListView(_fields);
}

class GroupItem extends AppFlowyGroupItem {
  final RowPB row;
  final FieldInfo fieldInfo;

  GroupItem({
    required this.row,
    required this.fieldInfo,
    bool draggable = true,
  }) {
    super.draggable = draggable;
  }

  @override
  String get id => row.id.toString();
}

class GroupControllerDelegateImpl extends GroupControllerDelegate {
  final FieldController fieldController;
  final AppFlowyBoardController controller;
  final void Function(String, RowPB, int?) onNewColumnItem;

  GroupControllerDelegateImpl({
    required this.controller,
    required this.fieldController,
    required this.onNewColumnItem,
  });

  @override
  void insertRow(GroupPB group, RowPB row, int? index) {
    final fieldInfo = fieldController.getField(group.fieldId);
    if (fieldInfo == null) {
      Log.warn("fieldInfo should not be null");
      return;
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
  void removeRow(GroupPB group, RowId rowId) {
    controller.removeGroupItem(group.groupId, rowId.toString());
  }

  @override
  void updateRow(GroupPB group, RowPB row) {
    final fieldInfo = fieldController.getField(group.fieldId);
    if (fieldInfo == null) {
      Log.warn("fieldInfo should not be null");
      return;
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
  void addNewRow(GroupPB group, RowPB row, int? index) {
    final fieldInfo = fieldController.getField(group.fieldId);
    if (fieldInfo == null) {
      Log.warn("fieldInfo should not be null");
      return;
    }
    final item = GroupItem(
      row: row,
      fieldInfo: fieldInfo,
      draggable: false,
    );

    if (index != null) {
      controller.insertGroupItem(group.groupId, index, item);
    } else {
      controller.addGroupItem(group.groupId, item);
    }
    onNewColumnItem(group.groupId, row, index);
  }
}

class BoardEditingRow {
  GroupPB group;
  RowPB row;
  int? index;

  BoardEditingRow({
    required this.group,
    required this.row,
    required this.index,
  });
}

class GroupData {
  final GroupPB group;
  final FieldInfo fieldInfo;
  GroupData({
    required this.group,
    required this.fieldInfo,
  });

  CheckboxGroup? asCheckboxGroup() {
    if (fieldType != FieldType.Checkbox) return null;
    return CheckboxGroup(group);
  }

  FieldType get fieldType => fieldInfo.fieldType;
}

class CheckboxGroup {
  final GroupPB group;

  CheckboxGroup(this.group);

// Hardcode value: "Yes" that equal to the value defined in Rust
// pub const CHECK: &str = "Yes";
  bool get isCheck => group.groupId == "Yes";
}
