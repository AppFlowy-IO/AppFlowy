import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart' show Cell, Field;
import 'package:flowy_sdk/protobuf/flowy-grid/date_type_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:async';
import 'cell_service.dart';
import 'package:dartz/dartz.dart';
part 'date_cal_bloc.freezed.dart';

class DateCalBloc extends Bloc<DateCalEvent, DateCalState> {
  final GridDefaultCellContext cellContext;
  void Function()? _onCellChangedFn;

  DateCalBloc({required this.cellContext}) : super(DateCalState.initial(cellContext)) {
    on<DateCalEvent>(
      (event, emit) async {
        event.map(
          initial: (_Initial value) {
            _startListening();
          },
          selectDay: (_SelectDay value) {
            if (!isSameDay(state.selectedDay, value.day)) {
              _updateCellData(value.day);
              emit(state.copyWith(selectedDay: value.day));
            }
          },
          setFormat: (_CalendarFormat value) {
            emit(state.copyWith(format: value.format));
          },
          setFocusedDay: (_FocusedDay value) {
            emit(state.copyWith(focusedDay: value.day));
          },
          didReceiveCellUpdate: (_DidReceiveCellUpdate value) {},
          didReceiveFieldUpdate: (_DidReceiveFieldUpdate value) {
            emit(state.copyWith(field: value.field));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    if (_onCellChangedFn != null) {
      cellContext.removeListener(_onCellChangedFn!);
      _onCellChangedFn = null;
    }
    cellContext.dispose();
    return super.close();
  }

  void _startListening() {
    _onCellChangedFn = cellContext.startListening(
      onCellChanged: ((cell) {
        if (!isClosed) {
          add(DateCalEvent.didReceiveCellUpdate(cell));
        }
      }),
    );
  }

  void _updateCellData(DateTime day) {
    final data = day.millisecondsSinceEpoch ~/ 1000;
    cellContext.saveCellData(data.toString());
  }
}

@freezed
class DateCalEvent with _$DateCalEvent {
  const factory DateCalEvent.initial() = _Initial;
  const factory DateCalEvent.selectDay(DateTime day) = _SelectDay;
  const factory DateCalEvent.setFormat(CalendarFormat format) = _CalendarFormat;
  const factory DateCalEvent.setFocusedDay(DateTime day) = _FocusedDay;
  const factory DateCalEvent.didReceiveCellUpdate(Cell cell) = _DidReceiveCellUpdate;
  const factory DateCalEvent.didReceiveFieldUpdate(Field field) = _DidReceiveFieldUpdate;
}

@freezed
class DateCalState with _$DateCalState {
  const factory DateCalState({
    required Field field,
    required Option<DateTypeOption> typeOptinoData,
    required CalendarFormat format,
    required DateTime focusedDay,
    DateTime? selectedDay,
  }) = _DateCalState;

  factory DateCalState.initial(GridCellContext context) => DateCalState(
        field: context.field,
        typeOptinoData: none(),
        format: CalendarFormat.month,
        focusedDay: DateTime.now(),
      );
}
