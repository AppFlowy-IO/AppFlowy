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

part 'gallery_bloc.freezed.dart';

class GalleryBloc extends Bloc<GalleryEvent, GalleryState> {
  GalleryBloc({required ViewPB view, required this.databaseController})
      : super(GalleryState.initial(view.id)) {
    _dispatch();
  }

  final DatabaseController databaseController;

  String get viewId => databaseController.viewId;

  UserProfilePB? _userProfile;
  UserProfilePB? get userProfile => _userProfile;

  void _dispatch() {
    on<GalleryEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            final response = await UserEventGetUserProfile().send();
            response.fold(
              (userProfile) => _userProfile = userProfile,
              (err) => Log.error(err),
            );

            _startListening();
            await _openGallery(emit);
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
            final result = await RowBackendService.createRow(viewId: viewId);
            result.fold(
              (createdRow) => emit(
                state.copyWith(
                  createdRow: createdRow,
                  openRowDetail: openRowDetail ?? false,
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
        );
      },
    );
  }

  RowCache get rowCache => databaseController.rowCache;

  void _startListening() {
    final onDatabaseChanged = DatabaseCallbacks(
      onNumOfRowsChanged: (rowInfos, _, reason) {
        if (!isClosed) {
          add(GalleryEvent.didLoadRows(rowInfos, reason));
        }
      },
      onRowsCreated: (rows) {
        for (final row in rows) {
          if (!isClosed && row.isHiddenInView) {
            add(GalleryEvent.openRowDetail(row.rowMeta));
          }
        }
      },
      onRowsUpdated: (rows, reason) {
        if (!isClosed) {
          add(
            GalleryEvent.didLoadRows(
              databaseController.rowCache.rowInfos,
              reason,
            ),
          );
        }
      },
      onFieldsChanged: (fields) {
        if (!isClosed) {
          add(GalleryEvent.didReceiveFieldUpdate(fields));
        }
      },
      onFiltersChanged: (filters) {
        if (!isClosed) {
          add(GalleryEvent.didReceveFilters(filters));
        }
      },
      onSortsChanged: (sorts) {
        if (!isClosed) {
          add(GalleryEvent.didReceveSorts(sorts));
        }
      },
    );
    databaseController.addListener(onDatabaseChanged: onDatabaseChanged);
  }

  Future<void> _openGallery(Emitter<GalleryState> emit) async {
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
class GalleryEvent with _$GalleryEvent {
  const factory GalleryEvent.initial() = InitialGrid;
  const factory GalleryEvent.openRowDetail(RowMetaPB row) = _OpenRowDetail;
  const factory GalleryEvent.createRow({bool? openRowDetail}) = _CreateRow;
  const factory GalleryEvent.resetCreatedRow() = _ResetCreatedRow;
  const factory GalleryEvent.deleteRow(RowInfo rowInfo) = _DeleteRow;
  const factory GalleryEvent.moveRow(int from, int to) = _MoveRow;
  const factory GalleryEvent.didLoadRows(
    List<RowInfo> rows,
    ChangedReason reason,
  ) = _DidReceiveRowUpdate;
  const factory GalleryEvent.didReceiveFieldUpdate(
    List<FieldInfo> fields,
  ) = _DidReceiveFieldUpdate;

  const factory GalleryEvent.didReceveFilters(List<DatabaseFilter> filters) =
      _DidReceiveFilters;
  const factory GalleryEvent.didReceveSorts(List<DatabaseSort> sorts) =
      _DidReceiveSorts;
}

@freezed
class GalleryState with _$GalleryState {
  const factory GalleryState({
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
  }) = _GalleryState;

  factory GalleryState.initial(String viewId) => GalleryState(
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
      );
}
