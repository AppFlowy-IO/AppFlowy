import 'dart:collection';
import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:app_flowy/plugins/grid/application/row/row_cache.dart';
import 'package:app_flowy/plugins/grid/application/row/row_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/block_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';

import 'card_data_controller.dart';

part 'card_bloc.freezed.dart';

class BoardCardBloc extends Bloc<BoardCardEvent, BoardCardState> {
  final String fieldId;
  final RowFFIService _rowService;
  final CardDataController _dataController;

  BoardCardBloc({
    required this.fieldId,
    required String gridId,
    required CardDataController dataController,
  })  : _rowService = RowFFIService(
          gridId: gridId,
          blockId: dataController.rowPB.blockId,
        ),
        _dataController = dataController,
        super(
          BoardCardState.initial(
            dataController.rowPB,
            _makeCells(fieldId, dataController.loadData()),
          ),
        ) {
    on<BoardCardEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            await _startListening();
          },
          didReceiveCells: (cells, reason) async {
            emit(state.copyWith(
              cells: cells,
              changeReason: reason,
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
      fields: UnmodifiableListView(
        state.cells.map((cell) => cell.identifier.field).toList(),
      ),
      rowPB: state.rowPB,
    );
  }

  Future<void> _startListening() async {
    _dataController.addListener(
      onRowChanged: (cellMap, reason) {
        if (!isClosed) {
          final cells = _makeCells(fieldId, cellMap);
          add(BoardCardEvent.didReceiveCells(cells, reason));
        }
      },
    );
  }
}

UnmodifiableListView<BoardCellEquatable> _makeCells(
    String fieldId, GridCellMap originalCellMap) {
  List<BoardCellEquatable> cells = [];
  for (final entry in originalCellMap.entries) {
    if (entry.value.fieldId != fieldId) {
      cells.add(BoardCellEquatable(entry.value));
    }
  }
  return UnmodifiableListView(cells);
}

@freezed
class BoardCardEvent with _$BoardCardEvent {
  const factory BoardCardEvent.initial() = _InitialRow;
  const factory BoardCardEvent.didReceiveCells(
    UnmodifiableListView<BoardCellEquatable> cells,
    RowsChangedReason reason,
  ) = _DidReceiveCells;
}

@freezed
class BoardCardState with _$BoardCardState {
  const factory BoardCardState({
    required RowPB rowPB,
    required UnmodifiableListView<BoardCellEquatable> cells,
    RowsChangedReason? changeReason,
  }) = _BoardCardState;

  factory BoardCardState.initial(
          RowPB rowPB, UnmodifiableListView<BoardCellEquatable> cells) =>
      BoardCardState(
        rowPB: rowPB,
        cells: cells,
      );
}

class BoardCellEquatable extends Equatable {
  final GridCellIdentifier identifier;

  const BoardCellEquatable(this.identifier);

  @override
  List<Object?> get props => [
        identifier.field.id,
        identifier.field.fieldType,
        identifier.field.visibility,
        identifier.field.width,
      ];
}
