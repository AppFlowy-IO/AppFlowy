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
  final String groupFieldId;
  final RowFFIService _rowService;
  final CardDataController _dataController;

  BoardCardBloc({
    required this.groupFieldId,
    required String gridId,
    required CardDataController dataController,
    required bool isEditing,
  })  : _rowService = RowFFIService(
          gridId: gridId,
          blockId: dataController.rowPB.blockId,
        ),
        _dataController = dataController,
        super(
          BoardCardState.initial(
            dataController.rowPB,
            _makeCells(groupFieldId, dataController.loadData()),
            isEditing,
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
          setIsEditing: (bool isEditing) {
            emit(state.copyWith(isEditing: isEditing));
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
        state.cells.map((cell) => cell.identifier.fieldInfo).toList(),
      ),
      rowPB: state.rowPB,
      visible: true,
    );
  }

  Future<void> _startListening() async {
    _dataController.addListener(
      onRowChanged: (cellMap, reason) {
        if (!isClosed) {
          final cells = _makeCells(groupFieldId, cellMap);
          add(BoardCardEvent.didReceiveCells(cells, reason));
        }
      },
    );
  }
}

List<BoardCellEquatable> _makeCells(
    String groupFieldId, GridCellMap originalCellMap) {
  List<BoardCellEquatable> cells = [];
  for (final entry in originalCellMap.entries) {
    // Filter out the cell if it's fieldId equal to the groupFieldId
    if (entry.value.fieldId != groupFieldId) {
      cells.add(BoardCellEquatable(entry.value));
    }
  }
  return cells;
}

@freezed
class BoardCardEvent with _$BoardCardEvent {
  const factory BoardCardEvent.initial() = _InitialRow;
  const factory BoardCardEvent.setIsEditing(bool isEditing) = _IsEditing;
  const factory BoardCardEvent.didReceiveCells(
    List<BoardCellEquatable> cells,
    RowsChangedReason reason,
  ) = _DidReceiveCells;
}

@freezed
class BoardCardState with _$BoardCardState {
  const factory BoardCardState({
    required RowPB rowPB,
    required List<BoardCellEquatable> cells,
    required bool isEditing,
    RowsChangedReason? changeReason,
  }) = _BoardCardState;

  factory BoardCardState.initial(
    RowPB rowPB,
    List<BoardCellEquatable> cells,
    bool isEditing,
  ) =>
      BoardCardState(
        rowPB: rowPB,
        cells: cells,
        isEditing: isEditing,
      );
}

class BoardCellEquatable extends Equatable {
  final GridCellIdentifier identifier;

  const BoardCellEquatable(this.identifier);

  @override
  List<Object?> get props {
    return [
      identifier.fieldInfo.id,
      identifier.fieldInfo.fieldType,
      identifier.fieldInfo.visibility,
      identifier.fieldInfo.width,
    ];
  }
}
