import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:universal_platform/universal_platform.dart';

final kFirstDay = DateTime.utc(1970);
final kLastDay = DateTime.utc(2100);

class DatePicker extends StatefulWidget {
  const DatePicker({
    super.key,
    required this.isRange,
    this.calendarFormat = CalendarFormat.month,
    this.startDay,
    this.endDay,
    this.selectedDay,
    required this.focusedDay,
    this.onDaySelected,
    this.onRangeSelected,
    this.onCalendarCreated,
    this.onPageChanged,
  });

  final bool isRange;
  final CalendarFormat calendarFormat;

  final DateTime? startDay;
  final DateTime? endDay;
  final DateTime? selectedDay;

  final DateTime focusedDay;

  final void Function(
    DateTime selectedDay,
    DateTime focusedDay,
  )? onDaySelected;

  final void Function(
    DateTime? start,
    DateTime? end,
    DateTime focusedDay,
  )? onRangeSelected;

  final void Function(PageController pageController)? onCalendarCreated;

  final void Function(DateTime focusedDay)? onPageChanged;

  @override
  State<DatePicker> createState() => _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {
  late CalendarFormat _calendarFormat = widget.calendarFormat;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium!;
    final boxDecoration = BoxDecoration(
      color: Theme.of(context).cardColor,
      shape: BoxShape.circle,
    );

    final calendarStyle = UniversalPlatform.isMobile
        ? _CalendarStyle.mobile(
            dowTextStyle: textStyle.copyWith(
              color: Theme.of(context).hintColor,
              fontSize: 14.0,
            ),
          )
        : _CalendarStyle.desktop(
            dowTextStyle: AFThemeExtension.of(context).caption,
            selectedColor: Theme.of(context).colorScheme.primary,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TableCalendar(
        firstDay: kFirstDay,
        lastDay: kLastDay,
        focusedDay: widget.focusedDay,
        rowHeight: calendarStyle.rowHeight,
        calendarFormat: _calendarFormat,
        daysOfWeekHeight: calendarStyle.dowHeight,
        rangeSelectionMode: widget.isRange
            ? RangeSelectionMode.enforced
            : RangeSelectionMode.disabled,
        rangeStartDay: widget.isRange ? widget.startDay : null,
        rangeEndDay: widget.isRange ? widget.endDay : null,
        availableGestures: calendarStyle.availableGestures,
        availableCalendarFormats: const {CalendarFormat.month: 'Month'},
        onCalendarCreated: widget.onCalendarCreated,
        headerVisible: calendarStyle.headerVisible,
        headerStyle: calendarStyle.headerStyle,
        calendarStyle: CalendarStyle(
          cellMargin: const EdgeInsets.all(3.5),
          defaultDecoration: boxDecoration,
          selectedDecoration: boxDecoration.copyWith(
            color: calendarStyle.selectedColor,
          ),
          todayDecoration: boxDecoration.copyWith(
            color: Colors.transparent,
            border: Border.all(color: calendarStyle.selectedColor),
          ),
          weekendDecoration: boxDecoration,
          outsideDecoration: boxDecoration,
          rangeStartDecoration: boxDecoration.copyWith(
            color: calendarStyle.selectedColor,
          ),
          rangeEndDecoration: boxDecoration.copyWith(
            color: calendarStyle.selectedColor,
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
            final label = DateFormat.E(locale).format(day);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Center(
                child: Text(label, style: calendarStyle.dowTextStyle),
              ),
            );
          },
        ),
        selectedDayPredicate: (day) =>
            widget.isRange ? false : isSameDay(widget.selectedDay, day),
        onFormatChanged: (calendarFormat) =>
            setState(() => _calendarFormat = calendarFormat),
        onPageChanged: (focusedDay) {
          widget.onPageChanged?.call(focusedDay);
        },
        onDaySelected: widget.onDaySelected,
        onRangeSelected: widget.onRangeSelected,
      ),
    );
  }
}

class _CalendarStyle {
  _CalendarStyle.desktop({
    required this.selectedColor,
    required this.dowTextStyle,
  })  : rowHeight = 33,
        dowHeight = 35,
        headerVisible = false,
        headerStyle = const HeaderStyle(),
        availableGestures = AvailableGestures.horizontalSwipe;

  _CalendarStyle.mobile({required this.dowTextStyle})
      : rowHeight = 48,
        dowHeight = 48,
        headerVisible = false,
        headerStyle = const HeaderStyle(),
        selectedColor = const Color(0xFF00BCF0),
        availableGestures = AvailableGestures.horizontalSwipe;

  _CalendarStyle({
    required this.rowHeight,
    required this.dowHeight,
    required this.headerVisible,
    required this.headerStyle,
    required this.dowTextStyle,
    required this.selectedColor,
    required this.availableGestures,
  });

  final double rowHeight;
  final double dowHeight;
  final bool headerVisible;
  final HeaderStyle headerStyle;
  final TextStyle dowTextStyle;
  final Color selectedColor;
  final AvailableGestures availableGestures;
}
