import 'dart:async';
import 'package:appflowy/plugins/database_view/application/defines.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
import 'package:appflowy/plugins/database_view/application/row/row_service.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/filter/filter_info.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/sort/sort_info.dart';
import 'package:appflowy_backend/log.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../application/database_controller.dart';

part 'grid_bloc.freezed.dart';

class GridBloc extends Bloc<GridEvent, GridState> {
  final DatabaseController databaseController;

  GridBloc({required ViewPB view, required this.databaseController})
      : super(GridState.initial(view.id)) {
    on<GridEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            _startListening();
            await _openGrid(emit);
          },
          createRow: () async {
            final result = await databaseController.createRow();
            result.fold(
              (createdRow) => emit(state.copyWith(createdRow: createdRow)),
              (err) => Log.error(err),
            );
          },
          resetCreatedRow: () {
            emit(state.copyWith(createdRow: null));
          },
          deleteRow: (rowInfo) async {
            await RowBackendService.deleteRow(rowInfo.viewId, rowInfo.rowId);
          },
          moveRow: (int from, int to) {
            final List<RowInfo> rows = [...state.rowInfos];

            final fromRow = rows[from].rowId;
            final toRow = rows[to].rowId;

            rows.insert(to, rows.removeAt(from));
            emit(state.copyWith(rowInfos: rows));

            databaseController.moveRow(fromRowId: fromRow, toRowId: toRow);
          },
          didReceiveGridUpdate: (grid) {
            emit(state.copyWith(grid: Some(grid)));
          },
          didReceiveFieldUpdate: (fields) {
            emit(
              state.copyWith(
                fields: fields,
              ),
            );
          },
          didLoadRows: (newRowInfos, reason) {
            emit(
              state.copyWith(
                rowInfos: newRowInfos,
                rowCount: newRowInfos.length,
                reason: reason,
              ),
            );
          },
          didReceveFilters: (List<FilterInfo> filters) {
            emit(
              state.copyWith(filters: filters),
            );
          },
          didReceveSorts: (List<SortInfo> sorts) {
            emit(
              state.copyWith(
                reorderable: sorts.isEmpty,
                sorts: sorts,
              ),
            );
          },
        );
      },
    );
  }

  RowCache getRowCache(RowId rowId) {
    return databaseController.rowCache;
  }

  void _startListening() {
    final onDatabaseChanged = DatabaseCallbacks(
      onDatabaseChanged: (database) {
        if (!isClosed) {
          add(GridEvent.didReceiveGridUpdate(database));
        }
      },
      onNumOfRowsChanged: (rowInfos, _, reason) {
        if (!isClosed) {
          add(GridEvent.didLoadRows(rowInfos, reason));
        }
      },
      onRowsUpdated: (rows, reason) {
        if (!isClosed) {
          add(
            GridEvent.didLoadRows(databaseController.rowCache.rowInfos, reason),
          );
        }
      },
      onFieldsChanged: (fields) {
        if (!isClosed) {
          add(GridEvent.didReceiveFieldUpdate(fields));
        }
      },
      onFiltersChanged: (filters) {
        if (!isClosed) {
          add(GridEvent.didReceveFilters(filters));
        }
      },
      onSortsChanged: (sorts) {
        if (!isClosed) {
          add(GridEvent.didReceveSorts(sorts));
        }
      },
    );
    databaseController.addListener(onDatabaseChanged: onDatabaseChanged);
  }

  Future<void> _openGrid(Emitter<GridState> emit) async {
    final result = await databaseController.open();
    result.fold(
      (grid) {
        databaseController.setIsLoading(false);
        emit(
          state.copyWith(loadingState: LoadingState.finish(left(unit))),
        );
      },
      (err) => emit(
        state.copyWith(loadingState: LoadingState.finish(right(err))),
      ),
    );
  }
}

@freezed
class GridEvent with _$GridEvent {
  const factory GridEvent.initial() = InitialGrid;
  const factory GridEvent.createRow() = _CreateRow;
  const factory GridEvent.resetCreatedRow() = _ResetCreatedRow;
  const factory GridEvent.deleteRow(RowInfo rowInfo) = _DeleteRow;
  const factory GridEvent.moveRow(int from, int to) = _MoveRow;
  const factory GridEvent.didLoadRows(
    List<RowInfo> rows,
    ChangedReason reason,
  ) = _DidReceiveRowUpdate;
  const factory GridEvent.didReceiveFieldUpdate(
    List<FieldInfo> fields,
  ) = _DidReceiveFieldUpdate;

  const factory GridEvent.didReceiveGridUpdate(
    DatabasePB grid,
  ) = _DidReceiveGridUpdate;

  const factory GridEvent.didReceveFilters(List<FilterInfo> filters) =
      _DidReceiveFilters;
  const factory GridEvent.didReceveSorts(List<SortInfo> sorts) =
      _DidReceiveSorts;
}

@freezed
class GridState with _$GridState {
  const factory GridState({
    required String viewId,
    required Option<DatabasePB> grid,
    required List<FieldInfo> fields,
    required List<RowInfo> rowInfos,
    required int rowCount,
    required RowMetaPB? createdRow,
    required LoadingState loadingState,
    required bool reorderable,
    required ChangedReason reason,
    required List<SortInfo> sorts,
    required List<FilterInfo> filters,
  }) = _GridState;

  factory GridState.initial(String viewId) => GridState(
        fields: [],
        rowInfos: [],
        rowCount: 0,
        createdRow: null,
        grid: none(),
        viewId: viewId,
        reorderable: true,
        loadingState: const LoadingState.loading(),
        reason: const InitialListState(),
        filters: [],
        sorts: [],
      );
}
