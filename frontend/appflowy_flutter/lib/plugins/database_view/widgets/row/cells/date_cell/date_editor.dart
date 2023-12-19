import 'package:flutter/material.dart';

import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/appflowy_date_picker.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:dartz/dartz.dart' show Either;
import 'package:flutter_bloc/flutter_bloc.dart';

import 'date_cal_bloc.dart';

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
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Either<dynamic, FlowyError>>(
      future: widget.cellController.getTypeOption(DateTypeOptionDataParser()),
      builder: (_, snapshot) {
        if (snapshot.hasData) {
          return _buildWidget(snapshot);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildWidget(AsyncSnapshot<Either<dynamic, FlowyError>> snapshot) {
    return snapshot.data!.fold(
      (dateTypeOptionPB) => _CellCalendarWidget(
        cellContext: widget.cellController,
        dateTypeOptionPB: dateTypeOptionPB,
      ),
      (err) {
        Log.error(err);
        return const SizedBox.shrink();
      },
    );
  }
}

class _CellCalendarWidget extends StatefulWidget {
  final DateCellController cellContext;
  final DateTypeOptionPB dateTypeOptionPB;

  const _CellCalendarWidget({
    required this.cellContext,
    required this.dateTypeOptionPB,
  });

  @override
  State<_CellCalendarWidget> createState() => _CellCalendarWidgetState();
}

class _CellCalendarWidgetState extends State<_CellCalendarWidget> {
  final PopoverMutex popoverMutex = PopoverMutex();

  @override
  void dispose() {
    popoverMutex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DateCellCalendarBloc(
        dateTypeOptionPB: widget.dateTypeOptionPB,
        cellData: widget.cellContext.getCellData(),
        cellController: widget.cellContext,
      )..add(const DateCellCalendarEvent.initial()),
      child: BlocBuilder<DateCellCalendarBloc, DateCellCalendarState>(
        builder: (context, state) {
          return AppFlowyDatePicker(
            includeTime: state.includeTime,
            onIncludeTimeChanged: (value) => context
                .read<DateCellCalendarBloc>()
                .add(DateCellCalendarEvent.setIncludeTime(!value)),
            isRange: state.isRange,
            onIsRangeChanged: (value) => context
                .read<DateCellCalendarBloc>()
                .add(DateCellCalendarEvent.setIsRange(!value)),
            dateFormat: state.dateTypeOptionPB.dateFormat,
            timeFormat: state.dateTypeOptionPB.timeFormat,
            selectedDay: state.dateTime,
            timeStr: state.timeStr,
            endTimeStr: state.endTimeStr,
            timeHintText: state.timeHintText,
            parseEndTimeError: state.parseEndTimeError,
            parseTimeError: state.parseTimeError,
            popoverMutex: popoverMutex,
            onStartTimeSubmitted: (timeStr) => context
                .read<DateCellCalendarBloc>()
                .add(DateCellCalendarEvent.setTime(timeStr)),
            onEndTimeSubmitted: (timeStr) => context
                .read<DateCellCalendarBloc>()
                .add(DateCellCalendarEvent.setEndTime(timeStr)),
            onDaySelected: (selectedDay, _) => context
                .read<DateCellCalendarBloc>()
                .add(DateCellCalendarEvent.selectDay(selectedDay)),
            onRangeSelected: (start, end, _) => context
                .read<DateCellCalendarBloc>()
                .add(DateCellCalendarEvent.selectDateRange(start, end)),
            allowFormatChanges: true,
            onDateFormatChanged: (format) => context
                .read<DateCellCalendarBloc>()
                .add(DateCellCalendarEvent.setDateFormat(format)),
            onTimeFormatChanged: (format) => context
                .read<DateCellCalendarBloc>()
                .add(DateCellCalendarEvent.setTimeFormat(format)),
            onClearDate: () => context
                .read<DateCellCalendarBloc>()
                .add(const DateCellCalendarEvent.clearDate()),
          );
        },
      ),
    );
  }
}
