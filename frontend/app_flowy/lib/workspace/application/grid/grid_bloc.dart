import 'dart:async';
import 'package:app_flowy/workspace/application/grid/row/row_service.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'grid_block_service.dart';
import 'field/grid_listenr.dart';
import 'grid_listener.dart';
import 'grid_service.dart';

part 'grid_bloc.freezed.dart';

class GridBloc extends Bloc<GridEvent, GridState> {
  final View view;
  final GridService _gridService;
  final GridListener _gridListener;
  final GridFieldsListener _fieldListener;

  GridBloc({required this.view})
      : _fieldListener = GridFieldsListener(gridId: view.id),
        _gridService = GridService(),
        _gridListener = GridListener(gridId: view.id),
        super(GridState.initial()) {
    on<GridEvent>(
      (event, emit) async {
        await event.map(
          initial: (InitialGrid value) async {
            await _initGrid(emit);
            _startListening();
          },
          createRow: (_CreateRow value) {
            _gridService.createRow(gridId: view.id);
          },
          delete: (_Delete value) {},
          rename: (_Rename value) {},
          updateDesc: (_Desc value) {},
          didReceiveRowUpdate: (_DidReceiveRowUpdate value) {
            emit(state.copyWith(rows: value.rows));
          },
          didReceiveFieldUpdate: (_DidReceiveFieldUpdate value) {
            emit(state.copyWith(fields: value.fields));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await _fieldListener.stop();
    await _gridListener.stop();
    return super.close();
  }

  Future<void> _initGrid(Emitter<GridState> emit) async {
    _fieldListener.updateFieldsNotifier.addPublishListener((result) {
      result.fold(
        (fields) => add(GridEvent.didReceiveFieldUpdate(fields)),
        (err) => Log.error(err),
      );
    });
    _fieldListener.start();

    await _loadGrid(emit);
  }

  void _startListening() {
    _gridListener.rowsUpdateNotifier.addPublishListener((result) {
      result.fold((blockOrders) {
        add(GridEvent.didReceiveRowUpdate(_buildRows(blockOrders)));
      }, (err) => Log.error(err));
    });
    _gridListener.start();
  }

  Future<void> _loadGrid(Emitter<GridState> emit) async {
    final result = await _gridService.loadGrid(gridId: view.id);
    return Future(
      () => result.fold(
        (grid) async => await _loadFields(grid, emit),
        (err) => emit(state.copyWith(loadingState: GridLoadingState.finish(right(err)))),
      ),
    );
  }

  Future<void> _loadFields(Grid grid, Emitter<GridState> emit) async {
    final result = await _gridService.getFields(gridId: grid.id, fieldOrders: grid.fieldOrders);
    return Future(
      () => result.fold(
        (fields) {
          emit(state.copyWith(
            grid: Some(grid),
            fields: fields.items,
            rows: _buildRows(grid.blockOrders),
            loadingState: GridLoadingState.finish(left(unit)),
          ));
        },
        (err) => emit(state.copyWith(loadingState: GridLoadingState.finish(right(err)))),
      ),
    );
  }

  List<GridBlockRow> _buildRows(List<GridBlockOrder> blockOrders) {
    List<GridBlockRow> rows = [];
    for (final blockOrder in blockOrders) {
      rows.addAll(blockOrder.rowOrders.map(
        (rowOrder) => GridBlockRow(
          gridId: view.id,
          rowId: rowOrder.rowId,
          height: rowOrder.height.toDouble(),
        ),
      ));
    }
    return rows;
  }
}

@freezed
class GridEvent with _$GridEvent {
  const factory GridEvent.initial() = InitialGrid;
  const factory GridEvent.rename(String gridId, String name) = _Rename;
  const factory GridEvent.updateDesc(String gridId, String desc) = _Desc;
  const factory GridEvent.delete(String gridId) = _Delete;
  const factory GridEvent.createRow() = _CreateRow;
  const factory GridEvent.didReceiveRowUpdate(List<GridBlockRow> rows) = _DidReceiveRowUpdate;
  const factory GridEvent.didReceiveFieldUpdate(List<Field> fields) = _DidReceiveFieldUpdate;
}

@freezed
class GridState with _$GridState {
  const factory GridState({
    required GridLoadingState loadingState,
    required List<Field> fields,
    required List<GridBlockRow> rows,
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
