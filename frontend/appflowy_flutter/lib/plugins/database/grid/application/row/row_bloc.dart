import 'dart:async';
import 'dart:collection';

import 'package:appflowy/plugins/database/application/defines.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../application/row/row_cache.dart';
import '../../../application/row/row_controller.dart';
import '../../../application/row/row_service.dart';

part 'row_bloc.freezed.dart';

class RowBloc extends Bloc<RowEvent, RowState> {
  final RowBackendService _rowBackendSvc;
  final RowController _rowController;
  final String viewId;
  final String rowId;

  RowBloc({
    required this.rowId,
    required this.viewId,
    required RowController rowController,
  })  : _rowBackendSvc = RowBackendService(viewId: viewId),
        _rowController = rowController,
        super(RowState.initial()) {
    on<RowEvent>(
      (event, emit) async {
        await event.when(
          initial: () {
            _startListening();
          },
          createRow: () {
            _rowBackendSvc.createRowAfter(rowId);
          },
          didReceiveCells: (cellByFieldId, reason) async {
            cellByFieldId.removeWhere(
              (_, cellContext) => !cellContext.isVisible(),
            );
            emit(
              state.copyWith(
                cellByFieldId: cellByFieldId,
                changeReason: reason,
              ),
            );
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    _rowController.dispose();
    return super.close();
  }

  void _startListening() {
    _rowController.addListener(
      onRowChanged: (cells, reason) {
        if (!isClosed) {
          add(RowEvent.didReceiveCells(cells, reason));
        }
      },
    );
  }
}

@freezed
class RowEvent with _$RowEvent {
  const factory RowEvent.initial() = _InitialRow;
  const factory RowEvent.createRow() = _CreateRow;
  const factory RowEvent.didReceiveCells(
    CellContextByFieldId cellsByFieldId,
    ChangedReason reason,
  ) = _DidReceiveCells;
}

@freezed
class RowState with _$RowState {
  const factory RowState({
    required CellContextByFieldId cellByFieldId,
    ChangedReason? changeReason,
  }) = _RowState;

  factory RowState.initial() {
    return RowState(
      cellByFieldId: CellContextByFieldId(),
      changeReason: null,
    );
  }
}
