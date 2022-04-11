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

  GridBloc({required View view})
      : _fieldListener = GridFieldsListener(gridId: view.id),
        _gridService = GridService(gridId: view.id),
        _gridListener = GridListener(gridId: view.id),
        super(GridState.initial(view.id)) {
    on<GridEvent>(
      (event, emit) async {
        await event.map(
          initial: (InitialGrid value) async {
            await _initGrid(emit);
            _startListening();
          },
          createRow: (_CreateRow value) {
            _gridService.createRow();
          },
          didReceiveRowUpdate: (_DidReceiveRowUpdate value) {
            emit(state.copyWith(rows: value.rows, listState: value.listState));
          },
          didReceiveFieldUpdate: (_DidReceiveFieldUpdate value) {
            final rows = state.rows.map((row) => row.copyWith(fields: value.fields)).toList();
            emit(state.copyWith(
              rows: rows,
              fields: value.fields,
              listState: const GridListState.reload(),
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
      result.fold((gridBlockChangeset) {
        for (final changeset in gridBlockChangeset) {
          if (changeset.insertedRows.isNotEmpty) {
            _insertRows(changeset.insertedRows);
          }

          if (changeset.deletedRows.isNotEmpty) {
            _deleteRows(changeset.deletedRows);
          }

          if (changeset.updatedRows.isNotEmpty) {
            _updateRows(changeset.updatedRows);
          }
        }
      }, (err) => Log.error(err));
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
          emit(state.copyWith(
            grid: Some(grid),
            fields: fields.items,
            rows: _buildRows(grid.blockOrders, fields.items),
            loadingState: GridLoadingState.finish(left(unit)),
          ));
        },
        (err) => emit(state.copyWith(loadingState: GridLoadingState.finish(right(err)))),
      ),
    );
  }

  void _deleteRows(List<RowOrder> deletedRows) {
    final List<RowData> rows = [];
    final List<Tuple2<int, RowData>> deletedIndex = [];
    final Map<String, RowOrder> deletedRowMap = {for (var rowOrder in deletedRows) rowOrder.rowId: rowOrder};
    state.rows.asMap().forEach((index, value) {
      if (deletedRowMap[value.rowId] == null) {
        rows.add(value);
      } else {
        deletedIndex.add(Tuple2(index, value));
      }
    });

    add(GridEvent.didReceiveRowUpdate(rows, GridListState.delete(deletedIndex)));
  }

  void _insertRows(List<IndexRowOrder> createdRows) {
    final List<RowData> rows = List.from(state.rows);
    List<int> insertIndexs = [];
    for (final newRow in createdRows) {
      if (newRow.hasIndex()) {
        insertIndexs.add(newRow.index);
        rows.insert(newRow.index, _toRowData(newRow.rowOrder));
      } else {
        insertIndexs.add(rows.length);
        rows.add(_toRowData(newRow.rowOrder));
      }
    }
    add(GridEvent.didReceiveRowUpdate(rows, GridListState.insert(insertIndexs)));
  }

  void _updateRows(List<RowOrder> updatedRows) {
    final List<RowData> rows = List.from(state.rows);
    final List<int> updatedIndexs = [];
    for (final updatedRow in updatedRows) {
      final index = rows.indexWhere((row) => row.rowId == updatedRow.rowId);
      if (index != -1) {
        rows.removeAt(index);
        rows.insert(index, _toRowData(updatedRow));
        updatedIndexs.add(index);
      }
    }
    add(GridEvent.didReceiveRowUpdate(rows, const GridListState.reload()));
  }

  List<RowData> _buildRows(List<GridBlockOrder> blockOrders, List<Field> fields) {
    return blockOrders.expand((blockOrder) => blockOrder.rowOrders).map((rowOrder) {
      return RowData.fromBlockRow(state.gridId, rowOrder, fields);
    }).toList();
  }

  RowData _toRowData(RowOrder rowOrder) {
    return RowData.fromBlockRow(state.gridId, rowOrder, state.fields);
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
        listState: const _Reload(),
      );
}

@freezed
class GridLoadingState with _$GridLoadingState {
  const factory GridLoadingState.loading() = _Loading;
  const factory GridLoadingState.finish(Either<Unit, FlowyError> successOrFail) = _Finish;
}

@freezed
class GridListState with _$GridListState {
  const factory GridListState.insert(List<int> indexs) = _Insert;
  const factory GridListState.delete(List<Tuple2<int, RowData>> indexs) = _Delete;
  const factory GridListState.reload() = _Reload;
}
