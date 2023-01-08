import 'package:app_flowy/plugins/grid/application/row/row_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'package:dartz/dartz.dart';

import 'row_cache.dart';

part 'row_action_sheet_bloc.freezed.dart';

class RowActionSheetBloc
    extends Bloc<RowActionSheetEvent, RowActionSheetState> {
  final RowFFIService _rowService;

  RowActionSheetBloc({required RowInfo rowInfo})
      : _rowService = RowFFIService(gridId: rowInfo.gridId),
        super(RowActionSheetState.initial(rowInfo)) {
    on<RowActionSheetEvent>(
      (event, emit) async {
        await event.map(
          deleteRow: (_DeleteRow value) async {
            final result = await _rowService.deleteRow(state.rowData.rowPB.id);
            logResult(result);
          },
          duplicateRow: (_DuplicateRow value) async {
            final result =
                await _rowService.duplicateRow(state.rowData.rowPB.id);
            logResult(result);
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    return super.close();
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
