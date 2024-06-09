import 'package:flutter/material.dart';

import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/appflowy_date_picker.dart';
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
  });

  final VoidCallback onDismissed;
  final DateCellController cellController;

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
    return MultiBlocProvider(
      providers: [
        BlocProvider<DateCellEditorBloc>(
          create: (context) => DateCellEditorBloc(
            reminderBloc: getIt<ReminderBloc>(),
            cellController: widget.cellController,
          ),
        ),
      ],
      child: BlocBuilder<DateCellEditorBloc, DateCellEditorState>(
        builder: (context, state) {
          final dateCellBloc = context.read<DateCellEditorBloc>();
          return AppFlowyDatePicker(
            includeTime: state.includeTime,
            rebuildOnDaySelected: false,
            onIncludeTimeChanged: (value) =>
                dateCellBloc.add(DateCellEditorEvent.setIncludeTime(!value)),
            isRange: state.isRange,
            startDay: state.isRange ? state.startDay : null,
            endDay: state.isRange ? state.endDay : null,
            onIsRangeChanged: (value) =>
                dateCellBloc.add(DateCellEditorEvent.setIsRange(!value)),
            dateFormat: state.dateTypeOptionPB.dateFormat,
            timeFormat: state.dateTypeOptionPB.timeFormat,
            selectedDay: state.dateTime,
            timeStr: state.timeStr,
            endTimeStr: state.endTimeStr,
            timeHintText: state.timeHintText,
            parseEndTimeError: state.parseEndTimeError,
            parseTimeError: state.parseTimeError,
            popoverMutex: popoverMutex,
            onReminderSelected: (option) => dateCellBloc.add(
              DateCellEditorEvent.setReminderOption(
                option: option,
                selectedDay: state.dateTime == null ? DateTime.now() : null,
              ),
            ),
            selectedReminderOption: state.reminderOption,
            options: [
              OptionGroup(
                options: [
                  DateTypeOptionButton(
                    popoverMutex: popoverMutex,
                    dateFormat: state.dateTypeOptionPB.dateFormat,
                    timeFormat: state.dateTypeOptionPB.timeFormat,
                    onDateFormatChanged: (format) => dateCellBloc
                        .add(DateCellEditorEvent.setDateFormat(format)),
                    onTimeFormatChanged: (format) => dateCellBloc
                        .add(DateCellEditorEvent.setTimeFormat(format)),
                  ),
                  ClearDateButton(
                    onClearDate: () =>
                        dateCellBloc.add(const DateCellEditorEvent.clearDate()),
                  ),
                ],
              ),
            ],
            onStartTimeSubmitted: (timeStr) =>
                dateCellBloc.add(DateCellEditorEvent.setTime(timeStr)),
            onEndTimeSubmitted: (timeStr) =>
                dateCellBloc.add(DateCellEditorEvent.setEndTime(timeStr)),
            onDaySelected: (selectedDay, _) =>
                dateCellBloc.add(DateCellEditorEvent.selectDay(selectedDay)),
            onRangeSelected: (start, end, _) => dateCellBloc
                .add(DateCellEditorEvent.selectDateRange(start, end)),
          );
        },
      ),
    );
  }
}
