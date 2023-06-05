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
    required final RowInfo rowInfo,
    required final RowController dataController,
  })  : _rowBackendSvc = RowBackendService(viewId: rowInfo.viewId),
        _dataController = dataController,
        super(RowState.initial(rowInfo, dataController.loadData())) {
    on<RowEvent>(
      (final event, final emit) async {
        await event.when(
          initial: () async {
            await _startListening();
          },
          createRow: () {
            _rowBackendSvc.createRow(rowInfo.rowPB.id);
          },
          didReceiveCells: (final cellByFieldId, final reason) async {
            final cells = cellByFieldId.values
                .map((final e) => GridCellEquatable(e.fieldInfo))
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
      onRowChanged: (final cells, final reason) {
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
    final CellByFieldId cellsByFieldId,
    final RowsChangedReason reason,
  ) = _DidReceiveCells;
}

@freezed
class RowState with _$RowState {
  const factory RowState({
    required final RowInfo rowInfo,
    required final CellByFieldId cellByFieldId,
    required final UnmodifiableListView<GridCellEquatable> cells,
    final RowsChangedReason? changeReason,
  }) = _RowState;

  factory RowState.initial(final RowInfo rowInfo, final CellByFieldId cellByFieldId) =>
      RowState(
        rowInfo: rowInfo,
        cellByFieldId: cellByFieldId,
        cells: UnmodifiableListView(
          cellByFieldId.values
              .map((final e) => GridCellEquatable(e.fieldInfo))
              .toList(),
        ),
      );
}

class GridCellEquatable extends Equatable {
  final FieldInfo _fieldContext;

  const GridCellEquatable(final FieldInfo field) : _fieldContext = field;

  @override
  List<Object?> get props => [
        _fieldContext.id,
        _fieldContext.fieldType,
        _fieldContext.visibility,
        _fieldContext.width,
      ];
}
