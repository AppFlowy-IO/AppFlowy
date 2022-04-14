import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'field/grid_listenr.dart';
import 'grid_listener.dart';
import 'grid_service.dart';
import 'row/row_service.dart';

part 'grid_bloc.freezed.dart';

class GridBloc extends Bloc<GridEvent, GridState> {
  final GridService _gridService;
  final GridListener _gridListener;
  final GridFieldsListener _fieldListener;
  final GridFieldCache fieldCache;
  final GridRowCache _rowCache;

  GridBloc({required View view})
      : _fieldListener = GridFieldsListener(gridId: view.id),
        _gridService = GridService(gridId: view.id),
        _gridListener = GridListener(gridId: view.id),
        fieldCache = GridFieldCache(),
        _rowCache = GridRowCache(gridId: view.id),
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
            emit(state.copyWith(
              rows: _rowCache.rows,
              fields: value.fields,
            ));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await _gridService.closeGrid();
    await _fieldListener.stop();
    await _gridListener.stop();
    return super.close();
  }

  void _startListening() {
    fieldCache.addListener((fields) {
      _rowCache.updateFields(fields);
    });

    _fieldListener.updateFieldsNotifier.addPublishListener((result) {
      result.fold(
        (changeset) {
          fieldCache.applyChangeset(changeset);
          add(GridEvent.didReceiveFieldUpdate(List.from(fieldCache.fields)));
        },
        (err) => Log.error(err),
      );
    });
    _fieldListener.start();

    _gridListener.rowsUpdateNotifier.addPublishListener((result) {
      result.fold(
        (changesets) {
          for (final changeset in changesets) {
            _rowCache
                .deleteRows(changeset.deletedRows)
                .foldRight(null, (listState, _) => add(GridEvent.didReceiveRowUpdate(_rowCache.rows, listState)));

            _rowCache
                .insertRows(changeset.insertedRows)
                .foldRight(null, (listState, _) => add(GridEvent.didReceiveRowUpdate(_rowCache.rows, listState)));

            _rowCache.updateRows(changeset.updatedRows);
          }
        },
        (err) => Log.error(err),
      );
    });
    _gridListener.start();
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
          _rowCache.updateWithBlock(grid.blockOrders);

          emit(state.copyWith(
            grid: Some(grid),
            fields: fieldCache.fields,
            rows: _rowCache.rows,
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
  const factory GridEvent.didReceiveRowUpdate(List<RowData> rows, GridListState listState) = _DidReceiveRowUpdate;
  const factory GridEvent.didReceiveFieldUpdate(List<Field> fields) = _DidReceiveFieldUpdate;
}

@freezed
class GridState with _$GridState {
  const factory GridState({
    required String gridId,
    required Option<Grid> grid,
    required List<Field> fields,
    required List<RowData> rows,
    required GridLoadingState loadingState,
    required GridListState listState,
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
