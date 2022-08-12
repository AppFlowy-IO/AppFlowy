import 'dart:async';
import 'package:app_flowy/plugins/grid/application/block/block_cache.dart';
import 'package:app_flowy/plugins/grid/application/field/field_cache.dart';
import 'package:app_flowy/plugins/grid/application/row/row_cache.dart';
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

part 'board_bloc.freezed.dart';

class BoardBloc extends Bloc<BoardEvent, BoardState> {
  final BoardDataController _dataController;
  late final AFBoardDataController boardDataController;

  GridFieldCache get fieldCache => _dataController.fieldCache;
  String get gridId => _dataController.gridId;

  BoardBloc({required ViewPB view})
      : _dataController = BoardDataController(view: view),
        super(BoardState.initial(view.id)) {
    boardDataController = AFBoardDataController(
      onMoveColumn: (
        fromIndex,
        toIndex,
      ) {},
      onMoveColumnItem: (
        columnId,
        fromIndex,
        toIndex,
      ) {},
      onMoveColumnItemToColumn: (
        fromColumnId,
        fromIndex,
        toColumnId,
        toIndex,
      ) {},
    );

    on<BoardEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _startListening();
            await _loadGrid(emit);
          },
          createRow: () {
            _dataController.createRow();
          },
          didReceiveGridUpdate: (GridPB grid) {
            emit(state.copyWith(grid: Some(grid)));
          },
          didReceiveGroups: (List<GroupPB> groups) {
            emit(state.copyWith(groups: groups));
          },
          didReceiveRows: (List<RowInfo> rowInfos) {
            emit(state.copyWith(rowInfos: rowInfos));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await _dataController.dispose();
    return super.close();
  }

  GridRowCache? getRowCache(String blockId) {
    final GridBlockCache? blockCache = _dataController.blocks[blockId];
    return blockCache?.rowCache;
  }

  void _startListening() {
    _dataController.addListener(
      onGridChanged: (grid) {
        if (!isClosed) {
          add(BoardEvent.didReceiveGridUpdate(grid));
        }
      },
      onGroupChanged: (groups) {
        List<AFBoardColumnData> columns = groups.map((group) {
          return AFBoardColumnData(
            id: group.groupId,
            desc: group.desc,
            items: _buildRows(group.rows),
            customData: group,
          );
        }).toList();

        boardDataController.addColumns(columns);
      },
      onRowsChanged: (List<RowInfo> rowInfos, RowChangeReason reason) {
        add(BoardEvent.didReceiveRows(rowInfos));
      },
      onError: (err) {
        Log.error(err);
      },
    );
  }

  List<BoardColumnItem> _buildRows(List<RowPB> rows) {
    return rows.map((row) {
      // final rowInfo = RowInfo(
      //   gridId: _dataController.gridId,
      //   blockId: row.blockId,
      //   id: row.id,
      //   fields: _dataController.fieldCache.unmodifiableFields,
      //   height: row.height.toDouble(),
      //   rawRow: row,
      // );
      return BoardColumnItem(row: row);
    }).toList();
  }

  Future<void> _loadGrid(Emitter<BoardState> emit) async {
    final result = await _dataController.loadData();
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
  const factory BoardEvent.createRow() = _CreateRow;
  const factory BoardEvent.didReceiveGroups(List<GroupPB> groups) =
      _DidReceiveGroup;
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
    required List<GroupPB> groups,
    required List<RowInfo> rowInfos,
    required GridLoadingState loadingState,
  }) = _BoardState;

  factory BoardState.initial(String gridId) => BoardState(
        rowInfos: [],
        groups: [],
        grid: none(),
        gridId: gridId,
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
