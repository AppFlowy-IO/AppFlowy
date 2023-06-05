import 'dart:async';
import 'dart:collection';

import 'package:appflowy_board/appflowy_board.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../application/field/field_controller.dart';
import '../../application/row/row_cache.dart';
import '../../application/database_controller.dart';
import 'group_controller.dart';

part 'board_bloc.freezed.dart';

class BoardBloc extends Bloc<BoardEvent, BoardState> {
  final DatabaseController _databaseController;
  late final AppFlowyBoardController boardController;
  final LinkedHashMap<String, GroupController> groupControllers =
      LinkedHashMap();

  FieldController get fieldController => _databaseController.fieldController;
  String get viewId => _databaseController.viewId;

  BoardBloc({required final ViewPB view})
      : _databaseController = DatabaseController(
          view: view,
          layoutType: LayoutTypePB.Board,
        ),
        super(BoardState.initial(view.id)) {
    boardController = AppFlowyBoardController(
      onMoveGroup: (
        final fromGroupId,
        final fromIndex,
        final toGroupId,
        final toIndex,
      ) {
        _databaseController.moveGroup(
          fromGroupId: fromGroupId,
          toGroupId: toGroupId,
        );
      },
      onMoveGroupItem: (
        final groupId,
        final fromIndex,
        final toIndex,
      ) {
        final fromRow = groupControllers[groupId]?.rowAtIndex(fromIndex);
        final toRow = groupControllers[groupId]?.rowAtIndex(toIndex);
        if (fromRow != null) {
          _databaseController.moveRow(
            fromRow: fromRow,
            toRow: toRow,
            groupId: groupId,
          );
        }
      },
      onMoveGroupItemToGroup: (
        final fromGroupId,
        final fromIndex,
        final toGroupId,
        final toIndex,
      ) {
        final fromRow = groupControllers[fromGroupId]?.rowAtIndex(fromIndex);
        final toRow = groupControllers[toGroupId]?.rowAtIndex(toIndex);
        if (fromRow != null) {
          _databaseController.moveRow(
            fromRow: fromRow,
            toRow: toRow,
            groupId: toGroupId,
          );
        }
      },
    );

    on<BoardEvent>(
      (final event, final emit) async {
        await event.when(
          initial: () async {
            _startListening();
            await _openGrid(emit);
          },
          createBottomRow: (final groupId) async {
            final startRowId = groupControllers[groupId]?.lastRow()?.id;
            final result = await _databaseController.createRow(
              groupId: groupId,
              startRowId: startRowId,
            );
            result.fold(
              (final _) {},
              (final err) => Log.error(err),
            );
          },
          createHeaderRow: (final String groupId) async {
            final result =
                await _databaseController.createRow(groupId: groupId);
            result.fold(
              (final _) {},
              (final err) => Log.error(err),
            );
          },
          didCreateRow: (final group, final row, final int? index) {
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
          startEditingRow: (final group, final row) {
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
          endEditingRow: (final rowId) {
            state.editingRow.fold(() => null, (final editingRow) {
              assert(editingRow.row.id == rowId);
              _groupItemStartEditing(editingRow.group, editingRow.row, false);
              emit(state.copyWith(editingRow: none()));
            });
          },
          didReceiveGridUpdate: (final DatabasePB grid) {
            emit(state.copyWith(grid: Some(grid)));
          },
          didReceiveError: (final FlowyError error) {
            emit(state.copyWith(noneOrError: some(error)));
          },
          didReceiveGroups: (final List<GroupPB> groups) {
            emit(
              state.copyWith(
                groupIds: groups.map((final group) => group.groupId).toList(),
              ),
            );
          },
        );
      },
    );
  }

  void _groupItemStartEditing(final GroupPB group, final RowPB row, final bool isEdit) {
    final fieldInfo = fieldController.getField(group.fieldId);
    if (fieldInfo == null) {
      Log.warn("fieldInfo should not be null");
      return;
    }

    boardController.enableGroupDragging(!isEdit);
  }

  @override
  Future<void> close() async {
    await _databaseController.dispose();
    for (final controller in groupControllers.values) {
      controller.dispose();
    }
    return super.close();
  }

  void initializeGroups(final List<GroupPB> groups) {
    for (final controller in groupControllers.values) {
      controller.dispose();
    }
    groupControllers.clear();
    boardController.clear();

    boardController.addGroups(
      groups
          .where((final group) => fieldController.getField(group.fieldId) != null)
          .map((final group) => initializeGroupData(group))
          .toList(),
    );

    for (final group in groups) {
      final controller = initializeGroupController(group);
      groupControllers[controller.group.groupId] = (controller);
    }
  }

  RowCache? getRowCache(final String blockId) {
    return _databaseController.rowCache;
  }

  void _startListening() {
    final onDatabaseChanged = DatabaseCallbacks(
      onDatabaseChanged: (final database) {
        if (!isClosed) {
          add(BoardEvent.didReceiveGridUpdate(database));
        }
      },
    );
    final onGroupChanged = GroupCallbacks(
      onGroupByField: (final groups) {
        if (isClosed) return;
        initializeGroups(groups);
        add(BoardEvent.didReceiveGroups(groups));
      },
      onDeleteGroup: (final groupIds) {
        if (isClosed) return;
        boardController.removeGroups(groupIds);
      },
      onInsertGroup: (final insertGroups) {
        if (isClosed) return;
        final group = insertGroups.group;
        final newGroup = initializeGroupData(group);
        final controller = initializeGroupController(group);
        groupControllers[controller.group.groupId] = (controller);
        boardController.addGroup(newGroup);
      },
      onUpdateGroup: (final updatedGroups) {
        if (isClosed) return;
        for (final group in updatedGroups) {
          final columnController =
              boardController.getGroupController(group.groupId);
          columnController?.updateGroupName(group.desc);
        }
      },
    );

    _databaseController.setListener(
      onDatabaseChanged: onDatabaseChanged,
      onGroupChanged: onGroupChanged,
    );
  }

  List<AppFlowyGroupItem> _buildGroupItems(final GroupPB group) {
    final items = group.rows.map((final row) {
      final fieldInfo = fieldController.getField(group.fieldId);
      return GroupItem(
        row: row,
        fieldInfo: fieldInfo!,
      );
    }).toList();

    return <AppFlowyGroupItem>[...items];
  }

  Future<void> _openGrid(final Emitter<BoardState> emit) async {
    final result = await _databaseController.open();
    result.fold(
      (final grid) => emit(
        state.copyWith(loadingState: GridLoadingState.finish(left(unit))),
      ),
      (final err) => emit(
        state.copyWith(loadingState: GridLoadingState.finish(right(err))),
      ),
    );
  }

  GroupController initializeGroupController(final GroupPB group) {
    final delegate = GroupControllerDelegateImpl(
      controller: boardController,
      fieldController: fieldController,
      onNewColumnItem: (final groupId, final row, final index) {
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

  AppFlowyGroupData initializeGroupData(final GroupPB group) {
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
  const factory BoardEvent.createBottomRow(final String groupId) = _CreateBottomRow;
  const factory BoardEvent.createHeaderRow(final String groupId) = _CreateHeaderRow;
  const factory BoardEvent.didCreateRow(
    final GroupPB group,
    final RowPB row,
    final int? index,
  ) = _DidCreateRow;
  const factory BoardEvent.startEditingRow(
    final GroupPB group,
    final RowPB row,
  ) = _StartEditRow;
  const factory BoardEvent.endEditingRow(final String rowId) = _EndEditRow;
  const factory BoardEvent.didReceiveError(final FlowyError error) = _DidReceiveError;
  const factory BoardEvent.didReceiveGridUpdate(
    final DatabasePB grid,
  ) = _DidReceiveGridUpdate;
  const factory BoardEvent.didReceiveGroups(final List<GroupPB> groups) =
      _DidReceiveGroups;
}

@freezed
class BoardState with _$BoardState {
  const factory BoardState({
    required final String viewId,
    required final Option<DatabasePB> grid,
    required final List<String> groupIds,
    required final Option<BoardEditingRow> editingRow,
    required final GridLoadingState loadingState,
    required final Option<FlowyError> noneOrError,
  }) = _BoardState;

  factory BoardState.initial(final String viewId) => BoardState(
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
    final Either<Unit, FlowyError> successOrFail,
  ) = _Finish;
}

class GridFieldEquatable extends Equatable {
  final UnmodifiableListView<FieldPB> _fields;
  const GridFieldEquatable(
    final UnmodifiableListView<FieldPB> fields,
  ) : _fields = fields;

  @override
  List<Object?> get props {
    if (_fields.isEmpty) {
      return [];
    }

    return [
      _fields.length,
      _fields
          .map((final field) => field.width)
          .reduce((final value, final element) => value + element),
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
    final bool draggable = true,
  }) {
    super.draggable = draggable;
  }

  @override
  String get id => row.id;
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
  void insertRow(final GroupPB group, final RowPB row, final int? index) {
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
  void removeRow(final GroupPB group, final String rowId) {
    controller.removeGroupItem(group.groupId, rowId);
  }

  @override
  void updateRow(final GroupPB group, final RowPB row) {
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
  void addNewRow(final GroupPB group, final RowPB row, final int? index) {
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
