import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/row/row_cache.dart';
import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/row_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'mobile_row_detail_bloc.freezed.dart';

class MobileRowDetailBloc
    extends Bloc<MobileRowDetailEvent, MobileRowDetailState> {
  MobileRowDetailBloc({required this.databaseController})
      : super(MobileRowDetailState.initial()) {
    rowBackendService = RowBackendService(viewId: databaseController.viewId);
    _dispatch();
  }

  final DatabaseController databaseController;
  late final RowBackendService rowBackendService;

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
    on<MobileRowDetailEvent>(
      (event, emit) {
        event.when(
          initial: (rowId) async {
            _startListening();

            emit(
              state.copyWith(
                isLoading: false,
                currentRowId: rowId,
                rowInfos: databaseController.rowCache.rowInfos,
              ),
            );

            final result = await UserEventGetUserProfile().send();
            result.fold(
              (profile) => _userProfile = profile,
              (error) => Log.error(error),
            );
          },
          didLoadRows: (rows) {
            emit(state.copyWith(rowInfos: rows));
          },
          changeRowId: (rowId) {
            emit(state.copyWith(currentRowId: rowId));
          },
          addCover: (rowCover) async {
            if (state.currentRowId == null) {
              return;
            }

            await rowBackendService.updateMeta(
              rowId: state.currentRowId!,
              cover: rowCover,
            );
          },
        );
      },
    );
  }

  void _startListening() {
    _databaseCallbacks = DatabaseCallbacks(
      onNumOfRowsChanged: (rowInfos, _, reason) {
        if (!isClosed) {
          add(MobileRowDetailEvent.didLoadRows(rowInfos));
        }
      },
      onRowsUpdated: (rows, reason) {
        if (!isClosed) {
          add(
            MobileRowDetailEvent.didLoadRows(
              databaseController.rowCache.rowInfos,
            ),
          );
        }
      },
    );
    databaseController.addListener(onDatabaseChanged: _databaseCallbacks);
  }
}

@freezed
class MobileRowDetailEvent with _$MobileRowDetailEvent {
  const factory MobileRowDetailEvent.initial(String rowId) = _Initial;
  const factory MobileRowDetailEvent.didLoadRows(List<RowInfo> rows) =
      _DidLoadRows;
  const factory MobileRowDetailEvent.changeRowId(String rowId) = _ChangeRowId;
  const factory MobileRowDetailEvent.addCover(RowCoverPB cover) = _AddCover;
}

@freezed
class MobileRowDetailState with _$MobileRowDetailState {
  const factory MobileRowDetailState({
    required bool isLoading,
    required String? currentRowId,
    required List<RowInfo> rowInfos,
  }) = _MobileRowDetailState;

  factory MobileRowDetailState.initial() {
    return const MobileRowDetailState(
      isLoading: true,
      rowInfos: [],
      currentRowId: null,
    );
  }
}
