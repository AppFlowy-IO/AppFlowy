import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart' show Cell, Field;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'cell_service.dart';

part 'date_cell_bloc.freezed.dart';

class DateCellBloc extends Bloc<DateCellEvent, DateCellState> {
  final GridDefaultCellContext cellContext;

  DateCellBloc({required this.cellContext}) : super(DateCellState.initial(cellContext)) {
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
              content: value.cell.content,
            ));
          },
          didReceiveFieldUpdate: (_DidReceiveFieldUpdate value) {
            emit(state.copyWith(field: value.field));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    cellContext.dispose();
    return super.close();
  }

  void _startListening() {
    cellContext.onCellChanged((cell) {
      if (!isClosed) {
        add(DateCellEvent.didReceiveCellUpdate(cell));
      }
    });
  }

  void _updateCellData(DateTime day) {
    final data = day.millisecondsSinceEpoch ~/ 1000;
    cellContext.saveCellData(data.toString());
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
    required String content,
    required Field field,
    DateTime? selectedDay,
  }) = _DateCellState;

  factory DateCellState.initial(GridCellContext context) => DateCellState(
        field: context.field,
        content: context.getCellData()?.content ?? "",
      );
}
