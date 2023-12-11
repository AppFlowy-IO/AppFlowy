import 'dart:async';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/application/cell/date_cell_service.dart';
import 'package:appflowy/plugins/database_view/application/field/field_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:easy_localization/easy_localization.dart'
    show StringTranslateExtension;
import 'package:flowy_infra/time/duration.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:protobuf/protobuf.dart';

part 'date_cal_bloc.freezed.dart';

class DateCellCalendarBloc
    extends Bloc<DateCellCalendarEvent, DateCellCalendarState> {
  final DateCellBackendService _dateCellBackendService;
  final DateCellController cellController;
  void Function()? _onCellChangedFn;

  DateCellCalendarBloc({
    required DateTypeOptionPB dateTypeOptionPB,
    required DateCellDataPB? cellData,
    required this.cellController,
  })  : _dateCellBackendService = DateCellBackendService(
          viewId: cellController.viewId,
          fieldId: cellController.fieldId,
          rowId: cellController.rowId,
        ),
        super(DateCellCalendarState.initial(dateTypeOptionPB, cellData)) {
    on<DateCellCalendarEvent>(
      (event, emit) async {
        await event.when(
          initial: () async => _startListening(),
          didReceiveCellUpdate: (DateCellDataPB? cellData) {
            final dateCellData = _dateDataFromCellData(cellData);
            final endDay =
                dateCellData.isRange == state.isRange && dateCellData.isRange
                    ? dateCellData.endDateTime
                    : null;
            emit(
              state.copyWith(
                dateTime: dateCellData.dateTime,
                timeStr: dateCellData.timeStr,
                endDateTime: dateCellData.endDateTime,
                endTimeStr: dateCellData.endTimeStr,
                includeTime: dateCellData.includeTime,
                isRange: dateCellData.isRange,
                startDay: dateCellData.isRange ? dateCellData.dateTime : null,
                endDay: endDay,
                dateStr: dateCellData.dateStr,
                endDateStr: dateCellData.endDateStr,
              ),
            );
          },
          didReceiveTimeFormatError:
              (String? parseTimeError, String? parseEndTimeError) {
            emit(
              state.copyWith(
                parseTimeError: parseTimeError,
                parseEndTimeError: parseEndTimeError,
              ),
            );
          },
          selectDay: (date) async {
            if (state.isRange) {
              return;
            }
            await _updateDateData(date: date);
          },
          setIncludeTime: (includeTime) async {
            await _updateDateData(includeTime: includeTime);
          },
          setIsRange: (isRange) async {
            await _updateDateData(isRange: isRange);
          },
          setTime: (timeStr) async {
            emit(state.copyWith(timeStr: timeStr));
            await _updateDateData(timeStr: timeStr);
          },
          selectDateRange: (DateTime? start, DateTime? end) async {
            if (end == null && state.startDay != null && state.endDay == null) {
              final (newStart, newEnd) = state.startDay!.isBefore(start!)
                  ? (state.startDay!, start)
                  : (start, state.startDay!);
              emit(
                state.copyWith(
                  startDay: null,
                  endDay: null,
                ),
              );
              await _updateDateData(
                date: newStart.date,
                endDate: newEnd.date,
              );
            } else if (end == null) {
              emit(
                state.copyWith(
                  startDay: start,
                  endDay: null,
                ),
              );
            } else {
              await _updateDateData(
                date: start!.date,
                endDate: end.date,
              );
            }
          },
          setStartDay: (DateTime startDay) async {
            if (state.endDay == null) {
              emit(
                state.copyWith(
                  startDay: startDay,
                ),
              );
            } else if (startDay.isAfter(state.endDay!)) {
              emit(
                state.copyWith(
                  startDay: startDay,
                  endDay: null,
                ),
              );
            } else {
              emit(
                state.copyWith(
                  startDay: startDay,
                ),
              );
              _updateDateData(date: startDay.date, endDate: state.endDay!.date);
            }
          },
          setEndDay: (DateTime endDay) async {
            if (state.startDay == null) {
              emit(
                state.copyWith(
                  endDay: endDay,
                ),
              );
            } else if (endDay.isBefore(state.startDay!)) {
              emit(
                state.copyWith(
                  startDay: null,
                  endDay: endDay,
                ),
              );
            } else {
              emit(
                state.copyWith(
                  endDay: endDay,
                ),
              );
              _updateDateData(date: state.startDay!.date, endDate: endDay.date);
            }
          },
          setEndTime: (String endTime) async {
            emit(state.copyWith(endTimeStr: endTime));
            await _updateDateData(endTimeStr: endTime);
          },
          setDateFormat: (dateFormat) async {
            await _updateTypeOption(emit, dateFormat: dateFormat);
          },
          setTimeFormat: (timeFormat) async {
            await _updateTypeOption(emit, timeFormat: timeFormat);
          },
          clearDate: () async {
            await _clearDate();
          },
        );
      },
    );
  }

  Future<void> _updateDateData({
    DateTime? date,
    String? timeStr,
    DateTime? endDate,
    String? endTimeStr,
    bool? includeTime,
    bool? isRange,
  }) async {
    // make sure that not both date and time are updated at the same time
    assert(
      !(date != null && timeStr != null) ||
          !(endDate != null && endTimeStr != null),
    );

    // if not updating the time, use the old time in the state
    final String? newTime = timeStr ?? state.timeStr;
    DateTime? newDate;
    if (timeStr != null && timeStr.isNotEmpty) {
      newDate = state.dateTime ?? DateTime.now();
    } else {
      newDate = _utcToLocalAndAddCurrentTime(date);
    }

    // if not updating the time, use the old time in the state
    final String? newEndTime = endTimeStr ?? state.endTimeStr;
    DateTime? newEndDate;
    if (endTimeStr != null && endTimeStr.isNotEmpty) {
      newEndDate = state.endDateTime ?? DateTime.now();
    } else {
      newEndDate = _utcToLocalAndAddCurrentTime(endDate);
    }

    final result = await _dateCellBackendService.update(
      date: newDate,
      time: newTime,
      endDate: newEndDate,
      endTime: newEndTime,
      includeTime: includeTime ?? state.includeTime,
      isRange: isRange ?? state.isRange,
    );

    result.fold(
      (_) {
        if (!isClosed &&
            (state.parseEndTimeError != null || state.parseTimeError != null)) {
          add(
            const DateCellCalendarEvent.didReceiveTimeFormatError(null, null),
          );
        }
      },
      (err) {
        switch (err.code) {
          case ErrorCode.InvalidDateTimeFormat:
            if (isClosed) {
              return;
            }
            // to determine which textfield should show error
            final (startError, endError) = newDate != null
                ? (timeFormatPrompt(err), null)
                : (null, timeFormatPrompt(err));
            add(
              DateCellCalendarEvent.didReceiveTimeFormatError(
                startError,
                endError,
              ),
            );
            break;
          default:
            Log.error(err);
        }
      },
    );
  }

  Future<void> _clearDate() async {
    final result = await _dateCellBackendService.clear();
    result.fold(
      (_) {
        if (isClosed) {
          return;
        }

        add(
          const DateCellCalendarEvent.didReceiveTimeFormatError(null, null),
        );
      },
      (err) => Log.error(err),
    );
  }

  DateTime? _utcToLocalAndAddCurrentTime(DateTime? date) {
    if (date == null) {
      return null;
    }
    final now = DateTime.now();
    // the incoming date is Utc. This trick converts it into Local
    // and add the current time. The time may be overwritten by
    // explicitly provided time string in the backend though
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
    return switch (state.dateTypeOptionPB.timeFormat) {
      TimeFormatPB.TwelveHour =>
        "${LocaleKeys.grid_field_invalidTimeFormat.tr()}. e.g. 01:00 PM",
      TimeFormatPB.TwentyFourHour =>
        "${LocaleKeys.grid_field_invalidTimeFormat.tr()}. e.g. 13:00",
      _ => "",
    };
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
    String? parseTimeError,
    String? parseEndTimeError,
  ) = _DidReceiveTimeFormatError;

  // date cell data is modified
  const factory DateCellCalendarEvent.selectDay(DateTime day) = _SelectDay;
  const factory DateCellCalendarEvent.selectDateRange(
    DateTime? start,
    DateTime? end,
  ) = _SelectDateRange;
  const factory DateCellCalendarEvent.setStartDay(
    DateTime startDay,
  ) = _SetStartDay;
  const factory DateCellCalendarEvent.setEndDay(
    DateTime endDay,
  ) = _SetEndDay;
  const factory DateCellCalendarEvent.setTime(String time) = _Time;
  const factory DateCellCalendarEvent.setEndTime(String endTime) = _EndTime;
  const factory DateCellCalendarEvent.setIncludeTime(bool includeTime) =
      _IncludeTime;
  const factory DateCellCalendarEvent.setIsRange(bool isRange) = _IsRange;

  // date field type options are modified
  const factory DateCellCalendarEvent.setTimeFormat(TimeFormatPB timeFormat) =
      _TimeFormat;
  const factory DateCellCalendarEvent.setDateFormat(DateFormatPB dateFormat) =
      _DateFormat;

  const factory DateCellCalendarEvent.clearDate() = _ClearDate;
}

