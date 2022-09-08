import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'block/block_cache.dart';
import 'field/field_controller.dart';
import 'grid_data_controller.dart';
import 'row/row_cache.dart';
import 'dart:collection';

part 'grid_bloc.freezed.dart';

class GridBloc extends Bloc<GridEvent, GridState> {
  final GridDataController dataController;

  GridBloc({required ViewPB view})
      : dataController = GridDataController(view: view),
        super(GridState.initial(view.id)) {
    on<GridEvent>(
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
              rowCount: newRowInfos.length,
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
          add(GridEvent.didReceiveGridUpdate(grid));
        }
      },
      onRowsChanged: (rowInfos, reason) {
        if (!isClosed) {
          add(GridEvent.didReceiveRowUpdate(rowInfos, reason));
        }
      },
      onFieldsChanged: (fields) {
        if (!isClosed) {
          add(GridEvent.didReceiveFieldUpdate(fields));
        }
      },
    );
  }

  Future<void> _loadGrid(Emitter<GridState> emit) async {
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
class GridEvent with _$GridEvent {
  const factory GridEvent.initial() = InitialGrid;
  const factory GridEvent.createRow() = _CreateRow;
  const factory GridEvent.didReceiveRowUpdate(
    List<RowInfo> rows,
    RowsChangedReason listState,
  ) = _DidReceiveRowUpdate;
  const factory GridEvent.didReceiveFieldUpdate(
    UnmodifiableListView<GridFieldContext> fields,
  ) = _DidReceiveFieldUpdate;

  const factory GridEvent.didReceiveGridUpdate(
    GridPB grid,
  ) = _DidReceiveGridUpdate;
}

@freezed
class GridState with _$GridState {
  const factory GridState({
    required String gridId,
    required Option<GridPB> grid,
    required GridFieldEquatable fields,
    required List<RowInfo> rowInfos,
    required int rowCount,
    required GridLoadingState loadingState,
    required RowsChangedReason reason,
  }) = _GridState;

  factory GridState.initial(String gridId) => GridState(
        fields: GridFieldEquatable(UnmodifiableListView([])),
        rowInfos: [],
        rowCount: 0,
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
  final UnmodifiableListView<GridFieldContext> _fields;
  const GridFieldEquatable(
    UnmodifiableListView<GridFieldContext> fields,
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

  UnmodifiableListView<GridFieldContext> get value =>
      UnmodifiableListView(_fields);
}
