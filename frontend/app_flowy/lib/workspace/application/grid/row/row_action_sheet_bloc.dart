import 'package:app_flowy/workspace/application/grid/row/row_service.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'package:dartz/dartz.dart';

part 'row_action_sheet_bloc.freezed.dart';

class RowActionSheetBloc extends Bloc<RowActionSheetEvent, RowActionSheetState> {
  final RowService _rowService;

  RowActionSheetBloc({required GridRow rowData})
      : _rowService = RowService(gridId: rowData.gridId, rowId: rowData.rowId),
        super(RowActionSheetState.initial(rowData)) {
    on<RowActionSheetEvent>(
      (event, emit) async {
        await event.map(
          deleteRow: (_DeleteRow value) async {
            final result = await _rowService.deleteRow();
            logResult(result);
          },
          duplicateRow: (_DuplicateRow value) async {
            final result = await _rowService.duplicateRow();
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
    required GridRow rowData,
  }) = _RowActionSheetState;

  factory RowActionSheetState.initial(GridRow rowData) => RowActionSheetState(
        rowData: rowData,
      );
}