@freezed
class DateCellCalendarState with _$DateCellCalendarState {
  const factory DateCellCalendarState({
    // the date field's type option
    required DateTypeOptionPB dateTypeOptionPB,

    // used when selecting a date range
    required DateTime? startDay,
    required DateTime? endDay,

    // cell data from the backend
    required DateTime? dateTime,
    required DateTime? endDateTime,
    required String? timeStr,
    required String? endTimeStr,
    required bool includeTime,
    required bool isRange,
    required String? dateStr,
    required String? endDateStr,

    // error and hint text
    required String? parseTimeError,
    required String? parseEndTimeError,
    required String timeHintText,
  }) = _DateCellCalendarState;

  factory DateCellCalendarState.initial(
    DateTypeOptionPB dateTypeOptionPB,
    DateCellDataPB? cellData,
  ) {
    final dateCellData = _dateDataFromCellData(cellData);
    return DateCellCalendarState(
      dateTypeOptionPB: dateTypeOptionPB,
      startDay: dateCellData.isRange ? dateCellData.dateTime : null,
      endDay: dateCellData.isRange ? dateCellData.endDateTime : null,
      dateTime: dateCellData.dateTime,
      endDateTime: dateCellData.endDateTime,
      timeStr: dateCellData.timeStr,
      endTimeStr: dateCellData.endTimeStr,
      dateStr: dateCellData.dateStr,
      endDateStr: dateCellData.endDateStr,
      includeTime: dateCellData.includeTime,
      isRange: dateCellData.isRange,
      parseTimeError: null,
      parseEndTimeError: null,
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

DateCellData _dateDataFromCellData(
  DateCellDataPB? cellData,
) {
  // a null DateCellDataPB may be returned, indicating that all the fields are
  // their default values: empty strings and false booleans
  if (cellData == null) {
    return DateCellData(
      dateTime: null,
      endDateTime: null,
      timeStr: null,
      endTimeStr: null,
      includeTime: false,
      isRange: false,
      dateStr: null,
      endDateStr: null,
    );
  }

  DateTime? dateTime;
  String? timeStr;
  DateTime? endDateTime;
  String? endTimeStr;

  String? endDateStr;
  if (cellData.hasTimestamp()) {
    final timestamp = cellData.timestamp * 1000;
    dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
    timeStr = cellData.time;
    if (cellData.hasEndTimestamp()) {
      final endTimestamp = cellData.endTimestamp * 1000;
      endDateTime = DateTime.fromMillisecondsSinceEpoch(endTimestamp.toInt());
      endTimeStr = cellData.endTime;
    }
  }
  final bool includeTime = cellData.includeTime;
  final bool isRange = cellData.isRange;

  if (cellData.isRange) {
    endDateStr = cellData.endDate;
  }
  final String dateStr = cellData.date;

  return DateCellData(
    dateTime: dateTime,
    endDateTime: endDateTime,
    timeStr: timeStr,
    endTimeStr: endTimeStr,
    includeTime: includeTime,
    isRange: isRange,
    dateStr: dateStr,
    endDateStr: endDateStr,
  );
}

class DateCellData {
  final DateTime? dateTime;
  final DateTime? endDateTime;
  final String? timeStr;
  final String? endTimeStr;
  final bool includeTime;
  final bool isRange;
  final String? dateStr;
  final String? endDateStr;

  DateCellData({
    required this.dateTime,
    required this.endDateTime,
    required this.timeStr,
    required this.endTimeStr,
    required this.includeTime,
    required this.isRange,
    required this.dateStr,
    required this.endDateStr,
  });
}
