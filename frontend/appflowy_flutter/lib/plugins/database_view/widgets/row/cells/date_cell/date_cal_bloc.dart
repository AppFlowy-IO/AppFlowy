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
    required final DateTypeOptionPB dateTypeOptionPB,
    required final DateCellDataPB? cellData,
    required this.cellController,
  }) : super(DateCellCalendarState.initial(dateTypeOptionPB, cellData)) {
    on<DateCellCalendarEvent>(
      (final event, final emit) async {
        await event.when(
          initial: () async => _startListening(),
          selectDay: (final date) async {
            await _updateDateData(emit, date: date, time: state.time);
          },
          setCalFormat: (final format) {
            emit(state.copyWith(format: format));
          },
          setFocusedDay: (final focusedDay) {
            emit(state.copyWith(focusedDay: focusedDay));
          },
          didReceiveCellUpdate: (final DateCellDataPB? cellData) {
            final dateCellData = calDataFromCellData(cellData);
            final time = dateCellData.foldRight(
              "",
              (final dateData, final previous) => dateData.time ?? '',
            );
            emit(state.copyWith(dateCellData: dateCellData, time: time));
          },
          setIncludeTime: (final includeTime) async {
            await _updateDateData(emit, includeTime: includeTime);
          },
          setDateFormat: (final dateFormat) async {
            await _updateTypeOption(emit, dateFormat: dateFormat);
          },
          setTimeFormat: (final timeFormat) async {
            await _updateTypeOption(emit, timeFormat: timeFormat);
          },
          setTime: (final time) async {
            if (state.dateCellData.isSome()) {
              await _updateDateData(emit, time: time);
            }
          },
          didUpdateCalData: (
            final Option<DateCellData> data,
            final Option<String> timeFormatError,
          ) {
            emit(
              state.copyWith(
                dateCellData: data,
                timeFormatError: timeFormatError,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateDateData(
    final Emitter<DateCellCalendarState> emit, {
    final DateTime? date,
    final String? time,
    final bool? includeTime,
  }) {
    final DateCellData newDateData = state.dateCellData.fold(
      () {
        DateTime newDate = DateTime.now();
        if (date != null) {
          newDate = _utcToLocalAddTime(date);
        }
        return DateCellData(
          date: newDate,
          time: time,
          includeTime: includeTime ?? false,
        );
      },
      (final dateData) {
        var newDateData = dateData;
        if (date != null && !isSameDay(newDateData.date, date)) {
          newDateData = newDateData.copyWith(
            date: _utcToLocalAddTime(date),
          );
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
    final Emitter<DateCellCalendarState> emit,
    final DateCellData newCalData,
  ) async {
    if (state.dateCellData == Some(newCalData)) {
      return;
    }

    updateCalData(
      final Option<DateCellData> dateCellData,
      final Option<String> timeFormatError,
    ) {
      if (!isClosed) {
        add(
          DateCellCalendarEvent.didUpdateCalData(
            dateCellData,
            timeFormatError,
          ),
        );
      }
    }

    cellController.saveCellData(
      newCalData,
      onFinish: (final result) {
        result.fold(
          () => updateCalData(Some(newCalData), none()),
          (final err) {
            switch (ErrorCode.valueOf(err.code)!) {
              case ErrorCode.InvalidDateTimeFormat:
                updateCalData(state.dateCellData, Some(timeFormatPrompt(err)));
                break;
              default:
                Log.error(err);
            }
          },
        );
      },
    );
  }

  DateTime _utcToLocalAddTime(final DateTime date) {
    final now = DateTime.now();
    // the incoming date is Utc. this trick converts it into Local
    // and add the current time, though
    // the time may be overwritten by explicitly provided time string
    return DateTime(
      date.year,
      date.month,
      date.day,
      now.hour,
      now.minute,
      now.second,
    );
  }

  String timeFormatPrompt(final FlowyError error) {
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
      onCellChanged: ((final cell) {
        if (!isClosed) {
          add(DateCellCalendarEvent.didReceiveCellUpdate(cell));
        }
      }),
    );
  }

  Future<void>? _updateTypeOption(
    final Emitter<DateCellCalendarState> emit, {
    final DateFormat? dateFormat,
    final TimeFormat? timeFormat,
  }) async {
    state.dateTypeOptionPB.freeze();
    final newDateTypeOption =
        state.dateTypeOptionPB.rebuild((final typeOption) {
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
      (final l) => emit(
        state.copyWith(
          dateTypeOptionPB: newDateTypeOption,
          timeHintText: _timeHintText(newDateTypeOption),
        ),
      ),
      (final err) => Log.error(err),
    );
  }
}

@freezed
class DateCellCalendarEvent with _$DateCellCalendarEvent {
  const factory DateCellCalendarEvent.initial() = _Initial;
  const factory DateCellCalendarEvent.selectDay(final DateTime day) =
      _SelectDay;
  const factory DateCellCalendarEvent.setCalFormat(
    final CalendarFormat format,
  ) = _CalendarFormat;
  const factory DateCellCalendarEvent.setFocusedDay(final DateTime day) =
      _FocusedDay;
  const factory DateCellCalendarEvent.setTimeFormat(
    final TimeFormat timeFormat,
  ) = _TimeFormat;
  const factory DateCellCalendarEvent.setDateFormat(
    final DateFormat dateFormat,
  ) = _DateFormat;
  const factory DateCellCalendarEvent.setIncludeTime(final bool includeTime) =
      _IncludeTime;
  const factory DateCellCalendarEvent.setTime(final String time) = _Time;
  const factory DateCellCalendarEvent.didReceiveCellUpdate(
    final DateCellDataPB? data,
  ) = _DidReceiveCellUpdate;
  const factory DateCellCalendarEvent.didUpdateCalData(
    final Option<DateCellData> data,
    final Option<String> timeFormatError,
  ) = _DidUpdateCalData;
}

@freezed
class DateCellCalendarState with _$DateCellCalendarState {
  const factory DateCellCalendarState({
    required final DateTypeOptionPB dateTypeOptionPB,
    required final CalendarFormat format,
    required final DateTime focusedDay,
    required final Option<String> timeFormatError,
    required final Option<DateCellData> dateCellData,
    required final String? time,
    required final String timeHintText,
  }) = _DateCellCalendarState;

  factory DateCellCalendarState.initial(
    final DateTypeOptionPB dateTypeOptionPB,
    final DateCellDataPB? cellData,
  ) {
    final Option<DateCellData> dateCellData = calDataFromCellData(cellData);
    final time = dateCellData.foldRight(
      "",
      (final dateData, final previous) => dateData.time ?? '',
    );
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

String _timeHintText(final DateTypeOptionPB typeOption) {
  switch (typeOption.timeFormat) {
    case TimeFormat.TwelveHour:
      return LocaleKeys.document_date_timeHintTextInTwelveHour.tr();
    case TimeFormat.TwentyFourHour:
      return LocaleKeys.document_date_timeHintTextInTwentyFourHour.tr();
    default:
      return "";
  }
}

Option<DateCellData> calDataFromCellData(final DateCellDataPB? cellData) {
  final String? time = timeFromCellData(cellData);
  Option<DateCellData> dateData = none();
  if (cellData != null) {
    final timestamp = cellData.timestamp * 1000;
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
    dateData = Some(
      DateCellData(
        date: date,
        time: time,
        includeTime: cellData.includeTime,
      ),
    );
  }
  return dateData;
}

String? timeFromCellData(final DateCellDataPB? cellData) {
  if (cellData == null || !cellData.hasTime()) {
    return null;
  }

  return cellData.time;
}
