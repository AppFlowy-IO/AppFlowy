import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/common/type_option_separator.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/include_time_button.dart';
import 'package:appflowy_backend/protobuf/flowy-user/date_time.pbenum.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

final kFirstDay = DateTime.utc(1970, 1, 1);
final kLastDay = DateTime.utc(2100, 1, 1);

typedef DaySelectedCallback = void Function(
  DateTime selectedDay,
  DateTime focusedDay,
  bool includeTime,
);
typedef IncludeTimeChangedCallback = void Function(bool includeTime);
typedef FormatChangedCallback = void Function(CalendarFormat format);
typedef PageChangedCallback = void Function(DateTime focusedDay);
typedef TimeChangedCallback = void Function(String? time);

class AppFlowyCalendar extends StatefulWidget {
  const AppFlowyCalendar({
    super.key,
    this.popoverMutex,
    this.firstDay,
    this.lastDay,
    this.selectedDate,
    required this.focusedDay,
    this.format = CalendarFormat.month,
    this.onDaySelected,
    this.onFormatChanged,
    this.onPageChanged,
    this.onIncludeTimeChanged,
    this.onTimeChanged,
    this.includeTime = false,
    this.timeFormat = UserTimeFormatPB.TwentyFourHour,
  });

  final PopoverMutex? popoverMutex;

  /// Disallows choosing dates before this date
  final DateTime? firstDay;

  /// Disallows choosing dates after this date
  final DateTime? lastDay;

  final DateTime? selectedDate;
  final DateTime focusedDay;
  final CalendarFormat format;

  final DaySelectedCallback? onDaySelected;
  final IncludeTimeChangedCallback? onIncludeTimeChanged;
  final FormatChangedCallback? onFormatChanged;
  final PageChangedCallback? onPageChanged;
  final TimeChangedCallback? onTimeChanged;

  final bool includeTime;

  // Timeformat for time selector
  final UserTimeFormatPB timeFormat;

  @override
  State<AppFlowyCalendar> createState() => _AppFlowyCalendarState();
}

class _AppFlowyCalendarState extends State<AppFlowyCalendar>
    with AutomaticKeepAliveClientMixin {
  String? _time;

  late DateTime? _selectedDay = widget.selectedDate;
  late DateTime _focusedDay = widget.focusedDay;
  late bool _includeTime = widget.includeTime;

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
    super.build(context);

    final textStyle = Theme.of(context).textTheme.bodyMedium!;
    final boxDecoration = BoxDecoration(
      color: Theme.of(context).cardColor,
      shape: BoxShape.circle,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const VSpace(18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: TableCalendar(
            currentDay: DateTime.now(),
            firstDay: widget.firstDay ?? kFirstDay,
            lastDay: widget.lastDay ?? kLastDay,
            focusedDay: _focusedDay,
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
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                ),
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
              rangeHighlightColor:
                  Theme.of(context).colorScheme.secondaryContainer,
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
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              if (!_includeTime) {
                widget.onDaySelected?.call(
                  selectedDay,
                  focusedDay,
                  _includeTime,
                );
              }

              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });

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
            setState(() => _includeTime = includeTime);

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
        const VSpace(6.0),
      ],
    );
  }

  DateTime _dateWithTime(DateTime date, DateTime time) {
    return DateTime.parse(
      '${date.year}${_padZeroLeft(date.month)}${_padZeroLeft(date.day)} ${_padZeroLeft(time.hour)}:${_padZeroLeft(time.minute)}',
    );
  }

  String _initialTime(DateTime selectedDay) => switch (widget.timeFormat) {
        UserTimeFormatPB.TwelveHour => DateFormat.jm().format(selectedDay),
        UserTimeFormatPB.TwentyFourHour => DateFormat.Hm().format(selectedDay),
        _ => '00:00',
      };

  String _padZeroLeft(int a) => a.toString().padLeft(2, '0');

  void _updateSelectedDay(
    DateTime selectedDay,
    DateTime focusedDay,
    bool includeTime,
  ) {
    late DateTime timeOfDay;
    switch (widget.timeFormat) {
      case UserTimeFormatPB.TwelveHour:
        timeOfDay = DateFormat.jm().parse(_time ?? '12:00 AM');
        break;
      case UserTimeFormatPB.TwentyFourHour:
        timeOfDay = DateFormat.Hm().parse(_time ?? '00:00');
        break;
    }

    widget.onDaySelected?.call(
      _dateWithTime(selectedDay, timeOfDay),
      focusedDay,
      _includeTime,
    );
  }

  @override
  bool get wantKeepAlive => true;
}
