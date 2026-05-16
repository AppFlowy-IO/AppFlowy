import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/widgets/setting/field_visibility_extension.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../application/row/row_cache.dart';
import '../../../application/row/row_controller.dart';
import '../../../application/row/row_service.dart';

part 'row_bloc.freezed.dart';

class RowBloc extends Bloc<RowEvent, RowState> {
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
    rowController.initialize();
  }

  final FieldController fieldController;
  final RowBackendService _rowBackendSvc;
  final RowController _rowController;
  final String viewId;
  final String rowId;

  @override
  Future<void> close() async {
    await _rowController.dispose();
    return super.close();
  }

  void _dispatch() {
    on<RowEvent>(
      (event, emit) async {
        event.when(
          createRow: () {
            _rowBackendSvc.createRowAfter(rowId);
          },
          didReceiveCells: (List<CellContext> cellContexts, reason) {
            final visibleCellContexts = cellContexts
                .where(
                  (cellContext) => fieldController
                      .getField(cellContext.fieldId)!
                      .fieldSettings!
                      .visibility
                      .isVisibleState(),
                )
                .toList();
            emit(
              state.copyWith(
                cellContexts: visibleCellContexts,
                changeReason: reason,
              ),
            );
          },
        );
      },
    );
  }

  void _startListening() =>
      _rowController.addListener(onRowChanged: _onRowChanged);

  void _onRowChanged(List<CellContext> cells, ChangedReason reason) {
    if (!isClosed) {
      add(RowEvent.didReceiveCells(cells, reason));
    }
  }

  void _init() {
    add(
      RowEvent.didReceiveCells(
        _rowController.loadCells(),
        const ChangedReason.setInitialRows(),
      ),
    );
  }
}

@freezed
class RowEvent with _$RowEvent {
  const factory RowEvent.createRow() = _CreateRow;
  const factory RowEvent.didReceiveCells(
    List<CellContext> cellsByFieldId,
    ChangedReason reason,
  ) = _DidReceiveCells;
}

@freezed
class RowState with _$RowState {
  const factory RowState({
    required List<CellContext> cellContexts,
    ChangedReason? changeReason,
  }) = _RowState;

  factory RowState.initial() => const RowState(cellContexts: []);
}
