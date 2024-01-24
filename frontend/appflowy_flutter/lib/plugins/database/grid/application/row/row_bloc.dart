import 'dart:async';
import 'dart:collection';

import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/defines.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/widgets/setting/field_visibility_extension.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../application/row/row_cache.dart';
import '../../../application/row/row_controller.dart';
import '../../../application/row/row_service.dart';

part 'row_bloc.freezed.dart';

class RowBloc extends Bloc<RowEvent, RowState> {
  final FieldController fieldController;
  final RowBackendService _rowBackendSvc;
  final RowController _rowController;
  final String viewId;
  final String rowId;

  RowBloc({
    required this.fieldController,
    required this.rowId,
    required this.viewId,
    required RowController rowController,
  })  : _rowBackendSvc = RowBackendService(viewId: viewId),
        _rowController = rowController,
        super(RowState.initial()) {
    _dispatch();
    _startListening();
    _init();
  }

  @override
  Future<void> close() async {
    _rowController.dispose();
    return super.close();
  }

  void _dispatch() {
    on<RowEvent>(
      (event, emit) async {
        event.when(
          createRow: () {
            _rowBackendSvc.createRowAfter(rowId);
          },
          didReceiveCells: (CellContextByFieldId cellByFieldId, reason) {
            cellByFieldId.removeWhere(
              (_, cellContext) => !fieldController
                  .getField(cellContext.fieldId)!
                  .fieldSettings!
                  .visibility
                  .isVisibleState(),
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

  void _startListening() {
    _rowController.addListener(
      onRowChanged: (cells, reason) {
        if (!isClosed) {
          add(RowEvent.didReceiveCells(cells, reason));
        }
      },
    );
  }

  void _init() {
    add(
      RowEvent.didReceiveCells(
        _rowController.loadData(),
        const ChangedReason.setInitialRows(),
      ),
    );
  }
}

@freezed
class RowEvent with _$RowEvent {
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
    );
  }
}
