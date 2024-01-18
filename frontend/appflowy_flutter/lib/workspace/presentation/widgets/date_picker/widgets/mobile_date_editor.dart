import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/appflowy_date_picker.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/date_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

class MobileDatePicker extends StatefulWidget {
  const MobileDatePicker({
    super.key,
    this.selectedDay,
    required this.isRange,
    this.onDaySelected,
    this.rebuildOnDaySelected = false,
    this.onRangeSelected,
    this.firstDay,
    this.lastDay,
    this.startDay,
    this.endDay,
  });

  final DateTime? selectedDay;

  final bool isRange;

  final DaySelectedCallback? onDaySelected;

  final bool rebuildOnDaySelected;
  final RangeSelectedCallback? onRangeSelected;

  final DateTime? firstDay;
  final DateTime? lastDay;
  final DateTime? startDay;
  final DateTime? endDay;

  @override
  State<MobileDatePicker> createState() => _MobileDatePickerState();
}

class _MobileDatePickerState extends State<MobileDatePicker> {
  PageController? _pageController;

  late DateTime _focusedDay = widget.selectedDay ?? DateTime.now();
  late DateTime? _selectedDay = widget.selectedDay;

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
    return DatePicker(
      isRange: widget.isRange,
      onDaySelected: (selectedDay, focusedDay) {
        widget.onDaySelected?.call(selectedDay, focusedDay);

        if (widget.rebuildOnDaySelected) {
          setState(() => _selectedDay = selectedDay);
        }
      },
      onRangeSelected: widget.onRangeSelected,
      selectedDay:
          widget.rebuildOnDaySelected ? _selectedDay : widget.selectedDay,
      firstDay: widget.firstDay,
      lastDay: widget.lastDay,
      startDay: widget.startDay,
      endDay: widget.endDay,
      onCalendarCreated: (pageController) => _pageController = pageController,
      onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
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
