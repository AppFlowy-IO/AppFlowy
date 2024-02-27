import 'dart:async';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/domain/date_cell_service.dart';
import 'package:appflowy/plugins/database/domain/field_service.dart';
import 'package:appflowy/plugins/database/application/field/type_option/type_option_data_parser.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/user/application/reminder/reminder_extension.dart';
import 'package:appflowy/util/int64_extension.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/reminder_selector.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart'
    show StringTranslateExtension;
import 'package:fixnum/fixnum.dart';
import 'package:flowy_infra/time/duration.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nanoid/non_secure.dart';
import 'package:protobuf/protobuf.dart';

part 'date_cell_editor_bloc.freezed.dart';

class DateCellEditorBloc
    extends Bloc<DateCellEditorEvent, DateCellEditorState> {
  DateCellEditorBloc({
    required this.cellController,
    required ReminderBloc reminderBloc,
  })  : _reminderBloc = reminderBloc,
        _dateCellBackendService = DateCellBackendService(
          viewId: cellController.viewId,
          fieldId: cellController.fieldId,
          rowId: cellController.rowId,
        ),
        super(DateCellEditorState.initial(cellController, reminderBloc)) {
    _dispatch();
  }

  final DateCellBackendService _dateCellBackendService;
  final DateCellController cellController;
  final ReminderBloc _reminderBloc;
  void Function()? _onCellChangedFn;

  void _dispatch() {
    on<DateCellEditorEvent>(
      (event, emit) async {
        await event.when(
          initial: () async => _startListening(),
          didReceiveCellUpdate: (DateCellDataPB? cellData) {
            final dateCellData = _dateDataFromCellData(cellData);
            final endDay =
                dateCellData.isRange == state.isRange && dateCellData.isRange
                    ? dateCellData.endDateTime
                    : null;
            ReminderOption option = state.reminderOption;

            if (dateCellData.dateTime != null &&
                (state.reminderId?.isEmpty ?? true) &&
                (dateCellData.reminderId?.isNotEmpty ?? false) &&
                state.reminderOption != ReminderOption.none) {
              final date = state.reminderOption.withoutTime
                  ? dateCellData.dateTime!.withoutTime
                  : dateCellData.dateTime!;

              // Add Reminder
              _reminderBloc.add(
                ReminderEvent.addById(
                  reminderId: dateCellData.reminderId!,
                  objectId: cellController.viewId,
                  meta: {
                    ReminderMetaKeys.includeTime: true.toString(),
                    ReminderMetaKeys.rowId: cellController.rowId,
                  },
                  scheduledAt: Int64(
                    state.reminderOption
                            .fromDate(date)
                            .millisecondsSinceEpoch ~/
                        1000,
                  ),
                ),
              );
            }

            if ((dateCellData.reminderId?.isNotEmpty ?? false) &&
                dateCellData.dateTime != null) {
              if (option.requiresNoTime && dateCellData.includeTime) {
                option = ReminderOption.atTimeOfEvent;
              } else if (!option.withoutTime && !dateCellData.includeTime) {
                option = ReminderOption.onDayOfEvent;
              }

              final date = option.withoutTime
                  ? dateCellData.dateTime!.withoutTime
                  : dateCellData.dateTime!;

              final scheduledAt = option.fromDate(date);

              // Update Reminder
              _reminderBloc.add(
                ReminderEvent.update(
                  ReminderUpdate(
                    id: dateCellData.reminderId!,
                    scheduledAt: scheduledAt,
                    includeTime: true,
                  ),
                ),
              );
            }

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
                reminderId: dateCellData.reminderId,
                reminderOption: option,
              ),
            );
          },
          didReceiveTimeFormatError: (
            String? parseTimeError,
            String? parseEndTimeError,
          ) {
            emit(
              state.copyWith(
                parseTimeError: parseTimeError,
                parseEndTimeError: parseEndTimeError,
              ),
            );
          },
          selectDay: (date) async {
            if (!state.isRange) {
              await _updateDateData(date: date);
            }
          },
          setIncludeTime: (includeTime) async =>
              _updateDateData(includeTime: includeTime),
          setIsRange: (isRange) async => _updateDateData(isRange: isRange),
          setTime: (timeStr) async {
            emit(state.copyWith(timeStr: timeStr));
            await _updateDateData(timeStr: timeStr);
          },
          selectDateRange: (DateTime? start, DateTime? end) async {
            if (end == null && state.startDay != null && state.endDay == null) {
              final (newStart, newEnd) = state.startDay!.isBefore(start!)
                  ? (state.startDay!, start)
                  : (start, state.startDay!);

              emit(state.copyWith(startDay: null, endDay: null));

              await _updateDateData(date: newStart.date, endDate: newEnd.date);
            } else if (end == null) {
              emit(state.copyWith(startDay: start, endDay: null));
            } else {
              await _updateDateData(date: start!.date, endDate: end.date);
            }
          },
          setStartDay: (DateTime startDay) async {
            if (state.endDay == null) {
              emit(state.copyWith(startDay: startDay));
            } else if (startDay.isAfter(state.endDay!)) {
              emit(state.copyWith(startDay: startDay, endDay: null));
            } else {
              emit(state.copyWith(startDay: startDay));
              await _updateDateData(
                date: startDay.date,
                endDate: state.endDay!.date,
              );
            }
          },
          setEndDay: (DateTime endDay) {
            if (state.startDay == null) {
              emit(state.copyWith(endDay: endDay));
            } else if (endDay.isBefore(state.startDay!)) {
              emit(state.copyWith(startDay: null, endDay: endDay));
            } else {
              emit(state.copyWith(endDay: endDay));
              _updateDateData(date: state.startDay!.date, endDate: endDay.date);
            }
          },
          setEndTime: (String? endTime) async {
            emit(state.copyWith(endTimeStr: endTime));
            await _updateDateData(endTimeStr: endTime);
          },
          setDateFormat: (DateFormatPB dateFormat) async =>
              await _updateTypeOption(emit, dateFormat: dateFormat),
          setTimeFormat: (TimeFormatPB timeFormat) async =>
              await _updateTypeOption(emit, timeFormat: timeFormat),
          clearDate: () async {
            // Remove reminder if neccessary
            if (state.reminderId != null) {
              _reminderBloc
                  .add(ReminderEvent.remove(reminderId: state.reminderId!));
            }

            await _clearDate();
          },
          setReminderOption: (
            ReminderOption option,
            DateTime? selectedDay,
          ) async {
            if (state.reminderId?.isEmpty ??
                true &&
                    (state.dateTime != null || selectedDay != null) &&
                    option != ReminderOption.none) {
              // New Reminder
              final reminderId = nanoid();
              await _updateDateData(reminderId: reminderId, date: selectedDay);

              emit(
                state.copyWith(reminderOption: option, dateTime: selectedDay),
              );
            } else if (option == ReminderOption.none &&
                (state.reminderId?.isNotEmpty ?? false)) {
              // Remove reminder
              _reminderBloc
                  .add(ReminderEvent.remove(reminderId: state.reminderId!));
              await _updateDateData(reminderId: "");
              emit(state.copyWith(reminderOption: option));
            } else if (state.dateTime != null &&
                (state.reminderId?.isNotEmpty ?? false)) {
              final scheduledAt = option.fromDate(state.dateTime!);

              // Update reminder
              _reminderBloc.add(
                ReminderEvent.update(
                  ReminderUpdate(
                    id: state.reminderId!,
                    scheduledAt: scheduledAt,
                    includeTime: true,
                  ),
                ),
              );
            }
          },
          // Empty String signifies no reminder
          removeReminder: () async => _updateDateData(reminderId: ""),
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
    String? reminderId,
  }) async {
    // make sure that not both date and time are updated at the same time
    assert(
      !(date != null && timeStr != null) ||
          !(endDate != null && endTimeStr != null),
    );

    // if not updating the time, use the old time in the state
    final String? newTime = timeStr ?? state.timeStr;
    final DateTime? newDate = timeStr != null && timeStr.isNotEmpty
        ? state.dateTime ?? DateTime.now()
        : _utcToLocalAndAddCurrentTime(date);

    // if not updating the time, use the old time in the state
    final String? newEndTime = endTimeStr ?? state.endTimeStr;
    final DateTime? newEndDate = endTimeStr != null && endTimeStr.isNotEmpty
        ? state.endDateTime ?? DateTime.now()
        : _utcToLocalAndAddCurrentTime(endDate);

    final result = await _dateCellBackendService.update(
      date: newDate,
      time: newTime,
      endDate: newEndDate,
      endTime: newEndTime,
      includeTime: includeTime ?? state.includeTime,
      isRange: isRange ?? state.isRange,
      reminderId: reminderId ?? state.reminderId,
    );

    result.fold(
      (_) {
        if (!isClosed &&
            (state.parseEndTimeError != null || state.parseTimeError != null)) {
          add(const DateCellEditorEvent.didReceiveTimeFormatError(null, null));
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
              DateCellEditorEvent.didReceiveTimeFormatError(
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
        if (!isClosed) {
          add(const DateCellEditorEvent.didReceiveTimeFormatError(null, null));
        }
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
    return super.close();
  }

  void _startListening() {
    _onCellChangedFn = cellController.addListener(
      onCellChanged: (cell) {
        if (!isClosed) {
          add(DateCellEditorEvent.didReceiveCellUpdate(cell));
        }
      },
    );
  }

  Future<void>? _updateTypeOption(
    Emitter<DateCellEditorState> emit, {
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
      (_) => emit(
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
class DateCellEditorEvent with _$DateCellEditorEvent {
  // initial event
  const factory DateCellEditorEvent.initial() = _Initial;

  // notification that cell is updated in the backend
  const factory DateCellEditorEvent.didReceiveCellUpdate(
    DateCellDataPB? data,
  ) = _DidReceiveCellUpdate;

  const factory DateCellEditorEvent.didReceiveTimeFormatError(
    String? parseTimeError,
    String? parseEndTimeError,
  ) = _DidReceiveTimeFormatError;

  // date cell data is modified
  const factory DateCellEditorEvent.selectDay(DateTime day) = _SelectDay;

  const factory DateCellEditorEvent.selectDateRange(
    DateTime? start,
    DateTime? end,
  ) = _SelectDateRange;

  const factory DateCellEditorEvent.setStartDay(
    DateTime startDay,
  ) = _SetStartDay;

  const factory DateCellEditorEvent.setEndDay(
    DateTime endDay,
  ) = _SetEndDay;

  const factory DateCellEditorEvent.setTime(String time) = _SetTime;

  const factory DateCellEditorEvent.setEndTime(String endTime) = _SetEndTime;

  const factory DateCellEditorEvent.setIncludeTime(bool includeTime) =
      _IncludeTime;

  const factory DateCellEditorEvent.setIsRange(bool isRange) = _SetIsRange;

  const factory DateCellEditorEvent.setReminderOption({
    required ReminderOption option,
    @Default(null) DateTime? selectedDay,
  }) = _SetReminderOption;

  const factory DateCellEditorEvent.removeReminder() = _RemoveReminder;

  // date field type options are modified
  const factory DateCellEditorEvent.setTimeFormat(TimeFormatPB timeFormat) =
      _SetTimeFormat;

  const factory DateCellEditorEvent.setDateFormat(DateFormatPB dateFormat) =
      _SetDateFormat;

  const factory DateCellEditorEvent.clearDate() = _ClearDate;
}

@freezed
class DateCellEditorState with _$DateCellEditorState {
  const factory DateCellEditorState({
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
    required String? reminderId,

    // error and hint text
    required String? parseTimeError,
    required String? parseEndTimeError,
    required String timeHintText,
    @Default(ReminderOption.none) ReminderOption reminderOption,
  }) = _DateCellEditorState;

  factory DateCellEditorState.initial(
    DateCellController controller,
    ReminderBloc reminderBloc,
  ) {
    final typeOption = controller.getTypeOption(DateTypeOptionDataParser());
    final cellData = controller.getCellData();
    final dateCellData = _dateDataFromCellData(cellData);

    ReminderOption reminderOption = ReminderOption.none;
    if ((dateCellData.reminderId?.isNotEmpty ?? false) &&
        dateCellData.dateTime != null) {
      final reminder = reminderBloc.state.reminders
          .firstWhereOrNull((r) => r.id == dateCellData.reminderId);
      if (reminder != null) {
        final eventDate = dateCellData.includeTime
            ? dateCellData.dateTime!
            : dateCellData.dateTime!.withoutTime;
        reminderOption = ReminderOption.fromDateDifference(
          eventDate,
          reminder.scheduledAt.toDateTime(),
        );
      }
    }

    return DateCellEditorState(
      dateTypeOptionPB: typeOption,
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
      timeHintText: _timeHintText(typeOption),
      reminderId: dateCellData.reminderId,
      reminderOption: reminderOption,
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

_DateCellData _dateDataFromCellData(
  DateCellDataPB? cellData,
) {
  // a null DateCellDataPB may be returned, indicating that all the fields are
  // their default values: empty strings and false booleans
  if (cellData == null) {
    return _DateCellData(
      dateTime: null,
      endDateTime: null,
      timeStr: null,
      endTimeStr: null,
      includeTime: false,
      isRange: false,
      dateStr: null,
      endDateStr: null,
      reminderId: null,
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

  return _DateCellData(
    dateTime: dateTime,
    endDateTime: endDateTime,
    timeStr: timeStr,
    endTimeStr: endTimeStr,
    includeTime: includeTime,
    isRange: isRange,
    dateStr: dateStr,
    endDateStr: endDateStr,
    reminderId: cellData.reminderId,
  );
}

class _DateCellData {
  _DateCellData({
    required this.dateTime,
    required this.endDateTime,
    required this.timeStr,
    required this.endTimeStr,
    required this.includeTime,
    required this.isRange,
    required this.dateStr,
    required this.endDateStr,
    required this.reminderId,
  });

  final DateTime? dateTime;
  final DateTime? endDateTime;
  final String? timeStr;
  final String? endTimeStr;
  final bool includeTime;
  final bool isRange;
  final String? dateStr;
  final String? endDateStr;
  final String? reminderId;
}
