import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'grid_service.dart';
import 'row/row_service.dart';

part 'grid_bloc.freezed.dart';

class GridBloc extends Bloc<GridEvent, GridState> {
  final GridService _gridService;
  final GridFieldCache fieldCache;
  final GridRowCache rowCache;

  GridBloc({required View view})
      : _gridService = GridService(gridId: view.id),
        fieldCache = GridFieldCache(gridId: view.id),
        rowCache = GridRowCache(gridId: view.id),
        super(GridState.initial(view.id)) {
    on<GridEvent>(
      (event, emit) async {
        await event.map(
          initial: (InitialGrid value) async {
            _startListening();
            await _loadGrid(emit);
          },
          createRow: (_CreateRow value) {
            _gridService.createRow();
          },
          didReceiveRowUpdate: (_DidReceiveRowUpdate value) {
            emit(state.copyWith(rows: value.rows, listState: value.listState));
          },
          didReceiveFieldUpdate: (_DidReceiveFieldUpdate value) {
            emit(state.copyWith(rows: rowCache.clonedRows, fields: value.fields));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await _gridService.closeGrid();
    await fieldCache.dispose();
    await rowCache.dispose();
    return super.close();
  }

  void _startListening() {
    fieldCache.addListener(
      onChanged: (fields) => add(GridEvent.didReceiveFieldUpdate(fields)),
      listenWhen: () => !isClosed,
    );

    rowCache.addListener(
      onChanged: (rows, listState) => add(GridEvent.didReceiveRowUpdate(rowCache.clonedRows, listState)),
      listenWhen: () => !isClosed,
    );
  }

  Future<void> _loadGrid(Emitter<GridState> emit) async {
    final result = await _gridService.loadGrid();
    return Future(
      () => result.fold(
        (grid) async => await _loadFields(grid, emit),
        (err) => emit(state.copyWith(loadingState: GridLoadingState.finish(right(err)))),
      ),
    );
  }

  Future<void> _loadFields(Grid grid, Emitter<GridState> emit) async {
    final result = await _gridService.getFields(fieldOrders: grid.fieldOrders);
    return Future(
      () => result.fold(
        (fields) {
          fieldCache.fields = fields.items;
          rowCache.updateWithBlock(grid.blockOrders, fieldCache.unmodifiableFields);

          emit(state.copyWith(
            grid: Some(grid),
            fields: fieldCache.clonedFields,
            rows: rowCache.clonedRows,
            loadingState: GridLoadingState.finish(left(unit)),
          ));
        },
        (err) => emit(state.copyWith(loadingState: GridLoadingState.finish(right(err)))),
      ),
    );
  }
}

@freezed
class GridEvent with _$GridEvent {
  const factory GridEvent.initial() = InitialGrid;
  const factory GridEvent.createRow() = _CreateRow;
  const factory GridEvent.didReceiveRowUpdate(List<GridRow> rows, GridRowChangeReason listState) = _DidReceiveRowUpdate;
  const factory GridEvent.didReceiveFieldUpdate(List<Field> fields) = _DidReceiveFieldUpdate;
}

@freezed
class GridState with _$GridState {
  const factory GridState({
    required String gridId,
    required Option<Grid> grid,
    required List<Field> fields,
    required List<GridRow> rows,
    required GridLoadingState loadingState,
    required GridRowChangeReason listState,
  }) = _GridState;

  factory GridState.initial(String gridId) => GridState(
        fields: [],
        rows: [],
        grid: none(),
        gridId: gridId,
        loadingState: const _Loading(),
        listState: const InitialListState(),
      );
}

@freezed
class GridLoadingState with _$GridLoadingState {
  const factory GridLoadingState.loading() = _Loading;
  const factory GridLoadingState.finish(Either<Unit, FlowyError> successOrFail) = _Finish;
}
