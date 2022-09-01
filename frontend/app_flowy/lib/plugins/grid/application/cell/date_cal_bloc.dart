import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/plugins/grid/application/field/field_service.dart';
import 'package:easy_localization/easy_localization.dart'
    show StringTranslateExtension;
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error-code/code.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/date_type_option.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/date_type_option_entities.pb.dart';
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
  final GridDateCellController cellController;
  void Function()? _onCellChangedFn;

  DateCalBloc({
    required DateTypeOptionPB dateTypeOptionPB,
    required DateCellDataPB? cellData,
    required this.cellController,
  }) : super(DateCalState.initial(dateTypeOptionPB, cellData)) {
    on<DateCalEvent>(
      (event, emit) async {
        await event.when(
          initial: () async => _startListening(),
          selectDay: (date) async {
            await _updateDateData(emit, date: date, time: state.time);
          },
          setCalFormat: (format) {
            emit(state.copyWith(format: format));
          },
          setFocusedDay: (focusedDay) {
            emit(state.copyWith(focusedDay: focusedDay));
          },
          didReceiveCellUpdate: (DateCellDataPB? cellData) {
            final calData = calDataFromCellData(cellData);
            final time =
                calData.foldRight("", (dateData, previous) => dateData.time);
            emit(state.copyWith(calData: calData, time: time));
          },
          setIncludeTime: (includeTime) async {
            await _updateTypeOption(emit, includeTime: includeTime);
          },
          setDateFormat: (dateFormat) async {
            await _updateTypeOption(emit, dateFormat: dateFormat);
          },
          setTimeFormat: (timeFormat) async {
            await _updateTypeOption(emit, timeFormat: timeFormat);
          },
          setTime: (time) async {
            if (state.calData.isSome()) {
              await _updateDateData(emit, time: time);
            }
          },
          didUpdateCalData:
              (Option<CalendarData> data, Option<String> timeFormatError) {
            emit(state.copyWith(
                calData: data, timeFormatError: timeFormatError));
          },
        );
      },
    );
  }

  Future<void> _updateDateData(Emitter<DateCalState> emit,
      {DateTime? date, String? time}) {
    final CalendarData newDateData = state.calData.fold(
      () => CalendarData(date: date ?? DateTime.now(), time: time),
      (dateData) {
        var newDateData = dateData;
        if (date != null && !isSameDay(newDateData.date, date)) {
          newDateData = newDateData.copyWith(date: date);
        }

        if (newDateData.time != time) {
          newDateData = newDateData.copyWith(time: time);
        }
        return newDateData;
      },
    );

    return _saveDateData(emit, newDateData);
  }

  Future<void> _saveDateData(
      Emitter<DateCalState> emit, CalendarData newCalData) async {
    if (state.calData == Some(newCalData)) {
      return;
    }

    updateCalData(
        Option<CalendarData> calData, Option<String> timeFormatError) {
      if (!isClosed) {
        add(DateCalEvent.didUpdateCalData(calData, timeFormatError));
      }
    }

    cellController.saveCellData(newCalData, resultCallback: (result) {
      result.fold(
        () => updateCalData(Some(newCalData), none()),
        (err) {
          switch (ErrorCode.valueOf(err.code)!) {
            case ErrorCode.InvalidDateTimeFormat:
              updateCalData(none(), Some(timeFormatPrompt(err)));
              break;
            default:
              Log.error(err);
          }
        },
      );
    });
  }

  String timeFormatPrompt(FlowyError error) {
    String msg = "${LocaleKeys.grid_field_invalidTimeFormat.tr()}. ";
    switch (state.dateTypeOptionPB.timeFormat) {
      case TimeFormat.TwelveHour:
        msg = "${msg}e.g. 01: 00 AM";
        break;
      case TimeFormat.TwentyFourHour:
        msg = "${msg}e.g. 13: 00";
        break;
      default:
        break;
    }
    return msg;
  }

  @override
  Future<void> close() async {
    if (_onCellChangedFn != null) {
      cellController.removeListener(_onCellChangedFn!);
      _onCellChangedFn = null;
    }
    cellController.dispose();
    return super.close();
  }

  void _startListening() {
    _onCellChangedFn = cellController.startListening(
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
    state.dateTypeOptionPB.freeze();
    final newDateTypeOption = state.dateTypeOptionPB.rebuild((typeOption) {
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
      gridId: cellController.gridId,
      fieldId: cellController.field.id,
      typeOptionData: newDateTypeOption.writeToBuffer(),
    );

    result.fold(
      (l) => emit(state.copyWith(
          dateTypeOptionPB: newDateTypeOption,
          timeHintText: _timeHintText(newDateTypeOption))),
      (err) => Log.error(err),
    );
  }
}

@freezed
class DateCalEvent with _$DateCalEvent {
  const factory DateCalEvent.initial() = _Initial;
  const factory DateCalEvent.selectDay(DateTime day) = _SelectDay;
  const factory DateCalEvent.setCalFormat(CalendarFormat format) =
      _CalendarFormat;
  const factory DateCalEvent.setFocusedDay(DateTime day) = _FocusedDay;
  const factory DateCalEvent.setTimeFormat(TimeFormat timeFormat) = _TimeFormat;
  const factory DateCalEvent.setDateFormat(DateFormat dateFormat) = _DateFormat;
  const factory DateCalEvent.setIncludeTime(bool includeTime) = _IncludeTime;
  const factory DateCalEvent.setTime(String time) = _Time;
  const factory DateCalEvent.didReceiveCellUpdate(DateCellDataPB? data) =
      _DidReceiveCellUpdate;
  const factory DateCalEvent.didUpdateCalData(
          Option<CalendarData> data, Option<String> timeFormatError) =
      _DidUpdateCalData;
}

@freezed
class DateCalState with _$DateCalState {
  const factory DateCalState({
    required DateTypeOptionPB dateTypeOptionPB,
    required CalendarFormat format,
    required DateTime focusedDay,
    required Option<String> timeFormatError,
    required Option<CalendarData> calData,
    required String? time,
    required String timeHintText,
  }) = _DateCalState;

  factory DateCalState.initial(
    DateTypeOptionPB dateTypeOptionPB,
    DateCellDataPB? cellData,
  ) {
    Option<CalendarData> calData = calDataFromCellData(cellData);
    final time = calData.foldRight("", (dateData, previous) => dateData.time);
    return DateCalState(
      dateTypeOptionPB: dateTypeOptionPB,
      format: CalendarFormat.month,
      focusedDay: DateTime.now(),
      time: time,
      calData: calData,
      timeFormatError: none(),
      timeHintText: _timeHintText(dateTypeOptionPB),
    );
  }
}

String _timeHintText(DateTypeOptionPB typeOption) {
  switch (typeOption.timeFormat) {
    case TimeFormat.TwelveHour:
      return LocaleKeys.document_date_timeHintTextInTwelveHour.tr();
    case TimeFormat.TwentyFourHour:
      return LocaleKeys.document_date_timeHintTextInTwentyFourHour.tr();
  }
  return "";
}

Option<CalendarData> calDataFromCellData(DateCellDataPB? cellData) {
  String? time = timeFromCellData(cellData);
  Option<CalendarData> calData = none();
  if (cellData != null) {
    final timestamp = cellData.timestamp * 1000;
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
    calData = Some(CalendarData(date: date, time: time));
  }
  return calData;
}

$fixnum.Int64 timestampFromDateTime(DateTime dateTime) {
  final timestamp = (dateTime.millisecondsSinceEpoch ~/ 1000);
  return $fixnum.Int64(timestamp);
}

String? timeFromCellData(DateCellDataPB? cellData) {
  String? time;
  if (cellData?.hasTime() ?? false) {
    time = cellData?.time;
  }
  return time;
}
