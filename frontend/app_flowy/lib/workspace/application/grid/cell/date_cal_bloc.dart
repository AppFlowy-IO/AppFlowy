import 'package:app_flowy/workspace/application/grid/field/field_service.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/date_type_option.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:async';
import 'cell_service/cell_service.dart';
import 'package:dartz/dartz.dart';
import 'package:protobuf/protobuf.dart';
import 'package:fixnum/fixnum.dart' as $fixnum;
part 'date_cal_bloc.freezed.dart';

class DateCalBloc extends Bloc<DateCalEvent, DateCalState> {
  final GridDateCellContext cellContext;
  void Function()? _onCellChangedFn;

  DateCalBloc({
    required DateTypeOption dateTypeOption,
    required DateCellData? cellData,
    required this.cellContext,
  }) : super(DateCalState.initial(dateTypeOption, cellData)) {
    on<DateCalEvent>(
      (event, emit) async {
        await event.when(
          initial: () async => _startListening(),
          selectDay: (date) {
            _updateDateData(emit, date: date);
          },
          setCalFormat: (format) {
            emit(state.copyWith(format: format));
          },
          setFocusedDay: (focusedDay) {
            emit(state.copyWith(focusedDay: focusedDay));
          },
          didReceiveCellUpdate: (value) {},
          setIncludeTime: (includeTime) async {
            await _updateTypeOption(emit, includeTime: includeTime);
          },
          setDateFormat: (dateFormat) async {
            await _updateTypeOption(emit, dateFormat: dateFormat);
          },
          setTimeFormat: (timeFormat) async {
            await _updateTypeOption(emit, timeFormat: timeFormat);
          },
          setTime: (time) {
            _updateDateData(emit, time: time);
          },
        );
      },
    );
  }

  void _updateDateData(Emitter<DateCalState> emit, {DateTime? date, String? time}) {
    state.dateData.fold(
      () {
        var newDateData = DateCellPersistenceData(date: date ?? DateTime.now());
        if (time != null) {
          newDateData = newDateData.copyWith(time: time);
        }
        emit(state.copyWith(dateData: Some(newDateData)));
      },
      (dateData) {
        var newDateData = dateData;
        if (date != null && !isSameDay(newDateData.date, date)) {
          newDateData = newDateData.copyWith(date: date);
        }

        if (newDateData.time != time) {
          newDateData = newDateData.copyWith(time: time);
        }

        if (newDateData != dateData) {
          emit(state.copyWith(dateData: Some(newDateData)));
        }
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

  Future<void>? _updateTypeOption(
    Emitter<DateCalState> emit, {
    DateFormat? dateFormat,
    TimeFormat? timeFormat,
    bool? includeTime,
  }) async {
    state.dateTypeOption.freeze();
    final newDateTypeOption = state.dateTypeOption.rebuild((typeOption) {
      if (dateFormat != null) {
        typeOption.dateFormat = dateFormat;
      }

      if (timeFormat != null) {
        typeOption.timeFormat = timeFormat;
      }

      if (includeTime != null) {
        typeOption.includeTime = includeTime;
      }
    });

    final result = await FieldService.updateFieldTypeOption(
      gridId: cellContext.gridId,
      fieldId: cellContext.field.id,
      typeOptionData: newDateTypeOption.writeToBuffer(),
    );

    result.fold(
      (l) => emit(state.copyWith(dateTypeOption: newDateTypeOption)),
      (err) => Log.error(err),
    );
  }
}

@freezed
class DateCalEvent with _$DateCalEvent {
  const factory DateCalEvent.initial() = _Initial;
  const factory DateCalEvent.selectDay(DateTime day) = _SelectDay;
  const factory DateCalEvent.setCalFormat(CalendarFormat format) = _CalendarFormat;
  const factory DateCalEvent.setFocusedDay(DateTime day) = _FocusedDay;
  const factory DateCalEvent.setTimeFormat(TimeFormat timeFormat) = _TimeFormat;
  const factory DateCalEvent.setDateFormat(DateFormat dateFormat) = _DateFormat;
  const factory DateCalEvent.setIncludeTime(bool includeTime) = _IncludeTime;
  const factory DateCalEvent.setTime(String time) = _Time;
  const factory DateCalEvent.didReceiveCellUpdate(DateCellData data) = _DidReceiveCellUpdate;
}

@freezed
class DateCalState with _$DateCalState {
  const factory DateCalState({
    required DateTypeOption dateTypeOption,
    required CalendarFormat format,
    required DateTime focusedDay,
    required String time,
    required Option<FlowyError> inputTimeError,
    required Option<DateCellPersistenceData> dateData,
  }) = _DateCalState;

  factory DateCalState.initial(
    DateTypeOption dateTypeOption,
    DateCellData? cellData,
  ) {
    Option<DateCellPersistenceData> dateData = none();
    final time = cellData?.time ?? "";
    if (cellData != null) {
      final timestamp = $fixnum.Int64.parseInt(cellData.date).toInt();
      final selectedDay = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      dateData = Some(DateCellPersistenceData(date: selectedDay));
    }

    return DateCalState(
      dateTypeOption: dateTypeOption,
      format: CalendarFormat.month,
      focusedDay: DateTime.now(),
      dateData: dateData,
      time: time,
      inputTimeError: none(),
    );
  }
}
