import 'dart:async';
import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
import 'package:appflowy/plugins/database_view/application/row/row_service.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/filter/filter_info.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/sort/sort_info.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../application/field/field_controller.dart';
import '../../application/database_controller.dart';
import 'dart:collection';

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
          createRow: () {
            databaseController.createRow();
          },
          deleteRow: (rowInfo) async {
            final rowService = RowBackendService(
              viewId: rowInfo.viewId,
            );
            await rowService.deleteRow(rowInfo.rowId);
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
                fields: GridFieldEquatable(fields),
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
              state.copyWith(
                reorderable: filters.isEmpty && state.sorts.isEmpty,
                filters: filters,
              ),
            );
          },
          didReceveSorts: (List<SortInfo> sorts) {
            emit(
              state.copyWith(
                reorderable: sorts.isEmpty && state.filters.isEmpty,
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
        emit(
          state.copyWith(loadingState: GridLoadingState.finish(left(unit))),
        );
      },
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
  const factory GridEvent.deleteRow(RowInfo rowInfo) = _DeleteRow;
  const factory GridEvent.moveRow(int from, int to) = _MoveRow;
  const factory GridEvent.didLoadRows(
    List<RowInfo> rows,
    RowsChangedReason reason,
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
    required GridFieldEquatable fields,
    required List<RowInfo> rowInfos,
    required int rowCount,
    required GridLoadingState loadingState,
    required bool reorderable,
    required RowsChangedReason reason,
    required List<SortInfo> sorts,
    required List<FilterInfo> filters,
  }) = _GridState;

  factory GridState.initial(String viewId) => GridState(
        fields: GridFieldEquatable(UnmodifiableListView([])),
        rowInfos: [],
        rowCount: 0,
        grid: none(),
        viewId: viewId,
        reorderable: true,
        loadingState: const _Loading(),
        reason: const InitialListState(),
        filters: [],
        sorts: [],
      );
}

@freezed
class GridLoadingState with _$GridLoadingState {
  const factory GridLoadingState.loading() = _Loading;
  const factory GridLoadingState.finish(
    Either<Unit, FlowyError> successOrFail,
  ) = _Finish;
}

class GridFieldEquatable extends Equatable {
  final List<FieldInfo> _fields;
  const GridFieldEquatable(
    List<FieldInfo> fields,
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

  UnmodifiableListView<FieldInfo> get value => UnmodifiableListView(_fields);
}
