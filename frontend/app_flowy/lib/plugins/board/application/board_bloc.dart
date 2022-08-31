import 'dart:async';
import 'package:app_flowy/plugins/grid/application/block/block_cache.dart';
import 'package:app_flowy/plugins/grid/application/field/field_cache.dart';
import 'package:app_flowy/plugins/grid/application/row/row_cache.dart';
import 'package:app_flowy/plugins/grid/application/row/row_service.dart';
import 'package:appflowy_board/appflowy_board.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:collection';

import 'board_data_controller.dart';
import 'group_controller.dart';

part 'board_bloc.freezed.dart';

class BoardBloc extends Bloc<BoardEvent, BoardState> {
  final BoardDataController _gridDataController;
  late final AFBoardDataController boardController;
  final MoveRowFFIService _rowService;
  LinkedHashMap<String, GroupController> groupControllers = LinkedHashMap();

  GridFieldCache get fieldCache => _gridDataController.fieldCache;
  String get gridId => _gridDataController.gridId;

  BoardBloc({required ViewPB view})
      : _rowService = MoveRowFFIService(gridId: view.id),
        _gridDataController = BoardDataController(view: view),
        super(BoardState.initial(view.id)) {
    boardController = AFBoardDataController(
      onMoveColumn: (
        fromColumnId,
        fromIndex,
        toColumnId,
        toIndex,
      ) {
        _moveGroup(fromColumnId, toColumnId);
      },
      onMoveColumnItem: (
        columnId,
        fromIndex,
        toIndex,
      ) {
        final fromRow = groupControllers[columnId]?.rowAtIndex(fromIndex);
        final toRow = groupControllers[columnId]?.rowAtIndex(toIndex);
        _moveRow(fromRow, columnId, toRow);
      },
      onMoveColumnItemToColumn: (
        fromColumnId,
        fromIndex,
        toColumnId,
        toIndex,
      ) {
        final fromRow = groupControllers[fromColumnId]?.rowAtIndex(fromIndex);
        final toRow = groupControllers[toColumnId]?.rowAtIndex(toIndex);
        _moveRow(fromRow, toColumnId, toRow);
      },
    );

    on<BoardEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _startListening();
            await _loadGrid(emit);
          },
          createBottomRow: (groupId) async {
            final startRowId = groupControllers[groupId]?.lastRow()?.id;
            final result = await _gridDataController.createBoardCard(
              groupId,
              startRowId: startRowId,
            );
            result.fold(
              (_) {},
              (err) => Log.error(err),
            );
          },
          createHeaderRow: (String groupId) async {
            final result = await _gridDataController.createBoardCard(groupId);
            result.fold(
              (_) {},
              (err) => Log.error(err),
            );
          },
          didCreateRow: (String groupId, RowPB row, int? index) {
            emit(state.copyWith(
              editingRow: Some(BoardEditingRow(
                columnId: groupId,
                row: row,
                index: index,
              )),
            ));
          },
          endEditRow: (rowId) {
            assert(state.editingRow.isSome());
            state.editingRow.fold(() => null, (editingRow) {
              assert(editingRow.row.id == rowId);
              emit(state.copyWith(editingRow: none()));
            });
          },
          didReceiveGridUpdate: (GridPB grid) {
            emit(state.copyWith(grid: Some(grid)));
          },
          didReceiveError: (FlowyError error) {
            emit(state.copyWith(noneOrError: some(error)));
          },
          didReceiveGroups: (List<GroupPB> groups) {
            emit(state.copyWith(
              groupIds: groups.map((group) => group.groupId).toList(),
            ));
          },
        );
      },
    );
  }

  void _moveRow(RowPB? fromRow, String columnId, RowPB? toRow) {
    if (fromRow != null) {
      _rowService
          .moveGroupRow(
        fromRowId: fromRow.id,
        toGroupId: columnId,
        toRowId: toRow?.id,
      )
          .then((result) {
        result.fold((l) => null, (r) => add(BoardEvent.didReceiveError(r)));
      });
    }
  }

  void _moveGroup(String fromColumnId, String toColumnId) {
    _rowService
        .moveGroup(
      fromGroupId: fromColumnId,
      toGroupId: toColumnId,
    )
        .then((result) {
      result.fold((l) => null, (r) => add(BoardEvent.didReceiveError(r)));
    });
  }

  @override
  Future<void> close() async {
    await _gridDataController.dispose();
    for (final controller in groupControllers.values) {
      controller.dispose();
    }
    return super.close();
  }

  void initializeGroups(List<GroupPB> groups) {
    for (final group in groups) {
      final delegate = GroupControllerDelegateImpl(
        controller: boardController,
        onNewColumnItem: (groupId, row, index) {
          add(BoardEvent.didCreateRow(groupId, row, index));
        },
      );
      final controller = GroupController(
        gridId: state.gridId,
        group: group,
        delegate: delegate,
      );
      controller.startListening();
      groupControllers[controller.group.groupId] = (controller);
    }
  }

  GridRowCache? getRowCache(String blockId) {
    final GridBlockCache? blockCache = _gridDataController.blocks[blockId];
    return blockCache?.rowCache;
  }

  void _startListening() {
    _gridDataController.addListener(
      onGridChanged: (grid) {
        if (!isClosed) {
          add(BoardEvent.didReceiveGridUpdate(grid));
        }
      },
      didLoadGroups: (groups) {
        List<AFBoardColumnData> columns = groups.map((group) {
          return AFBoardColumnData(
            id: group.groupId,
            name: group.desc,
            items: _buildRows(group),
            customData: group,
          );
        }).toList();

        boardController.addColumns(columns);
        initializeGroups(groups);
        add(BoardEvent.didReceiveGroups(groups));
      },
      onDeletedGroup: (groupIds) {
        //
      },
      onInsertedGroup: (insertedGroups) {
        //
      },
      onUpdatedGroup: (updatedGroups) {
        //
        for (final group in updatedGroups) {
          final columnController =
              boardController.getColumnController(group.groupId);
          if (columnController != null) {
            columnController.updateColumnName(group.desc);
          }
        }
      },
      onError: (err) {
        Log.error(err);
      },
    );
  }

  List<AFColumnItem> _buildRows(GroupPB group) {
    final items = group.rows.map((row) {
      return BoardColumnItem(
        row: row,
        fieldId: group.fieldId,
      );
    }).toList();

    return <AFColumnItem>[...items];
  }

  Future<void> _loadGrid(Emitter<BoardState> emit) async {
    final result = await _gridDataController.loadData();
    result.fold(
      (grid) => emit(
        state.copyWith(loadingState: GridLoadingState.finish(left(unit))),
      ),
      (err) => emit(
        state.copyWith(loadingState: GridLoadingState.finish(right(err))),
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
    String groupId,
    RowPB row,
    int? index,
  ) = _DidCreateRow;
  const factory BoardEvent.endEditRow(String rowId) = _EndEditRow;
  const factory BoardEvent.didReceiveError(FlowyError error) = _DidReceiveError;
  const factory BoardEvent.didReceiveGridUpdate(
    GridPB grid,
  ) = _DidReceiveGridUpdate;
  const factory BoardEvent.didReceiveGroups(List<GroupPB> groups) =
      _DidReceiveGroups;
}

@freezed
class BoardState with _$BoardState {
  const factory BoardState({
    required String gridId,
    required Option<GridPB> grid,
    required List<String> groupIds,
    required Option<BoardEditingRow> editingRow,
    required GridLoadingState loadingState,
    required Option<FlowyError> noneOrError,
  }) = _BoardState;

  factory BoardState.initial(String gridId) => BoardState(
        grid: none(),
        gridId: gridId,
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
      Either<Unit, FlowyError> successOrFail) = _Finish;
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

class BoardColumnItem extends AFColumnItem {
  final RowPB row;

  final String fieldId;

  final bool requestFocus;

  BoardColumnItem({
    required this.row,
    required this.fieldId,
    this.requestFocus = false,
  });

  @override
  String get id => row.id;
}

class GroupControllerDelegateImpl extends GroupControllerDelegate {
  final AFBoardDataController controller;
  final void Function(String, RowPB, int?) onNewColumnItem;

  GroupControllerDelegateImpl({
    required this.controller,
    required this.onNewColumnItem,
  });

  @override
  void insertRow(GroupPB group, RowPB row, int? index) {
    if (index != null) {
      final item = BoardColumnItem(row: row, fieldId: group.fieldId);
      controller.insertColumnItem(group.groupId, index, item);
    } else {
      final item = BoardColumnItem(
        row: row,
        fieldId: group.fieldId,
      );
      controller.addColumnItem(group.groupId, item);
    }
  }

  @override
  void removeRow(GroupPB group, String rowId) {
    controller.removeColumnItem(group.groupId, rowId);
  }

  @override
  void updateRow(GroupPB group, RowPB row) {
    controller.updateColumnItem(
      group.groupId,
      BoardColumnItem(
        row: row,
        fieldId: group.fieldId,
      ),
    );
  }

  @override
  void addNewRow(GroupPB group, RowPB row, int? index) {
    final item = BoardColumnItem(
      row: row,
      fieldId: group.fieldId,
      requestFocus: true,
    );

    if (index != null) {
      controller.insertColumnItem(group.groupId, index, item);
    } else {
      controller.addColumnItem(group.groupId, item);
    }
    onNewColumnItem(group.groupId, row, index);
  }
}

class BoardEditingRow {
  String columnId;
  RowPB row;
  int? index;

  BoardEditingRow({
    required this.columnId,
    required this.row,
    required this.index,
  });
}
