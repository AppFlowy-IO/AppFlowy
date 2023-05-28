import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';

import '../../../application/row/row_cache.dart';
import '../../../application/row/row_service.dart';

part 'row_action_sheet_bloc.freezed.dart';

class RowActionSheetBloc
    extends Bloc<RowActionSheetEvent, RowActionSheetState> {
  final RowBackendService _rowService;

  RowActionSheetBloc({required RowInfo rowInfo})
      : _rowService = RowBackendService(viewId: rowInfo.viewId),
        super(RowActionSheetState.initial(rowInfo)) {
    on<RowActionSheetEvent>(
      (event, emit) async {
        await event.when(
          deleteRow: () async {
            final result = await _rowService.deleteRow(state.rowData.rowPB.id);
            logResult(result);
          },
          duplicateRow: () async {
            final result =
                await _rowService.duplicateRow(rowId: state.rowData.rowPB.id);
            logResult(result);
          },
        );
      },
    );
  }

  void logResult(Either<Unit, FlowyError> result) {
    result.fold((l) => null, (err) => Log.error(err));
  }
}

@freezed
class RowActionSheetEvent with _$RowActionSheetEvent {
  const factory RowActionSheetEvent.duplicateRow() = _DuplicateRow;
  const factory RowActionSheetEvent.deleteRow() = _DeleteRow;
}

@freezed
class RowActionSheetState with _$RowActionSheetState {
  const factory RowActionSheetState({
    required RowInfo rowData,
  }) = _RowActionSheetState;

  factory RowActionSheetState.initial(RowInfo rowData) => RowActionSheetState(
        rowData: rowData,
      );
}
