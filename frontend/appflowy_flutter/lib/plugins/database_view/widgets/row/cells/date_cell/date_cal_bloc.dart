import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy/plugins/database_view/application/field/field_service.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pb.dart';
import 'package:easy_localization/easy_localization.dart'
    show StringTranslateExtension;
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:async';
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
          didReceiveCellUpdate: (DateCellDataPB? cellData) {
            final dateData = _dateDataFromCellData(cellData);
            emit(
              state.copyWith(
                dateTime: dateData.dateTime,
                time: dateData.time,
                includeTime: dateData.includeTime,
              ),
            );
          },
          didReceiveTimeFormatError: (String? timeFormatError) {
            emit(state.copyWith(timeFormatError: timeFormatError));
          },
          selectDay: (date) async {
            await _updateDateData(emit, date: date);
          },
          setIncludeTime: (includeTime) async {
            await _updateDateData(emit, includeTime: includeTime);
          },
          setTime: (time) async {
            await _updateDateData(emit, time: time);
          },
          setDateFormat: (dateFormat) async {
            await _updateTypeOption(emit, dateFormat: dateFormat);
          },
          setTimeFormat: (timeFormat) async {
            await _updateTypeOption(emit, timeFormat: timeFormat);
          },
          setCalFormat: (format) {
            emit(state.copyWith(format: format));
          },
          setFocusedDay: (focusedDay) {
            emit(state.copyWith(focusedDay: focusedDay));
          },
        );
      },
    );
  }

  Future<void> _updateDateData(
    Emitter<DateCellCalendarState> emit, {
    DateTime? date,
    String? time,
    bool? includeTime,
  }) async {
    // make sure that not both date and time are updated at the same time
    assert(
      date == null && time == null ||
          date == null && time != null ||
          date != null && time == null,
    );
    final String? newTime = time ?? state.time;
    DateTime? newDate = _utcToLocalAddTime(date);
    if (time != null && time.isNotEmpty) {
      newDate = state.dateTime ?? DateTime.now();
    }

    final DateCellData newDateData = DateCellData(
      dateTime: newDate,
      time: newTime,
      includeTime: includeTime ?? state.includeTime,
    );

    cellController.saveCellData(
      newDateData,
      onFinish: (result) {
        result.fold(
          () {
            if (!isClosed && state.timeFormatError != null) {
              add(const DateCellCalendarEvent.didReceiveTimeFormatError(null));
            }
          },
          (err) {
            switch (ErrorCode.valueOf(err.code)!) {
              case ErrorCode.InvalidDateTimeFormat:
                if (isClosed) return;
                add(
                  DateCellCalendarEvent.didReceiveTimeFormatError(
                    timeFormatPrompt(err),
                  ),
                );
                break;
              default:
                Log.error(err);
            }
          },
        );
      },
    );
  }

  DateTime? _utcToLocalAddTime(DateTime? date) {
    if (date == null) {
      return null;
    }
    final now = DateTime.now();
    // the incoming date is Utc. this trick converts it into Local
    // and add the current time, though the time may be overwritten by
    // explicitly provided time string
    return DateTime(
      date.year,
      date.month,
      date.day,
      now.hour,
      now.minute,
      now.second,
    );
  }

  String timeFormatPrompt(FlowyError error) {
    String msg = "${LocaleKeys.grid_field_invalidTimeFormat.tr()}.";
    switch (state.dateTypeOptionPB.timeFormat) {
      case TimeFormatPB.TwelveHour:
        msg = "$msg e.g. 01:00 PM";
        break;
      case TimeFormatPB.TwentyFourHour:
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
    DateFormatPB? dateFormat,
    TimeFormatPB? timeFormat,
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
      (l) => emit(
        state.copyWith(
          dateTypeOptionPB: newDateTypeOption,
          timeHintText: _timeHintText(newDateTypeOption),
        ),
      ),
      (err) => Log.error(err),
    );
  }
}

@freezed
class DateCellCalendarEvent with _$DateCellCalendarEvent {
  // initial event
  const factory DateCellCalendarEvent.initial() = _Initial;

  // notification that cell is updated in the backend
  const factory DateCellCalendarEvent.didReceiveCellUpdate(
    DateCellDataPB? data,
  ) = _DidReceiveCellUpdate;
  const factory DateCellCalendarEvent.didReceiveTimeFormatError(
    String? timeformatError,
  ) = _DidReceiveTimeFormatError;

  // table calendar's UI settings
  const factory DateCellCalendarEvent.setFocusedDay(DateTime day) = _FocusedDay;
  const factory DateCellCalendarEvent.setCalFormat(CalendarFormat format) =
      _CalendarFormat;

  // date cell data is modified
  const factory DateCellCalendarEvent.selectDay(DateTime day) = _SelectDay;
  const factory DateCellCalendarEvent.setTime(String time) = _Time;
  const factory DateCellCalendarEvent.setIncludeTime(bool includeTime) =
      _IncludeTime;

  // date field type options are modified
  const factory DateCellCalendarEvent.setTimeFormat(TimeFormatPB timeFormat) =
      _TimeFormat;
  const factory DateCellCalendarEvent.setDateFormat(DateFormatPB dateFormat) =
      _DateFormat;
}

@freezed
class DateCellCalendarState with _$DateCellCalendarState {
  const factory DateCellCalendarState({
    required DateTypeOptionPB dateTypeOptionPB,
    required CalendarFormat format,
    required DateTime focusedDay,
    required DateTime? dateTime,
    required String? time,
    required bool includeTime,
    required String? timeFormatError,
    required String timeHintText,
  }) = _DateCellCalendarState;

  factory DateCellCalendarState.initial(
    DateTypeOptionPB dateTypeOptionPB,
    DateCellDataPB? cellData,
  ) {
    final dateData = _dateDataFromCellData(cellData);
    return DateCellCalendarState(
      dateTypeOptionPB: dateTypeOptionPB,
      format: CalendarFormat.month,
      focusedDay: DateTime.now(),
      dateTime: dateData.dateTime,
      time: dateData.time,
      includeTime: dateData.includeTime,
      timeFormatError: null,
      timeHintText: _timeHintText(dateTypeOptionPB),
    );
  }
}

String _timeHintText(DateTypeOptionPB typeOption) {
  switch (typeOption.timeFormat) {
    case TimeFormatPB.TwelveHour:
      return LocaleKeys.document_date_timeHintTextInTwelveHour.tr();
    case TimeFormatPB.TwentyFourHour:
      return LocaleKeys.document_date_timeHintTextInTwentyFourHour.tr();
    default:
      return "";
  }
}

DateCellData _dateDataFromCellData(DateCellDataPB? cellData) {
  // a null DateCellDataPB may be returned, indicating that all the fields are
  // at their default values: empty strings and false booleans
  if (cellData == null) {
    return const DateCellData(includeTime: false);
  }

  DateTime? dateTime;
  String? time;
  if (cellData.hasTimestamp()) {
    final timestamp = cellData.timestamp * 1000;
    dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
    time = cellData.time;
  }
  final bool includeTime = cellData.includeTime;

  return DateCellData(dateTime: dateTime, time: time, includeTime: includeTime);
}
