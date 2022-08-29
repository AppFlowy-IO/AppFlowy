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
  LinkedHashMap<String, GroupController> groupControllers = LinkedHashMap.new();

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
          createRow: (groupId) async {
            final result = await _gridDataController.createBoardCard(groupId);
            result.fold(
              (rowPB) {
                emit(state.copyWith(editingRow: some(rowPB)));
              },
              (err) => Log.error(err),
            );
          },
          endEditRow: (rowId) {
            assert(state.editingRow.isSome());
            state.editingRow.fold(() => null, (row) {
              assert(row.id == rowId);
              emit(state.copyWith(editingRow: none()));
            });
          },
          didReceiveGridUpdate: (GridPB grid) {
            emit(state.copyWith(grid: Some(grid)));
          },
          didReceiveRows: (List<RowInfo> rowInfos) {
            emit(state.copyWith(rowInfos: rowInfos));
          },
          didReceiveError: (FlowyError error) {
            emit(state.copyWith(noneOrError: some(error)));
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
      final delegate = GroupControllerDelegateImpl(boardController);
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
            items: _buildRows(group.rows),
            customData: group,
          );
        }).toList();

        boardController.addColumns(columns);
        initializeGroups(groups);
      },
      onRowsChanged: (List<RowInfo> rowInfos, RowsChangedReason reason) {
        add(BoardEvent.didReceiveRows(rowInfos));
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

  List<AFColumnItem> _buildRows(List<RowPB> rows) {
    final items = rows.map((row) {
      return BoardColumnItem(row: row);
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
  const factory BoardEvent.initial() = InitialGrid;
  const factory BoardEvent.createRow(String groupId) = _CreateRow;
  const factory BoardEvent.endEditRow(String rowId) = _EndEditRow;
  const factory BoardEvent.didReceiveError(FlowyError error) = _DidReceiveError;
  const factory BoardEvent.didReceiveRows(List<RowInfo> rowInfos) =
      _DidReceiveRows;
  const factory BoardEvent.didReceiveGridUpdate(
    GridPB grid,
  ) = _DidReceiveGridUpdate;
}

@freezed
class BoardState with _$BoardState {
  const factory BoardState({
    required String gridId,
    required Option<GridPB> grid,
    required Option<RowPB> editingRow,
    required List<RowInfo> rowInfos,
    required GridLoadingState loadingState,
    required Option<FlowyError> noneOrError,
  }) = _BoardState;

  factory BoardState.initial(String gridId) => BoardState(
        rowInfos: [],
        grid: none(),
        gridId: gridId,
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

  BoardColumnItem({required this.row});

  @override
  String get id => row.id;
}

class CreateCardItem extends AFColumnItem {
  @override
  String get id => '$CreateCardItem';
}

class GroupControllerDelegateImpl extends GroupControllerDelegate {
  final AFBoardDataController controller;

  GroupControllerDelegateImpl(this.controller);

  @override
  void insertRow(String groupId, RowPB row, int? index) {
    final item = BoardColumnItem(row: row);
    if (index != null) {
      controller.insertColumnItem(groupId, index, item);
    } else {
      controller.addColumnItem(groupId, item);
    }
  }

  @override
  void removeRow(String groupId, String rowId) {
    controller.removeColumnItem(groupId, rowId);
  }

  @override
  void updateRow(String groupId, RowPB row) {
    controller.updateColumnItem(groupId, BoardColumnItem(row: row));
  }
}
