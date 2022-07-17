import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'block/block_cache.dart';
import 'grid_service.dart';
import 'row/row_service.dart';
import 'dart:collection';

part 'grid_bloc.freezed.dart';

class GridBloc extends Bloc<GridEvent, GridState> {
  final String gridId;
  final GridService _gridService;
  final GridFieldCache fieldCache;

  // key: the block id
  final LinkedHashMap<String, GridBlockCache> _blocks;

  List<GridRowInfo> get rowInfos {
    final List<GridRowInfo> rows = [];
    for (var block in _blocks.values) {
      rows.addAll(block.rows);
    }
    return rows;
  }

  GridBloc({required View view})
      : gridId = view.id,
        _blocks = LinkedHashMap.identity(),
        _gridService = GridService(gridId: view.id),
        fieldCache = GridFieldCache(gridId: view.id),
        super(GridState.initial(view.id)) {
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
          didReceiveRowUpdate: (newRowInfos, reason) {
            emit(state.copyWith(rowInfos: newRowInfos, reason: reason));
          },
          didReceiveFieldUpdate: (fields) {
            emit(state.copyWith(rowInfos: rowInfos, fields: GridFieldEquatable(fields)));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await _gridService.closeGrid();
    await fieldCache.dispose();

    for (final blockCache in _blocks.values) {
      blockCache.dispose();
    }
    return super.close();
  }

  GridRowCache? getRowCache(String blockId, String rowId) {
    final GridBlockCache? blockCache = _blocks[blockId];
    return blockCache?.rowCache;
  }

  void _startListening() {
    fieldCache.addListener(
      listenWhen: () => !isClosed,
      onFields: (fields) => add(GridEvent.didReceiveFieldUpdate(fields)),
    );
  }

  Future<void> _loadGrid(Emitter<GridState> emit) async {
    final result = await _gridService.loadGrid();
    return Future(
      () => result.fold(
        (grid) async {
          _initialBlocks(grid.blocks);
          await _loadFields(grid, emit);
        },
        (err) => emit(state.copyWith(loadingState: GridLoadingState.finish(right(err)))),
      ),
    );
  }

  Future<void> _loadFields(Grid grid, Emitter<GridState> emit) async {
    final result = await _gridService.getFields(fieldOrders: grid.fields);
    return Future(
      () => result.fold(
        (fields) {
          fieldCache.fields = fields.items;

          emit(state.copyWith(
            grid: Some(grid),
            fields: GridFieldEquatable(fieldCache.fields),
            rowInfos: rowInfos,
            loadingState: GridLoadingState.finish(left(unit)),
          ));
        },
        (err) => emit(state.copyWith(loadingState: GridLoadingState.finish(right(err)))),
      ),
    );
  }

  void _initialBlocks(List<GridBlock> blocks) {
    for (final block in blocks) {
      if (_blocks[block.id] != null) {
        Log.warn("Intial duplicate block's cache: ${block.id}");
        return;
      }

      final cache = GridBlockCache(
        gridId: gridId,
        block: block,
        fieldCache: fieldCache,
      );

      cache.addListener(
        listenWhen: () => !isClosed,
        onChangeReason: (reason) => add(GridEvent.didReceiveRowUpdate(rowInfos, reason)),
      );

      _blocks[block.id] = cache;
    }
  }
}

@freezed
class GridEvent with _$GridEvent {
  const factory GridEvent.initial() = InitialGrid;
  const factory GridEvent.createRow() = _CreateRow;
  const factory GridEvent.didReceiveRowUpdate(List<GridRowInfo> rows, GridRowChangeReason listState) =
      _DidReceiveRowUpdate;
  const factory GridEvent.didReceiveFieldUpdate(List<Field> fields) = _DidReceiveFieldUpdate;
}

@freezed
class GridState with _$GridState {
  const factory GridState({
    required String gridId,
    required Option<Grid> grid,
    required GridFieldEquatable fields,
    required List<GridRowInfo> rowInfos,
    required GridLoadingState loadingState,
    required GridRowChangeReason reason,
  }) = _GridState;

  factory GridState.initial(String gridId) => GridState(
        fields: const GridFieldEquatable([]),
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
