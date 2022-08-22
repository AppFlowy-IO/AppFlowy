import 'dart:collection';
import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'row_cache.dart';
import 'row_data_controller.dart';
import 'row_service.dart';

part 'row_bloc.freezed.dart';

class RowBloc extends Bloc<RowEvent, RowState> {
  final RowFFIService _rowService;
  final GridRowDataController _dataController;

  RowBloc({
    required RowInfo rowInfo,
    required GridRowDataController dataController,
  })  : _rowService = RowFFIService(
          gridId: rowInfo.gridId,
          blockId: rowInfo.rowPB.blockId,
        ),
        _dataController = dataController,
        super(RowState.initial(rowInfo, dataController.loadData())) {
    on<RowEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialRow value) async {
            await _startListening();
          },
          createRow: (_CreateRow value) {
            _rowService.createRow(rowInfo.rowPB.id);
          },
          didReceiveCells: (_DidReceiveCells value) async {
            final cells = value.gridCellMap.values
                .map((e) => GridCellEquatable(e.field))
                .toList();
            emit(state.copyWith(
              gridCellMap: value.gridCellMap,
              cells: UnmodifiableListView(cells),
              changeReason: value.reason,
            ));
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
      GridCellMap gridCellMap, RowsChangedReason reason) = _DidReceiveCells;
}

@freezed
class RowState with _$RowState {
  const factory RowState({
    required RowInfo rowInfo,
    required GridCellMap gridCellMap,
    required UnmodifiableListView<GridCellEquatable> cells,
    RowsChangedReason? changeReason,
  }) = _RowState;

  factory RowState.initial(RowInfo rowInfo, GridCellMap cellDataMap) =>
      RowState(
        rowInfo: rowInfo,
        gridCellMap: cellDataMap,
        cells: UnmodifiableListView(
          cellDataMap.values.map((e) => GridCellEquatable(e.field)).toList(),
        ),
      );
}

class GridCellEquatable extends Equatable {
  final FieldPB _field;

  const GridCellEquatable(FieldPB field) : _field = field;

  @override
  List<Object?> get props => [
        _field.id,
        _field.fieldType,
        _field.visibility,
        _field.width,
      ];
}
