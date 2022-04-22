import 'package:app_flowy/workspace/application/grid/cell/cell_listener.dart';
import 'package:app_flowy/workspace/application/grid/field/field_listener.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'cell_service.dart';

part 'number_cell_bloc.freezed.dart';

class NumberCellBloc extends Bloc<NumberCellEvent, NumberCellState> {
  final CellService _service;
  final CellListener _cellListener;
  final SingleFieldListener _fieldListener;

  NumberCellBloc({
    required GridCellDataContext cellDataContext,
  })  : _service = CellService(),
        _cellListener = CellListener(rowId: cellDataContext.rowId, fieldId: cellDataContext.fieldId),
        _fieldListener = SingleFieldListener(fieldId: cellDataContext.fieldId),
        super(NumberCellState.initial(cellDataContext.cellData)) {
    on<NumberCellEvent>(
      (event, emit) async {
        await event.map(
          initial: (_Initial value) async {
            _startListening();
          },
          didReceiveCellUpdate: (_DidReceiveCellUpdate value) {
            emit(state.copyWith(content: value.cell.content));
          },
          updateCell: (_UpdateCell value) async {
            await _updateCellValue(value, emit);
          },
        );
      },
    );
  }

  Future<void> _updateCellValue(_UpdateCell value, Emitter<NumberCellState> emit) async {
    final result = await _service.updateCell(
      gridId: state.cellData.gridId,
      fieldId: state.cellData.field.id,
      rowId: state.cellData.rowId,
      data: value.text,
    );
    result.fold(
      (field) => _getCellData(),
      (err) => Log.error(err),
    );
  }

  @override
  Future<void> close() async {
    await _cellListener.stop();
    await _fieldListener.stop();
    return super.close();
  }

  void _startListening() {
    _cellListener.updateCellNotifier?.addPublishListener((result) {
      result.fold(
        (notificationData) async {
          await _getCellData();
        },
        (err) => Log.error(err),
      );
    });
    _cellListener.start();

    _fieldListener.updateFieldNotifier?.addPublishListener((result) {
      result.fold(
        (field) => _getCellData(),
        (err) => Log.error(err),
      );
    });
    _fieldListener.start();
  }

  Future<void> _getCellData() async {
    final result = await _service.getCell(
      gridId: state.cellData.gridId,
      fieldId: state.cellData.field.id,
      rowId: state.cellData.rowId,
    );

    if (isClosed) {
      return;
    }
    result.fold(
      (cell) => add(NumberCellEvent.didReceiveCellUpdate(cell)),
      (err) => Log.error(err),
    );
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
    required GridCell cellData,
    required String content,
  }) = _NumberCellState;

  factory NumberCellState.initial(GridCell cellData) {
    return NumberCellState(cellData: cellData, content: cellData.cell?.content ?? "");
  }
}
