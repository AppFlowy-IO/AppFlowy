import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/calendar/application/calendar_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/row/row_cache.dart';
import '../../application/row/row_data_controller.dart';
import '../../widgets/row/cell_builder.dart';
import '../../widgets/row/row_detail.dart';
import 'calendar_day.dart';
import 'layout/sizes.dart';
import 'toolbar/calendar_toolbar.dart';

class CalendarPage extends StatefulWidget {
  final ViewPB view;
  const CalendarPage({required this.view, super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final _eventController = EventController<CalendarDayEvent>();
  GlobalKey<MonthViewState>? _calendarState;
  late CalendarBloc _calendarBloc;

  @override
  void initState() {
    _calendarState = GlobalKey<MonthViewState>();
    _calendarBloc = CalendarBloc(view: widget.view)
      ..add(const CalendarEvent.initial());

    super.initState();
  }

  @override
  void dispose() {
    _calendarBloc.close();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return CalendarControllerProvider(
      controller: _eventController,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<CalendarBloc>.value(
            value: _calendarBloc,
          )
        ],
        child: MultiBlocListener(
          listeners: [
            BlocListener<CalendarBloc, CalendarState>(
              listenWhen: (final p, final c) => p.initialEvents != c.initialEvents,
              listener: (final context, final state) {
                _eventController.removeWhere((final _) => true);
                _eventController.addAll(state.initialEvents);
              },
            ),
            BlocListener<CalendarBloc, CalendarState>(
              listenWhen: (final p, final c) => p.deleteEventIds != c.deleteEventIds,
              listener: (final context, final state) {
                _eventController.removeWhere(
                  (final element) =>
                      state.deleteEventIds.contains(element.event!.eventId),
                );
              },
            ),
            BlocListener<CalendarBloc, CalendarState>(
              listenWhen: (final p, final c) => p.editEvent != c.editEvent,
              listener: (final context, final state) {
                if (state.editEvent != null) {
                  showEventDetails(
                    context: context,
                    event: state.editEvent!.event!,
                    viewId: widget.view.id,
                    rowCache: _calendarBloc.rowCache,
                  );
                }
              },
            ),
            BlocListener<CalendarBloc, CalendarState>(
              // Event create by click the + button or double click on the
              // calendar
              listenWhen: (final p, final c) => p.newEvent != c.newEvent,
              listener: (final context, final state) {
                if (state.newEvent != null) {
                  _eventController.add(state.newEvent!);
                }
              },
            ),
          ],
          child: BlocBuilder<CalendarBloc, CalendarState>(
            builder: (final context, final state) {
              return Column(
                children: [
                  // const _ToolbarBlocAdaptor(),
                  const CalendarToolbar(),
                  _buildCalendar(
                    _eventController,
                    state.settings
                        .foldLeft(0, (final previous, final a) => a.firstDayOfWeek),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar(final EventController eventController, final int firstDayOfWeek) {
    return Expanded(
      child: MonthView(
        key: _calendarState,
        controller: _eventController,
        cellAspectRatio: .6,
        startDay: _weekdayFromInt(firstDayOfWeek),
        borderColor: Theme.of(context).dividerColor,
        headerBuilder: _headerNavigatorBuilder,
        weekDayBuilder: _headerWeekDayBuilder,
        cellBuilder: _calendarDayBuilder,
      ),
    );
  }

  Widget _headerNavigatorBuilder(final DateTime currentMonth) {
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
          icon: const FlowySvg(name: 'home/arrow_left'),
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
          icon: const FlowySvg(name: 'home/arrow_right'),
          tooltipText: LocaleKeys.calendar_navigation_nextMonth.tr(),
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
          onPressed: () => _calendarState?.currentState?.nextPage(),
        ),
      ],
    );
  }

  Widget _headerWeekDayBuilder(final day) {
    // incoming day starts from Monday, the symbols start from Sunday
    final symbols = DateFormat.EEEE(context.locale.toLanguageTag()).dateSymbols;
    final weekDayString = symbols.WEEKDAYS[(day + 1) % 7];
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

  Widget _calendarDayBuilder(
    final DateTime date,
    final List<CalendarEventData<CalendarDayEvent>> calenderEvents,
    final isToday,
    final isInMonth,
  ) {
    final events = calenderEvents.map((final value) => value.event!).toList();
    // Sort the events by timestamp. Because the database view is not
    // reserving the order of the events. Reserving the order of the rows/events
    // is implemnted in the develop branch(WIP). Will be replaced with that.
    events.sort(
      (final a, final b) => a.event.timestamp.compareTo(b.event.timestamp),
    );
    return CalendarDayCard(
      viewId: widget.view.id,
      isToday: isToday,
      isInMonth: isInMonth,
      events: events,
      date: date,
      rowCache: _calendarBloc.rowCache,
      onCreateEvent: (final date) {
        _calendarBloc.add(
          CalendarEvent.createEvent(
            date,
            LocaleKeys.calendar_defaultNewCalendarTitle.tr(),
          ),
        );
      },
    );
  }

  WeekDays _weekdayFromInt(final int dayOfWeek) {
    // dayOfWeek starts from Sunday, WeekDays starts from Monday
    return WeekDays.values[(dayOfWeek - 1) % 7];
  }
}

void showEventDetails({
  required final BuildContext context,
  required final CalendarDayEvent event,
  required final String viewId,
  required final RowCache rowCache,
}) {
  final dataController = RowController(
    rowId: event.eventId,
    viewId: viewId,
    rowCache: rowCache,
  );

  FlowyOverlay.show(
    context: context,
    builder: (final BuildContext context) {
      return RowDetailPage(
        cellBuilder: GridCellBuilder(
          cellCache: rowCache.cellCache,
        ),
        dataController: dataController,
      );
    },
  );
}
