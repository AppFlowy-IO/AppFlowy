import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy/plugins/database_view/application/field/field_service.dart';
import 'package:easy_localization/easy_localization.dart'
    show StringTranslateExtension;
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/date_type_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/date_type_option_entities.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:protobuf/protobuf.dart';

part 'date_cal_bloc.freezed.dart';

class DateCellCalendarBloc
    extends Bloc<DateCellCalendarEvent, DateCellCalendarState> {
  final DateCellController cellController;
  void Function()? _onCellChangedFn;

  DateCellCalendarBloc({
    required DateTypeOptionPB dateTypeOptionPB,
    required DateCellDataPB? cellData,
    required this.cellController,
  }) : super(DateCellCalendarState.initial(dateTypeOptionPB, cellData)) {
    on<DateCellCalendarEvent>(
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
            final dateCellData = calDataFromCellData(cellData);
            final time = dateCellData.foldRight(
                "", (dateData, previous) => dateData.time ?? '');
            emit(state.copyWith(dateCellData: dateCellData, time: time));
          },
          setIncludeTime: (includeTime) async {
            await _updateDateData(emit, includeTime: includeTime);
          },
          setDateFormat: (dateFormat) async {
            await _updateTypeOption(emit, dateFormat: dateFormat);
          },
          setTimeFormat: (timeFormat) async {
            await _updateTypeOption(emit, timeFormat: timeFormat);
          },
          setTime: (time) async {
            if (state.dateCellData.isSome()) {
              await _updateDateData(emit, time: time);
            }
          },
          didUpdateCalData:
              (Option<DateCellData> data, Option<String> timeFormatError) {
            emit(state.copyWith(
                dateCellData: data, timeFormatError: timeFormatError));
          },
        );
      },
    );
  }

  Future<void> _updateDateData(Emitter<DateCellCalendarState> emit,
      {DateTime? date, String? time, bool? includeTime}) {
    final DateCellData newDateData = state.dateCellData.fold(
      () => DateCellData(
        date: date ?? DateTime.now(),
        time: time,
        includeTime: includeTime ?? false,
      ),
      (dateData) {
        var newDateData = dateData;
        if (date != null && !isSameDay(newDateData.date, date)) {
          newDateData = newDateData.copyWith(date: date);
        }

        if (newDateData.time != time) {
          newDateData = newDateData.copyWith(time: time);
        }

        if (includeTime != null && newDateData.includeTime != includeTime) {
          newDateData = newDateData.copyWith(includeTime: includeTime);
        }

        return newDateData;
      },
    );

    return _saveDateData(emit, newDateData);
  }

  Future<void> _saveDateData(
      Emitter<DateCellCalendarState> emit, DateCellData newCalData) async {
    if (state.dateCellData == Some(newCalData)) {
      return;
    }

    updateCalData(
        Option<DateCellData> dateCellData, Option<String> timeFormatError) {
      if (!isClosed) {
        add(DateCellCalendarEvent.didUpdateCalData(
            dateCellData, timeFormatError));
      }
    }

    cellController.saveCellData(newCalData, onFinish: (result) {
      result.fold(
        () => updateCalData(Some(newCalData), none()),
        (err) {
          switch (ErrorCode.valueOf(err.code)!) {
            case ErrorCode.InvalidDateTimeFormat:
              updateCalData(state.dateCellData, Some(timeFormatPrompt(err)));
              break;
            default:
              Log.error(err);
          }
        },
      );
    });
  }

  String timeFormatPrompt(FlowyError error) {
    String msg = "${LocaleKeys.grid_field_invalidTimeFormat.tr()}.";
    switch (state.dateTypeOptionPB.timeFormat) {
      case TimeFormat.TwelveHour:
        msg = "$msg e.g. 01:00 PM";
        break;
      case TimeFormat.TwentyFourHour:
        msg = "$msg e.g. 13:00";
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
    await cellController.dispose();
    return super.close();
  }

  void _startListening() {
    _onCellChangedFn = cellController.startListening(
      onCellChanged: ((cell) {
        if (!isClosed) {
          add(DateCellCalendarEvent.didReceiveCellUpdate(cell));
        }
      }),
    );
  }

  Future<void>? _updateTypeOption(
    Emitter<DateCellCalendarState> emit, {
    DateFormat? dateFormat,
    TimeFormat? timeFormat,
  }) async {
    state.dateTypeOptionPB.freeze();
    final newDateTypeOption = state.dateTypeOptionPB.rebuild((typeOption) {
      if (dateFormat != null) {
        typeOption.dateFormat = dateFormat;
      }

      if (timeFormat != null) {
        typeOption.timeFormat = timeFormat;
      }
    });

    final result = await FieldBackendService.updateFieldTypeOption(
      viewId: cellController.viewId,
      fieldId: cellController.fieldInfo.id,
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
class DateCellCalendarEvent with _$DateCellCalendarEvent {
  const factory DateCellCalendarEvent.initial() = _Initial;
  const factory DateCellCalendarEvent.selectDay(DateTime day) = _SelectDay;
  const factory DateCellCalendarEvent.setCalFormat(CalendarFormat format) =
      _CalendarFormat;
  const factory DateCellCalendarEvent.setFocusedDay(DateTime day) = _FocusedDay;
  const factory DateCellCalendarEvent.setTimeFormat(TimeFormat timeFormat) =
      _TimeFormat;
  const factory DateCellCalendarEvent.setDateFormat(DateFormat dateFormat) =
      _DateFormat;
  const factory DateCellCalendarEvent.setIncludeTime(bool includeTime) =
      _IncludeTime;
  const factory DateCellCalendarEvent.setTime(String time) = _Time;
  const factory DateCellCalendarEvent.didReceiveCellUpdate(
      DateCellDataPB? data) = _DidReceiveCellUpdate;
  const factory DateCellCalendarEvent.didUpdateCalData(
          Option<DateCellData> data, Option<String> timeFormatError) =
      _DidUpdateCalData;
}

@freezed
class DateCellCalendarState with _$DateCellCalendarState {
  const factory DateCellCalendarState({
    required DateTypeOptionPB dateTypeOptionPB,
    required CalendarFormat format,
    required DateTime focusedDay,
    required Option<String> timeFormatError,
    required Option<DateCellData> dateCellData,
    required String? time,
    required String timeHintText,
  }) = _DateCellCalendarState;

  factory DateCellCalendarState.initial(
    DateTypeOptionPB dateTypeOptionPB,
    DateCellDataPB? cellData,
  ) {
    Option<DateCellData> dateCellData = calDataFromCellData(cellData);
    final time =
        dateCellData.foldRight("", (dateData, previous) => dateData.time ?? '');
    return DateCellCalendarState(
      dateTypeOptionPB: dateTypeOptionPB,
      format: CalendarFormat.month,
      focusedDay: DateTime.now(),
      time: time,
      dateCellData: dateCellData,
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
    default:
      return "";
  }
}

Option<DateCellData> calDataFromCellData(DateCellDataPB? cellData) {
  String? time = timeFromCellData(cellData);
  Option<DateCellData> dateData = none();
  if (cellData != null) {
    final timestamp = cellData.timestamp * 1000;
    final date = DateTime.fromMillisecondsSinceEpoch(
      timestamp.toInt(),
      isUtc: true,
    );
    dateData = Some(DateCellData(
      date: date,
      time: time,
      includeTime: cellData.includeTime,
    ));
  }
  return dateData;
}

String? timeFromCellData(DateCellDataPB? cellData) {
  if (cellData == null || !cellData.hasTime()) {
    return null;
  }

  return cellData.time;
}
