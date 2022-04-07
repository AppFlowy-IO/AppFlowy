import 'package:app_flowy/workspace/application/grid/cell_bloc/cell_listener.dart';
import 'package:app_flowy/workspace/application/grid/row/row_service.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'cell_service.dart';

part 'number_cell_bloc.freezed.dart';

class NumberCellBloc extends Bloc<NumberCellEvent, NumberCellState> {
  final CellService _service;
  final CellListener _listener;

  NumberCellBloc({
    required CellData cellData,
  })  : _service = CellService(),
        _listener = CellListener(rowId: cellData.rowId, fieldId: cellData.field.id),
        super(NumberCellState.initial(cellData)) {
    on<NumberCellEvent>(
      (event, emit) async {
        await event.map(
          initial: (_Initial value) async {
            _startListening();
          },
          didReceiveCellUpdate: (_DidReceiveCellUpdate value) {
            emit(state.copyWith(content: value.cell.content));
          },
          updateCell: (_UpdateCell value) {
            _updateCellValue(value, emit);
          },
        );
      },
    );
  }

  void _updateCellValue(_UpdateCell value, Emitter<NumberCellState> emit) {
    final number = num.tryParse(value.text);
    if (number == null) {
      emit(state.copyWith(content: ""));
    } else {
      _service.updateCell(
        gridId: state.cellData.gridId,
        fieldId: state.cellData.field.id,
        rowId: state.cellData.rowId,
        data: value.text,
      );
    }
  }

  @override
  Future<void> close() async {
    await _listener.stop();
    return super.close();
  }

  void _startListening() {
    _listener.updateCellNotifier.addPublishListener((result) {
      result.fold(
        (notificationData) async {
          final result = await _service.getCell(
            gridId: state.cellData.gridId,
            fieldId: state.cellData.field.id,
            rowId: state.cellData.rowId,
          );
          result.fold(
            (cell) => add(NumberCellEvent.didReceiveCellUpdate(cell)),
            (err) => Log.error(err),
          );
        },
        (err) => Log.error(err),
      );
    });
    _listener.start();
  }
}

@freezed
class NumberCellEvent with _$NumberCellEvent {
  const factory NumberCellEvent.initial() = _Initial;
  const factory NumberCellEvent.updateCell(String text) = _UpdateCell;
  const factory NumberCellEvent.didReceiveCellUpdate(Cell cell) = _DidReceiveCellUpdate;
}

@freezed
class NumberCellState with _$NumberCellState {
  const factory NumberCellState({
    required CellData cellData,
    required String content,
  }) = _NumberCellState;

  factory NumberCellState.initial(CellData cellData) {
    return NumberCellState(cellData: cellData, content: cellData.cell?.content ?? "");
  }
}
