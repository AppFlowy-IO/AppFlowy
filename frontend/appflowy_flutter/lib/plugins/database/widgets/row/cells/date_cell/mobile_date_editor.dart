import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/appflowy_date_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'date_cell_editor_bloc.dart';

class MobileDatePicker extends StatefulWidget {
  const MobileDatePicker({
    super.key,
  });

  @override
  State<MobileDatePicker> createState() => _MobileDatePickerState();
}

class _MobileDatePickerState extends State<MobileDatePicker> {
  DateTime _focusedDay = DateTime.now();
  PageController? _pageController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const VSpace(8.0),
        _buildHeader(context),
        const VSpace(8.0),
        _buildCalendar(context),
        const VSpace(16.0),
      ],
    );
  }

  Widget _buildCalendar(BuildContext context) {
    return BlocBuilder<DateCellEditorBloc, DateCellEditorState>(
      builder: (context, state) {
        return AppFlowyDatePicker(
          includeTime: state.includeTime,
          rebuildOnDaySelected: false,
          dateFormat: state.dateTypeOptionPB.dateFormat,
          timeFormat: state.dateTypeOptionPB.timeFormat,
          selectedDay: state.dateTime,
          startDay: state.isRange ? state.startDay : null,
          endDay: state.isRange ? state.endDay : null,
          timeStr: state.timeStr,
          endTimeStr: state.endTimeStr,
          timeHintText: state.timeHintText,
          parseEndTimeError: state.parseEndTimeError,
          parseTimeError: state.parseTimeError,
          onIncludeTimeChanged: (value) => context
              .read<DateCellEditorBloc>()
              .add(DateCellEditorEvent.setIncludeTime(!value)),
          isRange: state.isRange,
          onIsRangeChanged: (value) => context
              .read<DateCellEditorBloc>()
              .add(DateCellEditorEvent.setIsRange(!value)),
          onCalendarCreated: (pageController) =>
              _pageController = pageController,
          onDaySelected: (selectedDay, focusedDay) => context
              .read<DateCellEditorBloc>()
              .add(DateCellEditorEvent.selectDay(selectedDay)),
          onRangeSelected: (start, end, focusedDay) => context
              .read<DateCellEditorBloc>()
              .add(DateCellEditorEvent.selectDateRange(start, end)),
          onPageChanged: (focusedDay) =>
              setState(() => _focusedDay = focusedDay),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const HSpace(16.0),
        FlowyText(
          DateFormat.yMMMM().format(_focusedDay),
        ),
        const Spacer(),
        FlowyButton(
          useIntrinsicWidth: true,
          text: FlowySvg(
            FlowySvgs.arrow_left_s,
            color: Theme.of(context).iconTheme.color,
            size: const Size.square(24.0),
          ),
          onTap: () => _pageController?.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          ),
        ),
        const HSpace(24.0),
        FlowyButton(
          useIntrinsicWidth: true,
          text: FlowySvg(
            FlowySvgs.arrow_right_s,
            color: Theme.of(context).iconTheme.color,
            size: const Size.square(24.0),
          ),
          onTap: () => _pageController?.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          ),
        ),
        const HSpace(8.0),
      ],
    );
  }
}
