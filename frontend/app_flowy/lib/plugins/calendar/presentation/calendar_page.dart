import 'package:calendar_view/calendar_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

import 'toolbar/calendar_toolbar.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CalendarContent();
  }
}

class CalendarContent extends StatefulWidget {
  const CalendarContent({super.key});

  @override
  State<CalendarContent> createState() => _CalendarContentState();
}

class _CalendarContentState extends State<CalendarContent> {
  late EventController _eventController;
  GlobalKey<MonthViewState>? _calendarState;

  @override
  void initState() {
    _eventController = EventController();
    _calendarState = GlobalKey<MonthViewState>();
    // todo add events to the controller
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CalendarControllerProvider(
      controller: _eventController,
      child: Column(
        children: [
          // const _ToolbarBlocAdaptor(),
          _toolbar(),
          _buildCalendar(_eventController),
        ],
      ),
    );
  }

  Widget _toolbar() {
    return const CalendarToolbar();
  }

  Widget _buildCalendar(EventController eventController) {
    return Expanded(
      child: MonthView(
        key: _calendarState,
        controller: _eventController,
        cellAspectRatio: 1.75,
        borderColor: Theme.of(context).dividerColor,
        headerBuilder: _headerNavigatorBuilder,
        weekDayBuilder: _headerWeekDayBuilder,
        cellBuilder: _calendarDayBuilder,
      ),
    );
  }

  Widget _headerNavigatorBuilder(DateTime currentMonth) {
    return Row(
      children: [
        FlowyText.medium(
          DateFormat('MMMM y', context.locale.toLanguageTag())
              .format(currentMonth),
        ),
        const Spacer(),
        FlowyIconButton(
          width: 25,
          iconPadding: const EdgeInsets.symmetric(vertical: 2.0),
          icon: svgWidget('home/arrow_left'),
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
          onPressed: () => _calendarState?.currentState?.previousPage(),
        ),
        FlowyTextButton(
          "Today",
          fillColor: Colors.transparent,
          fontWeight: FontWeight.w500,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
          onPressed: () =>
              _calendarState?.currentState?.animateToMonth(DateTime.now()),
        ),
        FlowyIconButton(
          width: 25,
          iconPadding: const EdgeInsets.symmetric(vertical: 2.0),
          icon: svgWidget('home/arrow_right'),
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
          onPressed: () => _calendarState?.currentState?.nextPage(),
        ),
      ],
    );
  }

  Widget _headerWeekDayBuilder(day) {
    final symbols = DateFormat.EEEE(context.locale.toLanguageTag()).dateSymbols;
    final weekDayString = symbols.WEEKDAYS[day];
    return Center(
      child: FlowyText(
        weekDayString,
        color: Theme.of(context).hintColor,
      ),
    ).padding(vertical: 10.0);
  }

  Widget _calendarDayBuilder(date, event, isToday, isInMonth) {
    // todo get events for day and create cards for them.
    // todo

    return Container(
      color: isInMonth
          ? Theme.of(context).colorScheme.surface
          : AFThemeExtension.of(context).lightGreyHover,
      child: Align(
        alignment: Alignment.topRight,
        child: Container(
          margin: const EdgeInsets.all(6.0),
          decoration: BoxDecoration(
            color: isToday ? Theme.of(context).colorScheme.primary : null,
            borderRadius: Corners.s6Border,
          ),
          padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 6.0),
          child: FlowyText(
            date.day == 1
                ? DateFormat('MMM d', context.locale.toLanguageTag())
                    .format(date)
                : date.day.toString(),
            color: isToday ? Theme.of(context).colorScheme.onPrimary : null,
          ),
        ),
      ),
    );
  }
}
