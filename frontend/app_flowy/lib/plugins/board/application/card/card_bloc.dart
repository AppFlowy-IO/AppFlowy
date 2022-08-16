import 'dart:collection';
import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:app_flowy/plugins/grid/application/row/row_cache.dart';
import 'package:app_flowy/plugins/grid/application/row/row_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/block_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

import 'card_data_controller.dart';

part 'card_bloc.freezed.dart';

class BoardCardBloc extends Bloc<BoardCardEvent, BoardCardState> {
  final RowFFIService _rowService;
  final CardDataController _dataController;

  BoardCardBloc({
    required String gridId,
    required CardDataController dataController,
  })  : _rowService = RowFFIService(
          gridId: gridId,
          blockId: dataController.rowPB.blockId,
          rowId: dataController.rowPB.id,
        ),
        _dataController = dataController,
        super(BoardCardState.initial(
            dataController.rowPB, dataController.loadData())) {
    on<BoardCardEvent>(
      (event, emit) async {
        await event.map(
          initial: (_InitialRow value) async {
            await _startListening();
          },
          createRow: (_CreateRow value) {
            _rowService.createRow();
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

  RowInfo rowInfo() {
    return RowInfo(
      gridId: _rowService.gridId,
      blockId: _rowService.blockId,
      fields: UnmodifiableListView(
        state.cells.map((cell) => cell._field).toList(),
      ),
      rowPB: state.rowPB,
    );
  }

  Future<void> _startListening() async {
    _dataController.addListener(
      onRowChanged: (cells, reason) {
        if (!isClosed) {
          add(BoardCardEvent.didReceiveCells(cells, reason));
        }
      },
    );
  }
}

@freezed
class BoardCardEvent with _$BoardCardEvent {
  const factory BoardCardEvent.initial() = _InitialRow;
  const factory BoardCardEvent.createRow() = _CreateRow;
  const factory BoardCardEvent.didReceiveCells(
      GridCellMap gridCellMap, RowsChangedReason reason) = _DidReceiveCells;
}

@freezed
class BoardCardState with _$BoardCardState {
  const factory BoardCardState({
    required RowPB rowPB,
    required GridCellMap gridCellMap,
    required UnmodifiableListView<GridCellEquatable> cells,
    RowsChangedReason? changeReason,
  }) = _BoardCardState;

  factory BoardCardState.initial(RowPB rowPB, GridCellMap cellDataMap) =>
      BoardCardState(
        rowPB: rowPB,
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
