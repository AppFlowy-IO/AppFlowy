import 'package:flutter/material.dart';

import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/calendar/application/calendar_bloc.dart';
import 'package:appflowy/plugins/database/calendar/application/calendar_setting_bloc.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/desktop_date_picker.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/clear_date_button.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/date_type_option_button.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/cell/bloc/date_cell_editor_bloc.dart';

class DateCellEditor extends StatefulWidget {
  const DateCellEditor({
    super.key,
    required this.onDismissed,
    required this.cellController,
    this.firstDayOfWeek,
  });

  final VoidCallback onDismissed;
  final DateCellController cellController;
  final int? firstDayOfWeek;

  @override
  State<StatefulWidget> createState() => _DateCellEditor();
}

class _DateCellEditor extends State<DateCellEditor> {
  final PopoverMutex popoverMutex = PopoverMutex();

  @override
  void dispose() {
    popoverMutex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DateCellEditorBloc>(
      create: (context) => DateCellEditorBloc(
        reminderBloc: getIt<ReminderBloc>(),
        cellController: widget.cellController,
      ),
      child: BlocBuilder<DateCellEditorBloc, DateCellEditorState>(
        builder: (context, state) {
          final dateCellBloc = context.read<DateCellEditorBloc>();
          final firstDayOfWeek = widget.firstDayOfWeek ??
              context.read<CalendarBloc?>()?.state.settings?.firstDayOfWeek ??
              context
                  .read<CalendarSettingBloc?>()
                  ?.state
                  .layoutSetting
                  ?.firstDayOfWeek;
          return DesktopAppFlowyDatePicker(
            dateTime: state.dateTime,
            endDateTime: state.endDateTime,
            dateFormat: state.dateTypeOptionPB.dateFormat,
            timeFormat: state.dateTypeOptionPB.timeFormat,
            includeTime: state.includeTime,
            isRange: state.isRange,
            reminderOption: state.reminderOption,
            popoverMutex: popoverMutex,
            firstDayOfWeek: firstDayOfWeek,
            options: [
              OptionGroup(
                options: [
                  DateTypeOptionButton(
                    popoverMutex: popoverMutex,
                    dateFormat: state.dateTypeOptionPB.dateFormat,
                    timeFormat: state.dateTypeOptionPB.timeFormat,
                    onDateFormatChanged: (format) {
                      dateCellBloc
                          .add(DateCellEditorEvent.setDateFormat(format));
                    },
                    onTimeFormatChanged: (format) {
                      dateCellBloc
                          .add(DateCellEditorEvent.setTimeFormat(format));
                    },
                  ),
                  ClearDateButton(
                    onClearDate: () {
                      dateCellBloc.add(const DateCellEditorEvent.clearDate());
                    },
                  ),
                ],
              ),
            ],
            onIncludeTimeChanged: (value, dateTime, endDateTime) {
              dateCellBloc.add(
                DateCellEditorEvent.setIncludeTime(
                  value,
                  dateTime,
                  endDateTime,
                ),
              );
            },
            onIsRangeChanged: (value, dateTime, endDateTime) {
              dateCellBloc.add(
                DateCellEditorEvent.setIsRange(value, dateTime, endDateTime),
              );
            },
            onDaySelected: (selectedDay) {
              dateCellBloc.add(DateCellEditorEvent.updateDateTime(selectedDay));
            },
            onRangeSelected: (start, end) {
              dateCellBloc.add(DateCellEditorEvent.updateDateRange(start, end));
            },
            onReminderSelected: (option) {
              dateCellBloc.add(DateCellEditorEvent.setReminderOption(option));
            },
          );
        },
      ),
    );
  }
}
