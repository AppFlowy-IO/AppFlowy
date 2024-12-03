import 'dart:async';

import 'package:appflowy/plugins/database/application/defines.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/application/field/filter_entities.dart';
import 'package:appflowy/plugins/database/application/field/sort_entities.dart';
import 'package:appflowy/plugins/database/application/row/row_cache.dart';
import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../application/database_controller.dart';

part 'grid_bloc.freezed.dart';

class GridBloc extends Bloc<GridEvent, GridState> {
  GridBloc({
    required ViewPB view,
    required this.databaseController,
    this.shrinkWrapped = false,
  }) : super(GridState.initial(view.id)) {
    _dispatch();
  }

  final DatabaseController databaseController;

  /// When true will emit the count of visible rows to show
  ///
  final bool shrinkWrapped;

  String get viewId => databaseController.viewId;

  UserProfilePB? _userProfile;
  UserProfilePB? get userProfile => _userProfile;

  DatabaseCallbacks? _databaseCallbacks;

  @override
  Future<void> close() async {
    databaseController.removeListener(onDatabaseChanged: _databaseCallbacks);
    _databaseCallbacks = null;
    await super.close();
  }

  void _dispatch() {
    on<GridEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            final response = await UserEventGetUserProfile().send();
            response.fold(
              (userProfile) => _userProfile = userProfile,
              (err) => Log.error(err),
            );

            _startListening();
            await _openGrid(emit);
          },
          openRowDetail: (row) {
            emit(
              state.copyWith(
                createdRow: row,
                openRowDetail: true,
              ),
            );
          },
          createRow: (openRowDetail) async {
            final lastVisibleRowId =
                shrinkWrapped ? state.lastVisibleRow?.rowId : null;

            final result = await RowBackendService.createRow(
              viewId: viewId,
              position: lastVisibleRowId != null
                  ? OrderObjectPositionTypePB.After
                  : null,
              targetRowId: lastVisibleRowId,
            );
            result.fold(
              (createdRow) => emit(
                state.copyWith(
                  createdRow: createdRow,
                  openRowDetail: openRowDetail ?? false,
                  visibleRows: state.visibleRows + 1,
                ),
              ),
              (err) => Log.error(err),
            );
          },
          resetCreatedRow: () {
            emit(state.copyWith(createdRow: null, openRowDetail: false));
          },
          deleteRow: (rowInfo) async {
            await RowBackendService.deleteRows(viewId, [rowInfo.rowId]);
          },
          moveRow: (int from, int to) {
            final List<RowInfo> rows = [...state.rowInfos];

            final fromRow = rows[from].rowId;
            final toRow = rows[to].rowId;

            rows.insert(to, rows.removeAt(from));
            emit(state.copyWith(rowInfos: rows));

            databaseController.moveRow(fromRowId: fromRow, toRowId: toRow);
          },
          didReceiveFieldUpdate: (fields) {
            emit(state.copyWith(fields: fields));
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
          didReceveFilters: (filters) {
            emit(state.copyWith(filters: filters));
          },
          didReceveSorts: (sorts) {
            emit(state.copyWith(reorderable: sorts.isEmpty, sorts: sorts));
          },
          loadMoreRows: () {
            emit(state.copyWith(visibleRows: state.visibleRows + 25));
          },
        );
      },
    );
  }

  RowCache get rowCache => databaseController.rowCache;

  void _startListening() {
    _databaseCallbacks = DatabaseCallbacks(
      onNumOfRowsChanged: (rowInfos, _, reason) {
        if (!isClosed) {
          add(GridEvent.didLoadRows(rowInfos, reason));
        }
      },
      onRowsCreated: (rows) {
        for (final row in rows) {
          if (!isClosed && row.isHiddenInView) {
            add(GridEvent.openRowDetail(row.rowMeta));
          }
        }
      },
      onRowsUpdated: (rows, reason) {
        // TODO(nathan): separate different reasons
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
    databaseController.addListener(onDatabaseChanged: _databaseCallbacks);
  }

  Future<void> _openGrid(Emitter<GridState> emit) async {
    final result = await databaseController.open();
    result.fold(
      (grid) {
        databaseController.setIsLoading(false);
        emit(
          state.copyWith(
            loadingState: LoadingState.finish(FlowyResult.success(null)),
          ),
        );
      },
      (err) => emit(
        state.copyWith(
          loadingState: LoadingState.finish(FlowyResult.failure(err)),
        ),
      ),
    );
  }
}

@freezed
class GridEvent with _$GridEvent {
  const factory GridEvent.initial() = InitialGrid;
  const factory GridEvent.openRowDetail(RowMetaPB row) = _OpenRowDetail;
  const factory GridEvent.createRow({bool? openRowDetail}) = _CreateRow;
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
  const factory GridEvent.didReceveFilters(List<DatabaseFilter> filters) =
      _DidReceiveFilters;
  const factory GridEvent.didReceveSorts(List<DatabaseSort> sorts) =
      _DidReceiveSorts;
  const factory GridEvent.loadMoreRows() = _LoadMoreRows;
}

@freezed
class GridState with _$GridState {
  const factory GridState({
    required String viewId,
    required List<FieldInfo> fields,
    required List<RowInfo> rowInfos,
    required int rowCount,
    required RowMetaPB? createdRow,
    required LoadingState loadingState,
    required bool reorderable,
    required ChangedReason reason,
    required List<DatabaseSort> sorts,
    required List<DatabaseFilter> filters,
    required bool openRowDetail,
    @Default(0) int visibleRows,
  }) = _GridState;

  factory GridState.initial(String viewId) => GridState(
        fields: [],
        rowInfos: [],
        rowCount: 0,
        createdRow: null,
        viewId: viewId,
        reorderable: true,
        loadingState: const LoadingState.loading(),
        reason: const InitialListState(),
        filters: [],
        sorts: [],
        openRowDetail: false,
        visibleRows: 25,
      );
}

extension _LastVisibleRow on GridState {
  /// Returns the last visible [RowInfo] in the list of [rowInfos].
  /// Only returns if the visibleRows is less than the rowCount, otherwise returns null.
  ///
  RowInfo? get lastVisibleRow {
    if (visibleRows < rowCount) {
      return rowInfos[visibleRows - 1];
    }

    return null;
  }
}
