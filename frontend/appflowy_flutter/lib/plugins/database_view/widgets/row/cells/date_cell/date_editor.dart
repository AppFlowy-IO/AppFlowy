import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/appflowy_date_picker.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter/material.dart';
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
            onStartTimeSubmitted: (timeStr) {
              bloc.add(DateCellEditorEvent.setTime(timeStr));
            },
            onEndTimeSubmitted: (timeStr) {
              bloc.add(DateCellEditorEvent.setEndTime(timeStr));
            },
            onDaySelected: (selectedDay, _) {
              bloc.add(DateCellEditorEvent.selectDay(selectedDay));
            },
            onRangeSelected: (start, end, _) {
              bloc.add(DateCellEditorEvent.selectDateRange(start, end));
            },
            allowFormatChanges: true,
            onDateFormatChanged: (format) {
              bloc.add(DateCellEditorEvent.setDateFormat(format));
            },
            onTimeFormatChanged: (format) {
              bloc.add(DateCellEditorEvent.setTimeFormat(format));
            },
            onClearDate: () {
              bloc.add(const DateCellEditorEvent.clearDate());
            },
          );
        },
      ),
    );
  }
}
