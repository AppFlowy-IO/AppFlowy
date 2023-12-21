import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:table_calendar/table_calendar.dart';

final kFirstDay = DateTime.utc(1970, 1, 1);
final kLastDay = DateTime.utc(2100, 1, 1);

class DatePicker extends StatefulWidget {
  const DatePicker({
    super.key,
    required this.isRange,
    this.calendarFormat = CalendarFormat.month,
    this.startDay,
    this.endDay,
    this.selectedDay,
    this.firstDay,
    this.lastDay,
    this.onDaySelected,
    this.onRangeSelected,
  });

  final bool isRange;
  final CalendarFormat calendarFormat;

  final DateTime? startDay;
  final DateTime? endDay;
  final DateTime? selectedDay;

  /// If not provided, defaults to 1st January 1970
  ///
  final DateTime? firstDay;

  /// If not provided, defaults to 1st January 2100
  ///
  final DateTime? lastDay;

  final Function(
    DateTime selectedDay,
    DateTime focusedDay,
  )? onDaySelected;

  final Function(
    DateTime? start,
    DateTime? end,
    DateTime focusedDay,
  )? onRangeSelected;

  @override
  State<DatePicker> createState() => _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {
  DateTime _focusedDay = DateTime.now();
  late CalendarFormat _calendarFormat = widget.calendarFormat;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium!;
    final boxDecoration = BoxDecoration(
      color: Theme.of(context).cardColor,
      shape: BoxShape.circle,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TableCalendar(
        firstDay: widget.firstDay ?? kFirstDay,
        lastDay: widget.lastDay ?? kLastDay,
        focusedDay: _focusedDay,
        rowHeight: 26.0 + 7.0,
        calendarFormat: _calendarFormat,
        availableCalendarFormats: const {CalendarFormat.month: 'Month'},
        daysOfWeekHeight: 17.0 + 8.0,
        rangeSelectionMode: widget.isRange
            ? RangeSelectionMode.enforced
            : RangeSelectionMode.disabled,
        rangeStartDay: widget.isRange ? widget.startDay : null,
        rangeEndDay: widget.isRange ? widget.endDay : null,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: textStyle,
          leftChevronMargin: EdgeInsets.zero,
          leftChevronPadding: EdgeInsets.zero,
          leftChevronIcon: FlowySvg(
            FlowySvgs.arrow_left_s,
            color: Theme.of(context).iconTheme.color,
          ),
          rightChevronPadding: EdgeInsets.zero,
          rightChevronMargin: EdgeInsets.zero,
          rightChevronIcon: FlowySvg(
            FlowySvgs.arrow_right_s,
            color: Theme.of(context).iconTheme.color,
          ),
          headerMargin: EdgeInsets.zero,
          headerPadding: const EdgeInsets.only(bottom: 8.0),
        ),
        calendarStyle: CalendarStyle(
          cellMargin: const EdgeInsets.all(3.5),
          defaultDecoration: boxDecoration,
          selectedDecoration: boxDecoration.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
          todayDecoration: boxDecoration.copyWith(
            color: Colors.transparent,
            border: Border.all(color: Theme.of(context).colorScheme.primary),
          ),
          weekendDecoration: boxDecoration,
          outsideDecoration: boxDecoration,
          rangeStartDecoration: boxDecoration.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
          rangeEndDecoration: boxDecoration.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
          defaultTextStyle: textStyle,
          weekendTextStyle: textStyle,
          selectedTextStyle: textStyle.copyWith(
            color: Theme.of(context).colorScheme.surface,
          ),
          rangeStartTextStyle: textStyle.copyWith(
            color: Theme.of(context).colorScheme.surface,
          ),
          rangeEndTextStyle: textStyle.copyWith(
            color: Theme.of(context).colorScheme.surface,
          ),
          todayTextStyle: textStyle,
          outsideTextStyle: textStyle.copyWith(
            color: Theme.of(context).disabledColor,
          ),
          rangeHighlightColor: Theme.of(context).colorScheme.secondaryContainer,
        ),
        calendarBuilders: CalendarBuilders(
          dowBuilder: (context, day) {
            final locale = context.locale.toLanguageTag();
            final label = DateFormat.E(locale).format(day).substring(0, 2);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Center(
                child: Text(
                  label,
                  style: AFThemeExtension.of(context).caption,
                ),
              ),
            );
          },
        ),
        selectedDayPredicate: (day) =>
            widget.isRange ? false : isSameDay(widget.selectedDay, day),
        onFormatChanged: (calendarFormat) =>
            setState(() => _calendarFormat = calendarFormat),
        onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
        onDaySelected: widget.onDaySelected,
        onRangeSelected: widget.onRangeSelected,
      ),
    );
  }
}
