import 'package:app_flowy/workspace/application/grid/field/field_listener.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'cell_service.dart';

part 'number_cell_bloc.freezed.dart';

class NumberCellBloc extends Bloc<NumberCellEvent, NumberCellState> {
  final GridCellContext<Cell> cellContext;
  final SingleFieldListener _fieldListener;

  NumberCellBloc({
    required this.cellContext,
  })  : _fieldListener = SingleFieldListener(fieldId: cellContext.fieldId),
        super(NumberCellState.initial(cellContext)) {
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
    cellContext.saveCellData(value.text);
    cellContext.reloadCellData();
  }

  @override
  Future<void> close() async {
    await _fieldListener.stop();
    return super.close();
  }

  void _startListening() {
    cellContext.onCellChanged((cell) {
      if (!isClosed) {
        add(NumberCellEvent.didReceiveCellUpdate(cell));
      }
    });

    _fieldListener.updateFieldNotifier?.addPublishListener((result) {
      result.fold(
        (field) => cellContext.reloadCellData(),
        (err) => Log.error(err),
      );
    });
    _fieldListener.start();
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
    required String content,
  }) = _NumberCellState;

  factory NumberCellState.initial(GridCellContext context) {
    return NumberCellState(content: context.getCellData().cell?.content ?? "");
  }
}
