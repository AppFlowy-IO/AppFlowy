import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart' show Cell, Field;
import 'package:flowy_sdk/protobuf/flowy-grid/date_type_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:async';
import 'cell_service.dart';
import 'package:dartz/dartz.dart';
import 'package:fixnum/fixnum.dart' as $fixnum;
part 'date_cal_bloc.freezed.dart';

class DateCalBloc extends Bloc<DateCalEvent, DateCalState> {
  final GridDefaultCellContext cellContext;
  void Function()? _onCellChangedFn;

  DateCalBloc({required this.cellContext}) : super(DateCalState.initial(cellContext)) {
    on<DateCalEvent>(
      (event, emit) async {
        await event.map(
          initial: (_Initial value) async {
            _startListening();
            await _loadDateTypeOption(emit);
          },
          selectDay: (_SelectDay value) {
            if (!isSameDay(state.selectedDay, value.day)) {
              _updateCellData(value.day);
              emit(state.copyWith(selectedDay: value.day));
            }
          },
          setCalFormat: (_CalendarFormat value) {
            emit(state.copyWith(format: value.format));
          },
          setFocusedDay: (_FocusedDay value) {
            emit(state.copyWith(focusedDay: value.day));
          },
          didReceiveCellUpdate: (_DidReceiveCellUpdate value) {},
          didReceiveFieldUpdate: (_DidReceiveFieldUpdate value) {
            emit(state.copyWith(field: value.field));
          },
          setIncludeTime: (_IncludeTime value) {
            emit(state.copyWith(includeTime: value.includeTime));
          },
          setDateFormat: (_DateFormat value) {},
          setTimeFormat: (_TimeFormat value) {},
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

  Future<void> _loadDateTypeOption(Emitter<DateCalState> emit) async {
    final result = await cellContext.getTypeOptionData();
    result.fold(
      (data) {
        final typeOptionData = DateTypeOption.fromBuffer(data);

        DateTime? selectedDay;
        final cellData = cellContext.getCellData()?.data;

        if (cellData != null) {
          final timestamp = $fixnum.Int64.parseInt(cellData).toInt();
          selectedDay = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        }

        emit(state.copyWith(
          typeOptinoData: some(typeOptionData),
          includeTime: typeOptionData.includeTime,
          selectedDay: selectedDay,
        ));
      },
      (err) => Log.error(err),
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
  const factory DateCalEvent.setCalFormat(CalendarFormat format) = _CalendarFormat;
  const factory DateCalEvent.setFocusedDay(DateTime day) = _FocusedDay;
  const factory DateCalEvent.setTimeFormat(TimeFormat value) = _TimeFormat;
  const factory DateCalEvent.setDateFormat(DateFormat value) = _DateFormat;
  const factory DateCalEvent.setIncludeTime(bool includeTime) = _IncludeTime;
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
    required bool includeTime,
    required Option<String> time,
    DateTime? selectedDay,
  }) = _DateCalState;

  factory DateCalState.initial(GridCellContext context) => DateCalState(
        field: context.field,
        typeOptinoData: none(),
        format: CalendarFormat.month,
        focusedDay: DateTime.now(),
        includeTime: false,
        time: none(),
      );
}
