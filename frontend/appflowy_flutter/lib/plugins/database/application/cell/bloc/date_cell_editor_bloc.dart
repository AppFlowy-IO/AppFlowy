import 'dart:async';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/domain/date_cell_service.dart';
import 'package:appflowy/plugins/database/domain/field_service.dart';
import 'package:appflowy/plugins/database/application/field/type_option/type_option_data_parser.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/user/application/reminder/reminder_extension.dart';
import 'package:appflowy/util/int64_extension.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/reminder_selector.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart'
    show StringTranslateExtension;
import 'package:fixnum/fixnum.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nanoid/non_secure.dart';
import 'package:protobuf/protobuf.dart' hide FieldInfo;

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
    _startListening();
  }

  final DateCellBackendService _dateCellBackendService;
  final DateCellController cellController;
  final ReminderBloc _reminderBloc;

  void Function()? _onCellChangedFn;

  void _dispatch() {
    on<DateCellEditorEvent>(
      (event, emit) async {
        await event.when(
          didReceiveCellUpdate: (DateCellDataPB? cellData) {
            final dateCellData = DateCellData.fromPB(cellData);

            final cellReminderId = dateCellData.reminderId;

            if (dateCellData.dateTime != null &&
                state.reminderId.isEmpty &&
                !_reminderBloc.state.reminders
                    .any((e) => e.id == cellReminderId)) {
              final date = state.reminderOption.withoutTime
                  ? dateCellData.dateTime!.withoutTime
                  : dateCellData.dateTime!;

              // Add Reminder
              _reminderBloc.add(
                ReminderEvent.addById(
                  reminderId: cellReminderId,
                  objectId: cellController.viewId,
                  meta: {
                    ReminderMetaKeys.includeTime: true.toString(),
                    ReminderMetaKeys.rowId: cellController.rowId,
                  },
                  scheduledAt: Int64(
                    state.reminderOption
                            .getNotificationDateTime(date)
                            .millisecondsSinceEpoch ~/
                        1000,
                  ),
                ),
              );
            }

            ReminderOption option = state.reminderOption;
            if (cellReminderId.isNotEmpty && dateCellData.dateTime != null) {
              if (option.requiresNoTime && dateCellData.includeTime) {
                option = ReminderOption.atTimeOfEvent;
              } else if (!option.withoutTime && !dateCellData.includeTime) {
                option = ReminderOption.onDayOfEvent;
              }

              final date = option.withoutTime
                  ? dateCellData.dateTime!.withoutTime
                  : dateCellData.dateTime!;

              final scheduledAt = option.getNotificationDateTime(date);

              // Update Reminder
              _reminderBloc.add(
                ReminderEvent.update(
                  ReminderUpdate(
                    id: dateCellData.reminderId,
                    scheduledAt: scheduledAt,
                    includeTime: true,
                  ),
                ),
              );
            }

            emit(
              state.copyWith(
                dateTime: dateCellData.dateTime,
                endDateTime: dateCellData.endDateTime,
                includeTime: dateCellData.includeTime,
                isRange: dateCellData.isRange,
                reminderId: dateCellData.reminderId,
                reminderOption: option,
              ),
            );
          },
          didUpdateField: (field) {
            final typeOption = DateTypeOptionDataParser()
                .fromBuffer(field.field.typeOptionData);
            emit(state.copyWith(dateTypeOptionPB: typeOption));
          },
          updateDateTime: (date) async {
            if (state.isRange) {
              return;
            }
            await _updateDateData(date: date);
          },
          updateDateRange: (DateTime start, DateTime end) async {
            if (!state.isRange) {
              return;
            }
            await _updateDateData(date: start, endDate: end);
          },
          setIncludeTime: (includeTime, dateTime, endDateTime) async {
            await _updateIncludeTime(includeTime, dateTime, endDateTime);
          },
          setIsRange: (isRange, dateTime, endDateTime) async {
            await _updateIsRange(isRange, dateTime, endDateTime);
          },
          setDateFormat: (DateFormatPB dateFormat) async {
            await _updateTypeOption(emit, dateFormat: dateFormat);
          },
          setTimeFormat: (TimeFormatPB timeFormat) async {
            await _updateTypeOption(emit, timeFormat: timeFormat);
          },
          clearDate: () async {
            // Remove reminder if neccessary
            if (state.reminderId.isNotEmpty) {
              _reminderBloc
                  .add(ReminderEvent.remove(reminderId: state.reminderId));
            }

            await _clearDate();
          },
          setReminderOption: (
            ReminderOption option,
          ) async {
            if (option == ReminderOption.none && state.reminderId.isNotEmpty) {
              _reminderBloc.add(
                ReminderEvent.remove(reminderId: state.reminderId),
              );
              await _updateDateData(reminderId: "");
            } else if (state.reminderId.isEmpty) {
              // New Reminder
              final reminderId = nanoid();
              await _updateDateData(
                reminderId: reminderId,
                date: state.dateTime ?? DateTime.now().withoutTime,
              );
            } else if (state.dateTime != null) {
              // Update reminder
              final scheduledAt =
                  option.getNotificationDateTime(state.dateTime!);
              _reminderBloc.add(
                ReminderEvent.update(
                  ReminderUpdate(
                    id: state.reminderId,
                    scheduledAt: scheduledAt,
                    includeTime: true,
                  ),
                ),
              );
            }
          },
          removeReminder: () async {
            await _updateDateData(reminderId: "");
          },
        );
      },
    );
  }

  Future<void> _updateDateData({
    DateTime? date,
    DateTime? endDate,
    String? reminderId,
  }) async {
    final result = await _dateCellBackendService.update(
      date: date,
      endDate: endDate,
      reminderId: reminderId,
    );
    result.onFailure(Log.error);
  }

  Future<void> _updateIsRange(
    bool isRange,
    DateTime? dateTime,
    DateTime? endDateTime,
  ) async {
    final result = await _dateCellBackendService.update(
      date: dateTime,
      endDate: endDateTime,
      isRange: isRange,
    );
    result.onFailure(Log.error);
  }

  Future<void> _updateIncludeTime(
    bool includeTime,
    DateTime? dateTime,
    DateTime? endDateTime,
  ) async {
    final result = await _dateCellBackendService.update(
      date: dateTime,
      endDate: endDateTime,
      includeTime: includeTime,
    );
    result.onFailure(Log.error);
  }

  Future<void> _clearDate() async {
    final result = await _dateCellBackendService.clear();
    result.onFailure(Log.error);
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
      cellController.removeListener(
        onCellChanged: _onCellChangedFn!,
        onFieldChanged: _onFieldChangedListener,
      );
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
      onFieldChanged: _onFieldChangedListener,
    );
  }

  void _onFieldChangedListener(FieldInfo fieldInfo) {
    if (!isClosed) {
      add(DateCellEditorEvent.didUpdateField(fieldInfo));
    }
  }

  Future<void> _updateTypeOption(
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

    result.fold((_) => {}, (err) => Log.error(err));
  }
}

