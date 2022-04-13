import 'package:app_flowy/workspace/application/grid/cell_bloc/cell_listener.dart';
import 'package:app_flowy/workspace/application/grid/field/field_listener.dart';
import 'package:app_flowy/workspace/application/grid/row/row_service.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart' show Cell, Field;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'cell_service.dart';

part 'date_cell_bloc.freezed.dart';

class DateCellBloc extends Bloc<DateCellEvent, DateCellState> {
  final CellService _service;
  final CellListener _cellListener;
  final FieldListener _fieldListener;

  DateCellBloc({required CellData cellData})
      : _service = CellService(),
        _cellListener = CellListener(rowId: cellData.rowId, fieldId: cellData.field.id),
        _fieldListener = FieldListener(fieldId: cellData.field.id),
        super(DateCellState.initial(cellData)) {
    on<DateCellEvent>(
      (event, emit) async {
        event.map(
          initial: (_InitialCell value) {
            _startListening();
          },
          selectDay: (_SelectDay value) {
            _updateCellData(value.day);
          },
          didReceiveCellUpdate: (_DidReceiveCellUpdate value) {
            emit(state.copyWith(
              cellData: state.cellData.copyWith(cell: value.cell),
              content: value.cell.content,
            ));
          },
          didReceiveFieldUpdate: (_DidReceiveFieldUpdate value) {
            emit(state.copyWith(field: value.field));
            _loadCellData();
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await _cellListener.stop();
    await _fieldListener.stop();
    return super.close();
  }

  void _startListening() {
    _cellListener.updateCellNotifier.addPublishListener((result) {
      result.fold(
        (notificationData) => _loadCellData(),
        (err) => Log.error(err),
      );
    });
    _cellListener.start();

    _fieldListener.updateFieldNotifier.addPublishListener((result) {
      result.fold(
        (field) => add(DateCellEvent.didReceiveFieldUpdate(field)),
        (err) => Log.error(err),
      );
    });
    _fieldListener.start();
  }

  Future<void> _loadCellData() async {
    final result = await _service.getCell(
      gridId: state.cellData.gridId,
      fieldId: state.cellData.field.id,
      rowId: state.cellData.rowId,
    );
    result.fold(
      (cell) {
        if (!isClosed) {
          add(DateCellEvent.didReceiveCellUpdate(cell));
        }
      },
      (err) => Log.error(err),
    );
  }

  void _updateCellData(DateTime day) {
    final data = day.millisecondsSinceEpoch ~/ 1000;
    _service.updateCell(
      gridId: state.cellData.gridId,
      fieldId: state.cellData.field.id,
      rowId: state.cellData.rowId,
      data: data.toString(),
    );
  }
}

@freezed
class DateCellEvent with _$DateCellEvent {
  const factory DateCellEvent.initial() = _InitialCell;
  const factory DateCellEvent.selectDay(DateTime day) = _SelectDay;
  const factory DateCellEvent.didReceiveCellUpdate(Cell cell) = _DidReceiveCellUpdate;
  const factory DateCellEvent.didReceiveFieldUpdate(Field field) = _DidReceiveFieldUpdate;
}

@freezed
class DateCellState with _$DateCellState {
  const factory DateCellState({
    required CellData cellData,
    required String content,
    required Field field,
    DateTime? selectedDay,
  }) = _DateCellState;

  factory DateCellState.initial(CellData cellData) => DateCellState(
        cellData: cellData,
        field: cellData.field,
        content: cellData.cell?.content ?? "",
      );
}
