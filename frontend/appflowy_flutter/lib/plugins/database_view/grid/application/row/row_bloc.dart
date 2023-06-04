import 'dart:collection';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

import '../../../application/cell/cell_service.dart';
import '../../../application/field/field_controller.dart';
import '../../../application/row/row_cache.dart';
import '../../../application/row/row_data_controller.dart';
import '../../../application/row/row_service.dart';

part 'row_bloc.freezed.dart';

class RowBloc extends Bloc<RowEvent, RowState> {
  final RowBackendService _rowBackendSvc;
  final RowController _dataController;

  RowBloc({
    required RowInfo rowInfo,
    required RowController dataController,
  })  : _rowBackendSvc = RowBackendService(viewId: rowInfo.viewId),
        _dataController = dataController,
        super(RowState.initial(rowInfo, dataController.loadData())) {
    on<RowEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            await _startListening();
          },
          createRow: () {
            _rowBackendSvc.createRow(rowInfo.rowPB.id);
          },
          didReceiveCells: (cellByFieldId, reason) async {
            final cells = cellByFieldId.values
                .map((e) => GridCellEquatable(e.fieldInfo))
                .toList();
            emit(
              state.copyWith(
                cellByFieldId: cellByFieldId,
                cells: UnmodifiableListView(cells),
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
    _dataController.dispose();
    return super.close();
  }

  Future<void> _startListening() async {
    _dataController.addListener(
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
    RowsChangedReason reason,
  ) = _DidReceiveCells;
}

@freezed
class RowState with _$RowState {
  const factory RowState({
    required RowInfo rowInfo,
    required CellContextByFieldId cellByFieldId,
    required UnmodifiableListView<GridCellEquatable> cells,
    RowsChangedReason? changeReason,
  }) = _RowState;

  factory RowState.initial(
    RowInfo rowInfo,
    CellContextByFieldId cellByFieldId,
  ) =>
      RowState(
        rowInfo: rowInfo,
        cellByFieldId: cellByFieldId,
        cells: UnmodifiableListView(
          cellByFieldId.values
              .map((e) => GridCellEquatable(e.fieldInfo))
              .toList(),
        ),
      );
}

class GridCellEquatable extends Equatable {
  final FieldInfo _fieldContext;

  const GridCellEquatable(FieldInfo field) : _fieldContext = field;

  @override
  List<Object?> get props => [
        _fieldContext.id,
        _fieldContext.fieldType,
        _fieldContext.visibility,
        _fieldContext.width,
      ];
}
