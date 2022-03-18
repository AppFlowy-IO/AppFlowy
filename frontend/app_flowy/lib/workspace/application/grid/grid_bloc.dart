import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'grid_block_service.dart';
import 'grid_listenr.dart';
import 'grid_service.dart';

part 'grid_bloc.freezed.dart';

class GridBloc extends Bloc<GridEvent, GridState> {
  final View view;
  final GridService service;
  late GridListener _gridListener;
  late GridBlockService _blockService;

  GridBloc({required this.view, required this.service}) : super(GridState.initial()) {
    _gridListener = GridListener();

    on<GridEvent>(
      (event, emit) async {
        await event.map(
          initial: (InitialGrid value) async {
            await _loadGrid(emit);
          },
          createRow: (_CreateRow value) {
            service.createRow(gridId: view.id);
          },
          delete: (_Delete value) {},
          rename: (_Rename value) {},
          updateDesc: (_Desc value) {},
          didLoadRows: (_DidLoadRows value) {
            emit(state.copyWith(rows: value.rows));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await _gridListener.stop();
    await _blockService.stop();
    return super.close();
  }

  Future<void> _startGridListening() async {
    _blockService.didLoadRowscallback = (rows) {
      add(GridEvent.didLoadRows(rows));
    };

    _gridListener.start();
  }

  Future<void> _loadGrid(Emitter<GridState> emit) async {
    final result = await service.openGrid(gridId: view.id);

    return Future(
      () => result.fold(
        (grid) async => await _loadFields(grid, emit),
        (err) => emit(state.copyWith(loadingState: GridLoadingState.finish(right(err)))),
      ),
    );
  }

  Future<void> _loadFields(Grid grid, Emitter<GridState> emit) async {
    final result = await service.getFields(gridId: grid.id, fieldOrders: grid.fieldOrders);
    return Future(
      () => result.fold(
        (fields) => _loadGridBlocks(grid, fields.items, emit),
        (err) => emit(state.copyWith(loadingState: GridLoadingState.finish(right(err)))),
      ),
    );
  }

  Future<void> _loadGridBlocks(Grid grid, List<Field> fields, Emitter<GridState> emit) async {
    final result = await service.getGridBlocks(gridId: grid.id, blockOrders: grid.blockOrders);
    result.fold(
      (repeatedGridBlock) {
        final gridBlocks = repeatedGridBlock.items;
        final gridId = view.id;
        _blockService = GridBlockService(
          gridId: gridId,
          fields: fields,
          gridBlocks: gridBlocks,
        );
        final rows = _blockService.rows();

        _startGridListening();
        emit(state.copyWith(
          grid: Some(grid),
          fields: Some(fields),
          rows: rows,
          loadingState: GridLoadingState.finish(left(unit)),
        ));
      },
      (err) => emit(state.copyWith(loadingState: GridLoadingState.finish(right(err)), rows: [])),
    );
  }
}

@freezed
abstract class GridEvent with _$GridEvent {
  const factory GridEvent.initial() = InitialGrid;
  const factory GridEvent.rename(String gridId, String name) = _Rename;
  const factory GridEvent.updateDesc(String gridId, String desc) = _Desc;
  const factory GridEvent.delete(String gridId) = _Delete;
  const factory GridEvent.createRow() = _CreateRow;
  const factory GridEvent.didLoadRows(List<GridRowData> rows) = _DidLoadRows;
}

@freezed
abstract class GridState with _$GridState {
  const factory GridState({
    required GridLoadingState loadingState,
    required Option<List<Field>> fields,
    required List<GridRowData> rows,
    required Option<Grid> grid,
  }) = _GridState;

  factory GridState.initial() => GridState(
        loadingState: const _Loading(),
        fields: none(),
        rows: [],
        grid: none(),
      );
}

@freezed
class GridLoadingState with _$GridLoadingState {
  const factory GridLoadingState.loading() = _Loading;
  const factory GridLoadingState.finish(Either<Unit, FlowyError> successOrFail) = _Finish;
}
