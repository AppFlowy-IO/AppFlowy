import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/row/row_cache.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'mobile_row_detail_bloc.freezed.dart';

class MobileRowDetailBloc
    extends Bloc<MobileRowDetailEvent, MobileRowDetailState> {
  MobileRowDetailBloc({required this.databaseController})
      : super(MobileRowDetailState.initial()) {
    _dispatch();
  }

  final DatabaseController databaseController;

  void _dispatch() {
    on<MobileRowDetailEvent>(
      (event, emit) {
        event.when(
          initial: (rowId) {
            _startListening();
            emit(
              state.copyWith(
                isLoading: false,
                currentRowId: rowId,
                rowInfos: databaseController.rowCache.rowInfos,
              ),
            );
          },
          didLoadRows: (rows) {
            emit(state.copyWith(rowInfos: rows));
          },
          changeRowId: (rowId) {
            emit(state.copyWith(currentRowId: rowId));
          },
        );
      },
    );
  }

  void _startListening() {
    final onDatabaseChanged = DatabaseCallbacks(
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
    databaseController.addListener(onDatabaseChanged: onDatabaseChanged);
  }
}

@freezed
class MobileRowDetailEvent with _$MobileRowDetailEvent {
  const factory MobileRowDetailEvent.initial(String rowId) = _Initial;
  const factory MobileRowDetailEvent.didLoadRows(List<RowInfo> rows) =
      _DidLoadRows;
  const factory MobileRowDetailEvent.changeRowId(String rowId) = _ChangeRowId;
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