@freezed
class DateCellEditorEvent with _$DateCellEditorEvent {
  const factory DateCellEditorEvent.didUpdateField(
    FieldInfo fieldInfo,
  ) = _DidUpdateField;

  // notification that cell is updated in the backend
  const factory DateCellEditorEvent.didReceiveCellUpdate(
    DateCellDataPB? data,
  ) = _DidReceiveCellUpdate;

  const factory DateCellEditorEvent.updateDateTime(DateTime day) =
      _UpdateDateTime;

  const factory DateCellEditorEvent.updateDateRange(
    DateTime start,
    DateTime end,
  ) = _UpdateDateRange;

  const factory DateCellEditorEvent.setIncludeTime(
    bool includeTime,
    DateTime? dateTime,
    DateTime? endDateTime,
  ) = _IncludeTime;

  const factory DateCellEditorEvent.setIsRange(
    bool isRange,
    DateTime? dateTime,
    DateTime? endDateTime,
  ) = _SetIsRange;

  const factory DateCellEditorEvent.setReminderOption(ReminderOption option) =
      _SetReminderOption;

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

    // cell data from the backend
    required DateTime? dateTime,
    required DateTime? endDateTime,
    required bool includeTime,
    required bool isRange,
    required String reminderId,
    @Default(ReminderOption.none) ReminderOption reminderOption,
  }) = _DateCellEditorState;

  factory DateCellEditorState.initial(
    DateCellController controller,
    ReminderBloc reminderBloc,
  ) {
    final typeOption = controller.getTypeOption(DateTypeOptionDataParser());
    final cellData = controller.getCellData();
    final dateCellData = DateCellData.fromPB(cellData);

    ReminderOption reminderOption = ReminderOption.none;

    if (dateCellData.reminderId.isNotEmpty && dateCellData.dateTime != null) {
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
      dateTime: dateCellData.dateTime,
      endDateTime: dateCellData.endDateTime,
      includeTime: dateCellData.includeTime,
      isRange: dateCellData.isRange,
      reminderId: dateCellData.reminderId,
      reminderOption: reminderOption,
    );
  }
}

/// Helper class to parse ProtoBuf payloads into DateCellEditorState
class DateCellData {
  const DateCellData({
    required this.dateTime,
    required this.endDateTime,
    required this.includeTime,
    required this.isRange,
    required this.reminderId,
  });

  const DateCellData.empty()
      : dateTime = null,
        endDateTime = null,
        includeTime = false,
        isRange = false,
        reminderId = "";

  factory DateCellData.fromPB(DateCellDataPB? cellData) {
    // a null DateCellDataPB may be returned, indicating that all the fields are
    // their default values: empty strings and false booleans
    if (cellData == null) {
      return const DateCellData.empty();
    }

    final dateTime =
        cellData.hasTimestamp() ? cellData.timestamp.toDateTime() : null;
    final endDateTime = dateTime == null || !cellData.isRange
        ? null
        : cellData.hasEndTimestamp()
            ? cellData.endTimestamp.toDateTime()
            : null;

    return DateCellData(
      dateTime: dateTime,
      endDateTime: endDateTime,
      includeTime: cellData.includeTime,
      isRange: cellData.isRange,
      reminderId: cellData.reminderId,
    );
  }

  final DateTime? dateTime;
  final DateTime? endDateTime;
  final bool includeTime;
  final bool isRange;
  final String reminderId;
}
