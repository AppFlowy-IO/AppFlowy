import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/calendar/application/calendar_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
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
  Widget build(BuildContext context) {
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
              listenWhen: (p, c) => p.initialEvents != c.initialEvents,
              listener: (context, state) {
                _eventController.removeWhere((_) => true);
                _eventController.addAll(state.initialEvents);
              },
            ),
            BlocListener<CalendarBloc, CalendarState>(
              listenWhen: (p, c) => p.deleteEventIds != c.deleteEventIds,
              listener: (context, state) {
                _eventController.removeWhere(
                  (element) =>
                      state.deleteEventIds.contains(element.event!.eventId),
                );
              },
            ),
            BlocListener<CalendarBloc, CalendarState>(
              listenWhen: (p, c) => p.editingEvent != c.editingEvent,
              listener: (context, state) {
                if (state.editingEvent != null) {
                  showEventDetails(
                    context: context,
                    event: state.editingEvent!.event!,
                    viewId: widget.view.id,
                    rowCache: _calendarBloc.rowCache,
                  );
                }
              },
            ),
            BlocListener<CalendarBloc, CalendarState>(
              // Event create by click the + button or double click on the
              // calendar
              listenWhen: (p, c) => p.newEvent != c.newEvent,
              listener: (context, state) {
                if (state.newEvent != null) {
                  _eventController.add(state.newEvent!);
                }
              },
            ),
            BlocListener<CalendarBloc, CalendarState>(
              // When an event is rescheduled
              listenWhen: (p, c) => p.updateEvent != c.updateEvent,
              listener: (context, state) {
                if (state.updateEvent != null) {
                  _eventController.removeWhere(
                    (element) =>
                        element.event!.eventId ==
                        state.updateEvent!.event!.eventId,
                  );
                  _eventController.add(state.updateEvent!);
                }
              },
            ),
          ],
          child: BlocBuilder<CalendarBloc, CalendarState>(
            builder: (context, state) {
              return Column(
                children: [
                  // const _ToolbarBlocAdaptor(),
                  const CalendarToolbar(),
                  _buildCalendar(
                    _eventController,
                    state.settings
                        .foldLeft(0, (previous, a) => a.firstDayOfWeek),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar(EventController eventController, int firstDayOfWeek) {
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

  Widget _headerWeekDayBuilder(day) {
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
    DateTime date,
    List<CalendarEventData<CalendarDayEvent>> calenderEvents,
    isToday,
    isInMonth,
  ) {
    final events = calenderEvents.map((value) => value.event!).toList();
    // Sort the events by timestamp. Because the database view is not
    // reserving the order of the events. Reserving the order of the rows/events
    // is implemnted in the develop branch(WIP). Will be replaced with that.
    events.sort(
      (a, b) => a.event.timestamp.compareTo(b.event.timestamp),
    );
    return CalendarDayCard(
      viewId: widget.view.id,
      isToday: isToday,
      isInMonth: isInMonth,
      events: events,
      date: date,
      rowCache: _calendarBloc.rowCache,
      onCreateEvent: (date) {
        _calendarBloc.add(
          CalendarEvent.createEvent(
            date,
            LocaleKeys.calendar_defaultNewCalendarTitle.tr(),
          ),
        );
      },
    );
  }

  WeekDays _weekdayFromInt(int dayOfWeek) {
    // dayOfWeek starts from Sunday, WeekDays starts from Monday
    return WeekDays.values[(dayOfWeek - 1) % 7];
  }
}

void showEventDetails({
  required BuildContext context,
  required CalendarDayEvent event,
  required String viewId,
  required RowCache rowCache,
}) {
  final dataController = RowController(
    rowId: event.eventId,
    viewId: viewId,
    rowCache: rowCache,
  );

  FlowyOverlay.show(
    context: context,
    builder: (BuildContext context) {
      return RowDetailPage(
        cellBuilder: GridCellBuilder(
          cellCache: rowCache.cellCache,
        ),
        rowController: dataController,
      );
    },
  );
}
