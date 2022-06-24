import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'block/block_listener.dart';
import 'cell/cell_service/cell_service.dart';
import 'grid_service.dart';
import 'row/row_service.dart';
import 'dart:collection';

part 'grid_bloc.freezed.dart';

class GridBloc extends Bloc<GridEvent, GridState> {
  final GridService _gridService;
  final GridFieldCache fieldCache;
  late final GridRowCache rowCache;
  late final GridCellCache cellCache;

  final GridBlockCache blockCache;

  GridBloc({required View view})
      : _gridService = GridService(gridId: view.id),
        fieldCache = GridFieldCache(gridId: view.id),
        blockCache = GridBlockCache(gridId: view.id),
        super(GridState.initial(view.id)) {
    rowCache = GridRowCache(
      gridId: view.id,
      fieldDelegate: GridRowCacheDelegateImpl(fieldCache),
    );

    cellCache = GridCellCache(
      gridId: view.id,
      fieldDelegate: GridCellCacheDelegateImpl(fieldCache),
    );

    blockCache.start((result) {
      result.fold(
        (changesets) => rowCache.applyChangesets(changesets),
        (err) => Log.error(err),
      );
    });

    on<GridEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _startListening();
            await _loadGrid(emit);
          },
          createRow: () {
            _gridService.createRow();
          },
          didReceiveRowUpdate: (rows, listState) {
            emit(state.copyWith(rows: rows, listState: listState));
          },
          didReceiveFieldUpdate: (fields) {
            emit(state.copyWith(rows: rowCache.clonedRows, fields: GridFieldEquatable(fields)));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await _gridService.closeGrid();
    await cellCache.dispose();
    await rowCache.dispose();
    await fieldCache.dispose();
    await blockCache.dispose();
    return super.close();
  }

  void _startListening() {
    fieldCache.addListener(
      listenWhen: () => !isClosed,
      onChanged: (fields) => add(GridEvent.didReceiveFieldUpdate(fields)),
    );

    rowCache.addListener(
      listenWhen: () => !isClosed,
      onChanged: (rows, listState) => add(GridEvent.didReceiveRowUpdate(rowCache.clonedRows, listState)),
    );
  }

  Future<void> _loadGrid(Emitter<GridState> emit) async {
    final result = await _gridService.loadGrid();
    return Future(
      () => result.fold(
        (grid) async {
          for (final block in grid.blocks) {
            blockCache.addBlockListener(block.id);
          }
          final rowOrders = grid.blocks.expand((block) => block.rowOrders).toList();
          rowCache.initialRows(rowOrders);

          await _loadFields(grid, emit);
        },
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

          emit(state.copyWith(
            grid: Some(grid),
            fields: GridFieldEquatable(fieldCache.fields),
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
    required GridFieldEquatable fields,
    required List<GridRow> rows,
    required GridLoadingState loadingState,
    required GridRowChangeReason listState,
  }) = _GridState;

  factory GridState.initial(String gridId) => GridState(
        fields: const GridFieldEquatable([]),
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

class GridFieldEquatable extends Equatable {
  final List<Field> _fields;
  const GridFieldEquatable(List<Field> fields) : _fields = fields;

  @override
  List<Object?> get props {
    return [
      _fields.length,
      _fields.map((field) => field.width).reduce((value, element) => value + element),
    ];
  }

  UnmodifiableListView<Field> get value => UnmodifiableListView(_fields);
}
