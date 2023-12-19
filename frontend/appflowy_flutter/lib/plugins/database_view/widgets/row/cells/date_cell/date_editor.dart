import 'package:flutter/material.dart';

import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/appflowy_date_picker.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/clear_date_button.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/date_type_option_button.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  @override
  void dispose() {
    popoverMutex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DateCellEditorBloc(
        cellController: widget.cellController,
      )..add(const DateCellEditorEvent.initial()),
      child: BlocBuilder<DateCellEditorBloc, DateCellEditorState>(
        builder: (context, state) {
          final bloc = context.read<DateCellEditorBloc>();
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
                    onClearDate: () => context
                        .read<DateCellEditorBloc>()
                        .add(const DateCellEditorEvent.clearDate()),
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
}
