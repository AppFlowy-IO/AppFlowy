import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/common/type_option_separator.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/include_time_button.dart';
import 'package:appflowy_backend/protobuf/flowy-user/date_time.pbenum.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

final kFirstDay = DateTime.utc(1970, 1, 1);
final kLastDay = DateTime.utc(2100, 1, 1);

class AppFlowyCalendar extends StatefulWidget {
  const AppFlowyCalendar({
    super.key,
    this.popoverMutex,
    this.firstDay,
    this.lastDay,
    this.selectedDate,
    required this.focusedDay,
    required this.format,
    this.onDaySelected,
    this.onFormatChanged,
    this.onPageChanged,
    this.onIncludeTimeChanged,
    this.onTimeChanged,
    this.includeTime = false,
    this.timeFormat = TimeFormatPB.TwentyFourHour,
  });

  final PopoverMutex? popoverMutex;

  /// Disallows choosing dates before this date
  final DateTime? firstDay;

  /// Disallows choosing dates after this date
  final DateTime? lastDay;

  final DateTime? selectedDate;
  final DateTime focusedDay;
  final CalendarFormat format;

  final void Function(
    DateTime selectedDay,
    DateTime focusedDay,
    bool includeTime,
  )? onDaySelected;

  final void Function(bool includeTime)? onIncludeTimeChanged;
  final void Function(CalendarFormat format)? onFormatChanged;
  final void Function(DateTime focusedDay)? onPageChanged;
  final void Function(String? time)? onTimeChanged;

  final bool includeTime;

  // Timeformat for time selector
  final TimeFormatPB timeFormat;

  @override
  State<AppFlowyCalendar> createState() => _AppFlowyCalendarState();
}

class _AppFlowyCalendarState extends State<AppFlowyCalendar> {
  late bool _includeTime = widget.includeTime;
  String? _time;

  @override
  void initState() {
    super.initState();
    if (widget.includeTime) {
      final hour = widget.focusedDay.hour;
      final minute = widget.focusedDay.minute;
      _time = '$hour:$minute';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium!;
    final defaultDecoration = _defaultDecoration(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: TableCalendar(
            firstDay: widget.firstDay ?? kFirstDay,
            lastDay: widget.lastDay ?? kLastDay,
            focusedDay: widget.focusedDay,
            rowHeight: GridSize.popoverItemHeight,
            calendarFormat: widget.format,
            daysOfWeekHeight: GridSize.popoverItemHeight,
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
            selectedDayPredicate: (day) => isSameDay(widget.selectedDate, day),
            onDaySelected: (selectedDay, focusedDay) {
              if (!_includeTime) {
                widget.onDaySelected?.call(
                  selectedDay,
                  focusedDay,
                  _includeTime,
                );
              }

              _updateSelectedDay(selectedDay, focusedDay, _includeTime);
            },
            onFormatChanged: widget.onFormatChanged,
            onPageChanged: widget.onPageChanged,
          ),
        ),
        const TypeOptionSeparator(spacing: 12.0),
        IncludeTimeButton(
          initialTime: widget.selectedDate != null
              ? _initialTime(widget.selectedDate!)
              : null,
          includeTime: widget.includeTime,
          timeFormat: widget.timeFormat,
          popoverMutex: widget.popoverMutex,
          onChanged: (includeTime) {
            setState(() {
              _includeTime = includeTime;
            });

            widget.onIncludeTimeChanged?.call(includeTime);
          },
          onSubmitted: (time) {
            _time = time;

            if (widget.selectedDate != null && widget.onTimeChanged == null) {
              _updateSelectedDay(
                widget.selectedDate!,
                widget.selectedDate!,
                _includeTime,
              );
            }

            widget.onTimeChanged?.call(time);
          },
        ),
      ],
    );
  }

  BoxDecoration _defaultDecoration(BuildContext context) => BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.rectangle,
        borderRadius: Corners.s6Border,
      );

  DateTime _dateWithTime(DateTime date, DateTime time) {
    return DateTime.parse(
      '${date.year}${_padZeroLeft(date.month)}${_padZeroLeft(date.day)} ${_padZeroLeft(time.hour)}:${_padZeroLeft(time.minute)}',
    );
  }

  String _initialTime(DateTime selectedDay) => switch (widget.timeFormat) {
        TimeFormatPB.TwelveHour => DateFormat.jm().format(selectedDay),
        TimeFormatPB.TwentyFourHour => DateFormat.Hm().format(selectedDay),
        _ => '00:00',
      };

  String _padZeroLeft(int a) => a.toString().padLeft(2, '0');

  void _updateSelectedDay(
    DateTime selectedDay,
    DateTime focusedDay,
    bool includeTime,
  ) {
    switch (widget.timeFormat) {
      case TimeFormatPB.TwelveHour:
        final timeOfDay = DateFormat.jm().parse(_time ?? '12:00 AM');

        widget.onDaySelected?.call(
          _dateWithTime(selectedDay, timeOfDay),
          focusedDay,
          _includeTime,
        );
        break;
      case TimeFormatPB.TwentyFourHour:
        final timeOfDay = DateFormat.Hm().parse(_time ?? '00:00');

        widget.onDaySelected?.call(
          _dateWithTime(selectedDay, timeOfDay),
          focusedDay,
          _includeTime,
        );
        break;
    }
  }
}
