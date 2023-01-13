import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/plugins/grid/presentation/layout/sizes.dart';
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

import 'layout/sizes.dart';
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
          width: CalendarSize.navigatorButtonWidth,
          height: CalendarSize.navigatorButtonHeight,
          icon: svgWidget('home/arrow_left'),
          tooltipText: LocaleKeys.calendar_navigation_previousMonth.tr(),
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
          onPressed: () => _calendarState?.currentState?.previousPage(),
        ),
        FlowyTextButton(
          LocaleKeys.calendar_navigation_today.tr(),
          fillColor: Colors.transparent,
          fontWeight: FontWeight.w500,
          tooltip: LocaleKeys.calendar_navigation_jumpToday.tr(),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
          onPressed: () =>
              _calendarState?.currentState?.animateToMonth(DateTime.now()),
        ),
        FlowyIconButton(
          width: CalendarSize.navigatorButtonWidth,
          height: CalendarSize.navigatorButtonHeight,
          icon: svgWidget('home/arrow_right'),
          tooltipText: LocaleKeys.calendar_navigation_nextMonth.tr(),
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
      child: Padding(
        padding: CalendarSize.daysOfWeekInsets,
        child: FlowyText.medium(
          weekDayString,
          color: Theme.of(context).hintColor,
        ),
      ),
    );
  }

  Widget _calendarDayBuilder(date, event, isToday, isInMonth) {
    Color dayTextColor = Theme.of(context).colorScheme.onSurface;
    Color cellBackgroundColor = Theme.of(context).colorScheme.surface;
    String dayString = date.day == 1
        ? DateFormat('MMM d', context.locale.toLanguageTag()).format(date)
        : date.day.toString();

    if (isToday) {
      dayTextColor = Theme.of(context).colorScheme.onPrimary;
    }
    if (!isInMonth) {
      dayTextColor = Theme.of(context).disabledColor;
      cellBackgroundColor = AFThemeExtension.of(context).lightGreyHover;
    }
    Widget day = Container(
      decoration: BoxDecoration(
        color: isToday ? Theme.of(context).colorScheme.primary : null,
        borderRadius: Corners.s6Border,
      ),
      padding: GridSize.typeOptionContentInsets,
      child: FlowyText.medium(
        dayString,
        color: dayTextColor,
      ),
    );

    return Container(
      color: cellBackgroundColor,
      child: Align(
        alignment: Alignment.topRight,
        child: day.padding(all: 6.0),
      ),
    );
  }
}
