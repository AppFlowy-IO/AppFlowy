import 'dart:async';
import 'package:app_flowy/plugins/grid/application/block/block_cache.dart';
import 'package:app_flowy/plugins/grid/application/grid_data_controller.dart';
import 'package:app_flowy/plugins/grid/application/row/row_cache.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:collection';

part 'board_bloc.freezed.dart';

class BoardBloc extends Bloc<BoardEvent, BoardState> {
  final GridDataController dataController;

  BoardBloc({required ViewPB view})
      : dataController = GridDataController(view: view),
        super(BoardState.initial(view.id)) {
    on<BoardEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _startListening();
            await _loadGrid(emit);
          },
          createRow: () {
            dataController.createRow();
          },
          didReceiveGridUpdate: (grid) {
            emit(state.copyWith(grid: Some(grid)));
          },
          didReceiveFieldUpdate: (fields) {
            emit(state.copyWith(
              fields: GridFieldEquatable(fields),
            ));
          },
          didReceiveRowUpdate: (newRowInfos, reason) {
            emit(state.copyWith(
              rowInfos: newRowInfos,
              reason: reason,
            ));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await dataController.dispose();
    return super.close();
  }

  GridRowCache? getRowCache(String blockId, String rowId) {
    final GridBlockCache? blockCache = dataController.blocks[blockId];
    return blockCache?.rowCache;
  }

  void _startListening() {
    dataController.addListener(
      onGridChanged: (grid) {
        if (!isClosed) {
          add(BoardEvent.didReceiveGridUpdate(grid));
        }
      },
      onRowsChanged: (rowInfos, reason) {
        if (!isClosed) {
          add(BoardEvent.didReceiveRowUpdate(rowInfos, reason));
        }
      },
      onFieldsChanged: (fields) {
        if (!isClosed) {
          add(BoardEvent.didReceiveFieldUpdate(fields));
        }
      },
    );
  }

  Future<void> _loadGrid(Emitter<BoardState> emit) async {
    final result = await dataController.loadData();
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
  const factory BoardEvent.didReceiveRowUpdate(
    List<GridRowInfo> rows,
    GridRowChangeReason listState,
  ) = _DidReceiveRowUpdate;
  const factory BoardEvent.didReceiveFieldUpdate(
    UnmodifiableListView<GridFieldPB> fields,
  ) = _DidReceiveFieldUpdate;

  const factory BoardEvent.didReceiveGridUpdate(
    GridPB grid,
  ) = _DidReceiveGridUpdate;
}

@freezed
class BoardState with _$BoardState {
  const factory BoardState({
    required String gridId,
    required Option<GridPB> grid,
    required GridFieldEquatable fields,
    required List<GridRowInfo> rowInfos,
    required GridLoadingState loadingState,
    required GridRowChangeReason reason,
  }) = _BoardState;

  factory BoardState.initial(String gridId) => BoardState(
        fields: GridFieldEquatable(UnmodifiableListView([])),
        rowInfos: [],
        grid: none(),
        gridId: gridId,
        loadingState: const _Loading(),
        reason: const InitialListState(),
      );
}

@freezed
class GridLoadingState with _$GridLoadingState {
  const factory GridLoadingState.loading() = _Loading;
  const factory GridLoadingState.finish(
      Either<Unit, FlowyError> successOrFail) = _Finish;
}

class GridFieldEquatable extends Equatable {
  final UnmodifiableListView<GridFieldPB> _fields;
  const GridFieldEquatable(
    UnmodifiableListView<GridFieldPB> fields,
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

  UnmodifiableListView<GridFieldPB> get value => UnmodifiableListView(_fields);
}
