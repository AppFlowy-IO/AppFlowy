import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

final kFirstDay = DateTime.utc(1970, 1, 1);
final kLastDay = DateTime.utc(2100, 1, 1);

class AppFlowyCalendar extends StatelessWidget {
  const AppFlowyCalendar({
    super.key,
    this.selectedDate,
    required this.focusedDay,
    required this.format,
    this.onDaySelected,
    this.onFormatChanged,
    this.onPageChanged,
  });

  final DateTime? selectedDate;
  final DateTime focusedDay;
  final CalendarFormat format;

  final OnDaySelected? onDaySelected;
  final void Function(CalendarFormat format)? onFormatChanged;
  final void Function(DateTime focusedDay)? onPageChanged;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium!;
    final defaultDecoration = _defaultDecoration(context);

    return TableCalendar(
      firstDay: kFirstDay,
      lastDay: kLastDay,
      focusedDay: focusedDay,
      rowHeight: GridSize.popoverItemHeight,
      calendarFormat: format,
      daysOfWeekHeight: GridSize.popoverItemHeight,
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: textStyle,
        leftChevronMargin: EdgeInsets.zero,
        leftChevronPadding: EdgeInsets.zero,
        leftChevronIcon: svgWidget(
          "home/arrow_left",
          color: Theme.of(context).iconTheme.color,
        ),
        rightChevronPadding: EdgeInsets.zero,
        rightChevronMargin: EdgeInsets.zero,
        rightChevronIcon: svgWidget(
          "home/arrow_right",
          color: Theme.of(context).iconTheme.color,
        ),
        headerMargin: const EdgeInsets.only(bottom: 8.0),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        dowTextFormatter: (date, locale) =>
            DateFormat.E(locale).format(date).toUpperCase(),
        weekdayStyle: AFThemeExtension.of(context).caption,
        weekendStyle: AFThemeExtension.of(context).caption,
      ),
      calendarStyle: CalendarStyle(
        cellMargin: const EdgeInsets.all(3),
        defaultDecoration: defaultDecoration,
        selectedDecoration: defaultDecoration.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
        todayDecoration: defaultDecoration.copyWith(
          color: AFThemeExtension.of(context).lightGreyHover,
        ),
        weekendDecoration: defaultDecoration,
        outsideDecoration: defaultDecoration,
        defaultTextStyle: textStyle,
        weekendTextStyle: textStyle,
        selectedTextStyle: textStyle.copyWith(
          color: Theme.of(context).colorScheme.surface,
        ),
        todayTextStyle: textStyle,
        outsideTextStyle: textStyle.copyWith(
          color: Theme.of(context).disabledColor,
        ),
      ),
      selectedDayPredicate: (day) => isSameDay(selectedDate, day),
      onDaySelected: onDaySelected,
      onFormatChanged: onFormatChanged,
      onPageChanged: onPageChanged,
    );
  }

  BoxDecoration _defaultDecoration(BuildContext context) => BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.rectangle,
        borderRadius: Corners.s6Border,
      );
}
