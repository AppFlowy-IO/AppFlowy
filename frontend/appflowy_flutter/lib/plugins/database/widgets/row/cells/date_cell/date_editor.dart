import 'package:appflowy/util/int64_extension.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu_shared_state.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/appflowy_date_picker.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/clear_date_button.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/date_type_option_button.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/reminder_selector.dart';
import 'package:appflowy_backend/protobuf/flowy-user/reminder.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nanoid/non_secure.dart';

import 'date_cell_editor_bloc.dart';

class DateCellEditor extends StatefulWidget {
  const DateCellEditor({
    super.key,
    required this.onDismissed,
    required this.cellController,
  });

  final VoidCallback onDismissed;
  final DateCellController cellController;

  @override
  State<StatefulWidget> createState() => _DateCellEditor();
}

class _DateCellEditor extends State<DateCellEditor> {
  final PopoverMutex popoverMutex = PopoverMutex();
  ReminderOption _reminderOption = ReminderOption.none;

  @override
  void dispose() {
    popoverMutex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DateCellEditorBloc>(
          create: (context) => DateCellEditorBloc(
            cellController: widget.cellController,
          )..add(const DateCellEditorEvent.initial()),
        ),
        BlocProvider<ReminderBloc>.value(value: getIt<ReminderBloc>()),
      ],
      child: BlocConsumer<DateCellEditorBloc, DateCellEditorState>(
        listenWhen: (prev, curr) =>
            curr.reminderId != null &&
            curr.reminderId!.isNotEmpty &&
            curr.dateTime != null,
        listener: (context, state) => _updateReminderScheduledAt(
          context.read<ReminderBloc>(),
          state.reminderId!,
          state.dateTime!,
        ),
        builder: (context, state) {
          final bloc = context.read<DateCellEditorBloc>();
          final reminder = context
              .read<ReminderBloc>()
              .state
              .reminders
              .firstWhereOrNull((r) => r.id == state.reminderId);

          _reminderOption = reminder != null && state.dateTime != null
              ? ReminderOption.fromDateDifference(
                  state.dateTime!,
                  reminder.scheduledAt.toDateTime(),
                )
              : ReminderOption.none;

          return AppFlowyDatePicker(
            includeTime: state.includeTime,
            onIncludeTimeChanged: (value) =>
                bloc.add(DateCellEditorEvent.setIncludeTime(!value)),
            isRange: state.isRange,
            onIsRangeChanged: (value) =>
                bloc.add(DateCellEditorEvent.setIsRange(!value)),
            dateFormat: state.dateTypeOptionPB.dateFormat,
            timeFormat: state.dateTypeOptionPB.timeFormat,
            selectedDay: state.dateTime,
            timeStr: state.timeStr,
            endTimeStr: state.endTimeStr,
            timeHintText: state.timeHintText,
            parseEndTimeError: state.parseEndTimeError,
            parseTimeError: state.parseTimeError,
            popoverMutex: popoverMutex,
            onReminderSelected: (newOption) => _updateReminderOption(
              newOption,
              cellBloc: bloc,
              reminderBloc: context.read<ReminderBloc>(),
            ),
            selectedReminderOption: _reminderOption,
            options: [
              OptionGroup(
                options: [
                  DateTypeOptionButton(
                    popoverMutex: popoverMutex,
                    dateFormat: state.dateTypeOptionPB.dateFormat,
                    timeFormat: state.dateTypeOptionPB.timeFormat,
                    onDateFormatChanged: (format) => context
                        .read<DateCellEditorBloc>()
                        .add(DateCellEditorEvent.setDateFormat(format)),
                    onTimeFormatChanged: (format) => context
                        .read<DateCellEditorBloc>()
                        .add(DateCellEditorEvent.setTimeFormat(format)),
                  ),
                  ClearDateButton(
                    onClearDate: () {
                      // Clear in Database
                      context
                          .read<DateCellEditorBloc>()
                          .add(const DateCellEditorEvent.clearDate());

                      // Remove reminder if neccessary
                      _removeReminder(
                        context.read<ReminderBloc>(),
                        state.reminderId,
                      );
                    },
                  ),
                ],
              ),
            ],
            onStartTimeSubmitted: (timeStr) => context
                .read<DateCellEditorBloc>()
                .add(DateCellEditorEvent.setTime(timeStr)),
            onEndTimeSubmitted: (timeStr) => context
                .read<DateCellEditorBloc>()
                .add(DateCellEditorEvent.setEndTime(timeStr)),
            onDaySelected: (selectedDay, _) => context
                .read<DateCellEditorBloc>()
                .add(DateCellEditorEvent.selectDay(selectedDay)),
            onRangeSelected: (start, end, _) => context
                .read<DateCellEditorBloc>()
                .add(DateCellEditorEvent.selectDateRange(start, end)),
          );
        },
      ),
    );
  }

  void _removeReminder(ReminderBloc bloc, String? reminderId) {
    if (reminderId != null) {
      final reminder =
          bloc.state.reminders.firstWhereOrNull((r) => r.id == reminderId);

      if (reminder != null) {
        bloc.add(ReminderEvent.remove(reminder: reminder));
      }
    }
  }

  void _updateReminderScheduledAt(
    ReminderBloc bloc,
    String reminderId,
    DateTime scheduledAt,
  ) =>
      bloc.add(
        ReminderEvent.update(
          ReminderUpdate(
            id: reminderId,
            scheduledAt: scheduledAt.subtract(_reminderOption.time),
          ),
        ),
      );

  void _updateReminderOption(
    ReminderOption newOption, {
    required DateCellEditorBloc cellBloc,
    required ReminderBloc reminderBloc,
  }) {
    final dateOfEvent = cellBloc.state.dateTime;
    if (dateOfEvent == null) {
      return;
    }

    final reminderId = cellBloc.state.reminderId;
    if ((reminderId != null || (reminderId?.isEmpty ?? false)) &&
        newOption == ReminderOption.none) {
      // Remove reminder if there is a reminder
      final reminder = reminderBloc.state.reminders
          .firstWhereOrNull((r) => r.id == reminderId);

      if (reminder != null) {
        reminderBloc.add(ReminderEvent.remove(reminder: reminder));
      }

      // Remove reminderId in database
      return cellBloc.add(const DateCellEditorEvent.removeReminder());
    } else if ((reminderId == null || reminderId.isEmpty) &&
        newOption != ReminderOption.none) {
      // Add reminder
      final reminderId = nanoid();
      final scheduledAtDate = dateOfEvent.subtract(newOption.time);
      reminderBloc.add(
        ReminderEvent.add(
          reminder: ReminderPB(
            id: reminderId,
            objectId: getIt<MenuSharedState>().latestOpenView?.id,
            title: LocaleKeys.reminderNotification_title.tr(),
            message: LocaleKeys.reminderNotification_message.tr(),
            scheduledAt: Int64(scheduledAtDate.millisecondsSinceEpoch ~/ 1000),
            isAck: dateOfEvent.isBefore(DateTime.now()),
          ),
        ),
      );

      // Update reminderId in database
      return cellBloc.add(
        DateCellEditorEvent.setReminder(reminderId: reminderId),
      );
    }

    if (reminderId != null) {
      // Update reminder
      reminderBloc.add(
        ReminderEvent.update(
          ReminderUpdate(
            id: reminderId,
            scheduledAt: dateOfEvent.subtract(newOption.time),
          ),
        ),
      );
    }
  }
}
