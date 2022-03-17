import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'data.dart';
import 'grid_listener.dart';
import 'grid_service.dart';

part 'grid_bloc.freezed.dart';

class GridBloc extends Bloc<GridEvent, GridState> {
  final View view;
  final GridService service;
  final GridListener listener;

  GridBloc({required this.view, required this.service, required this.listener}) : super(GridState.initial()) {
    on<GridEvent>(
      (event, emit) async {
        await event.map(
          initial: (InitialGrid value) async {
            await _startGridListening();
            await _loadGrid(emit);
          },
          createRow: (_CreateRow value) {
            service.createRow(gridId: view.id);
          },
          delete: (_Delete value) {},
          rename: (_Rename value) {},
          updateDesc: (_Desc value) {},
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await listener.close();
    return super.close();
  }

  Future<void> _startGridListening() async {
    listener.blockUpdateNotifier.addPublishListener((result) {
      result.fold((blockId) {
        //
        Log.info("$blockId");
      }, (err) => null);
    });

    listener.start();
  }

  Future<void> _loadGrid(Emitter<GridState> emit) async {
    final result = await service.openGrid(gridId: view.id);
    result.fold(
      (grid) {
        _loadFields(grid, emit);
        emit(state.copyWith(grid: Some(grid)));
      },
      (err) => emit(state.copyWith(loadingState: GridLoadingState.finish(right(err)))),
    );
  }

  Future<void> _loadFields(Grid grid, Emitter<GridState> emit) async {
    final result = await service.getFields(gridId: grid.id, fieldOrders: grid.fieldOrders);
    result.fold(
      (fields) {
        _loadGridBlocks(grid, emit);
        emit(state.copyWith(fields: fields.items));
      },
      (err) => emit(state.copyWith(loadingState: GridLoadingState.finish(right(err)))),
    );
  }

  Future<void> _loadGridBlocks(Grid grid, Emitter<GridState> emit) async {
    final result = await service.getGridBlocks(gridId: grid.id, blocks: grid.blocks);

    result.fold((repeatedGridBlock) {
      final blocks = repeatedGridBlock.items;
      final gridInfo = GridInfo(
        gridId: grid.id,
        blocks: blocks,
        fields: _fields!,
      );
      emit(
        state.copyWith(loadingState: GridLoadingState.finish(left(unit)), gridInfo: some(left(gridInfo))),
      );
    }, (err) {
      emit(
        state.copyWith(loadingState: GridLoadingState.finish(right(err)), gridInfo: none()),
      );
    });
  }
}

@freezed
abstract class GridEvent with _$GridEvent {
  const factory GridEvent.initial() = InitialGrid;
  const factory GridEvent.rename(String gridId, String name) = _Rename;
  const factory GridEvent.updateDesc(String gridId, String desc) = _Desc;
  const factory GridEvent.delete(String gridId) = _Delete;
  const factory GridEvent.createRow() = _CreateRow;
}

@freezed
abstract class GridState with _$GridState {
  const factory GridState({
    required GridLoadingState loadingState,
    required List<Field> fields,
    required List<Row> rows,
    required Option<Grid> grid,
  }) = _GridState;

  factory GridState.initial() => GridState(
        loadingState: const _Loading(),
        fields: [],
        rows: [],
        grid: none(),
      );
}

@freezed
class GridLoadingState with _$GridLoadingState {
  const factory GridLoadingState.loading() = _Loading;
  const factory GridLoadingState.finish(Either<Unit, FlowyError> successOrFail) = _Finish;
}
