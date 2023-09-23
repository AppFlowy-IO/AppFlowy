import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy/plugins/database_view/calendar/application/calendar_bloc.dart';
import 'package:appflowy/plugins/database_view/calendar/application/unschedule_event_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database_view/tar_bar/tab_bar_view.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/calendar_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';

import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/row/row_cache.dart';
import '../../application/row/row_controller.dart';
import '../../widgets/row/cell_builder.dart';
import '../../widgets/row/row_detail.dart';
import 'calendar_day.dart';
import 'layout/sizes.dart';
import 'toolbar/calendar_setting_bar.dart';

class CalendarPageTabBarBuilderImpl implements DatabaseTabBarItemBuilder {
  @override
  Widget content(
    BuildContext context,
    ViewPB view,
    DatabaseController controller,
    bool shrinkWrap,
  ) {
    return CalendarPage(
      key: _makeValueKey(controller),
      view: view,
      databaseController: controller,
      shrinkWrap: shrinkWrap,
    );
  }

  @override
  Widget settingBar(BuildContext context, DatabaseController controller) {
    return CalendarSettingBar(
      key: _makeValueKey(controller),
      databaseController: controller,
    );
  }

  @override
  Widget settingBarExtension(
    BuildContext context,
    DatabaseController controller,
  ) {
    return SizedBox.fromSize();
  }

  ValueKey _makeValueKey(DatabaseController controller) {
    return ValueKey(controller.viewId);
  }
}

class CalendarPage extends StatefulWidget {
  final ViewPB view;
  final DatabaseController databaseController;
  final bool shrinkWrap;
  const CalendarPage({
    required this.view,
    required this.databaseController,
    this.shrinkWrap = false,
    super.key,
  });

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
    _calendarBloc = CalendarBloc(
      view: widget.view,
      databaseController: widget.databaseController,
    )..add(const CalendarEvent.initial());

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
      child: BlocProvider<CalendarBloc>.value(
        value: _calendarBloc,
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
              return ValueListenableBuilder<bool>(
                valueListenable: widget.databaseController.isLoading,
                builder: (_, value, ___) {
                  if (value) {
                    return const Center(
                      child: CircularProgressIndicator.adaptive(),
                    );
                  }
                  return _buildCalendar(
                    context,
                    _eventController,
                    state.settings
                        .foldLeft(0, (previous, a) => a.firstDayOfWeek),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar(
    BuildContext context,
    EventController eventController,
    int firstDayOfWeek,
  ) {
    return Padding(
      padding: CalendarSize.contentInsets,
      child: LayoutBuilder(
        // must specify MonthView width for useAvailableVerticalSpace to work properly
        builder: (context, constraints) => ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: MonthView(
            key: _calendarState,
            controller: _eventController,
            width: constraints.maxWidth,
            cellAspectRatio: 0.6,
            startDay: _weekdayFromInt(firstDayOfWeek),
            borderColor: Theme.of(context).dividerColor,
            headerBuilder: _headerNavigatorBuilder,
            weekDayBuilder: _headerWeekDayBuilder,
            cellBuilder: _calendarDayBuilder,
            useAvailableVerticalSpace: widget.shrinkWrap,
          ),
        ),
      ),
    );
  }

  Widget _headerNavigatorBuilder(DateTime currentMonth) {
    return SizedBox(
      height: 24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FlowyText.medium(
            DateFormat('MMMM y', context.locale.toLanguageTag())
                .format(currentMonth),
          ),
          const Spacer(),
          FlowyIconButton(
            width: CalendarSize.navigatorButtonWidth,
            height: CalendarSize.navigatorButtonHeight,
            icon: const FlowySvg(FlowySvgs.arrow_left_s),
            tooltipText: LocaleKeys.calendar_navigation_previousMonth.tr(),
            hoverColor: AFThemeExtension.of(context).lightGreyHover,
            onPressed: () => _calendarState?.currentState?.previousPage(),
          ),
          FlowyTextButton(
            LocaleKeys.calendar_navigation_today.tr(),
            fillColor: Colors.transparent,
            fontWeight: FontWeight.w400,
            fontSize: 10,
            tooltip: LocaleKeys.calendar_navigation_jumpToday.tr(),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            hoverColor: AFThemeExtension.of(context).lightGreyHover,
            onPressed: () =>
                _calendarState?.currentState?.animateToMonth(DateTime.now()),
          ),
          FlowyIconButton(
            width: CalendarSize.navigatorButtonWidth,
            height: CalendarSize.navigatorButtonHeight,
            icon: const FlowySvg(FlowySvgs.arrow_right_s),
            tooltipText: LocaleKeys.calendar_navigation_nextMonth.tr(),
            hoverColor: AFThemeExtension.of(context).lightGreyHover,
            onPressed: () => _calendarState?.currentState?.nextPage(),
          ),
          const HSpace(6.0),
          UnscheduledEventsButton(
            databaseController: widget.databaseController,
          ),
        ],
      ),
    );
  }

  Widget _headerWeekDayBuilder(day) {
    // incoming day starts from Monday, the symbols start from Sunday
    final symbols = DateFormat.EEEE(context.locale.toLanguageTag()).dateSymbols;
    final weekDayString = symbols.WEEKDAYS[(day + 1) % 7];
    return Center(
      child: Padding(
        padding: CalendarSize.daysOfWeekInsets,
        child: FlowyText.regular(
          weekDayString,
          fontSize: 9,
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
          CalendarEvent.createEvent(date),
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
  required CalendarEventPB event,
  required String viewId,
  required RowCache rowCache,
}) {
  final dataController = RowController(
    rowMeta: event.rowMeta,
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

class UnscheduledEventsButton extends StatefulWidget {
  final DatabaseController databaseController;

  const UnscheduledEventsButton({super.key, required this.databaseController});

  @override
  State<UnscheduledEventsButton> createState() =>
      _UnscheduledEventsButtonState();
}

class _UnscheduledEventsButtonState extends State<UnscheduledEventsButton> {
  late final PopoverController _popoverController;

  @override
  void initState() {
    super.initState();
    _popoverController = PopoverController();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UnscheduleEventsBloc>(
      create: (_) =>
          UnscheduleEventsBloc(databaseController: widget.databaseController)
            ..add(const UnscheduleEventsEvent.initial()),
      child: BlocBuilder<UnscheduleEventsBloc, UnscheduleEventsState>(
        builder: (context, state) {
          return AppFlowyPopover(
            direction: PopoverDirection.bottomWithCenterAligned,
            triggerActions: PopoverTriggerFlags.none,
            controller: _popoverController,
            offset: const Offset(0, 8),
            constraints: const BoxConstraints(maxWidth: 282, maxHeight: 600),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                  borderRadius: Corners.s6Border,
                ),
                side:
                    BorderSide(color: Theme.of(context).dividerColor, width: 1),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () {
                if (state.unscheduleEvents.isNotEmpty) {
                  _popoverController.show();
                }
              },
              child: FlowyText.regular(
                "${LocaleKeys.calendar_settings_noDateTitle.tr()} (${state.unscheduleEvents.length})",
                fontSize: 10,
              ),
            ),
            popupBuilder: (context) {
              return UnscheduleEventsList(
                viewId: widget.databaseController.viewId,
                rowCache: widget.databaseController.rowCache,
                unscheduleEvents: state.unscheduleEvents,
              );
            },
          );
        },
      ),
    );
  }
}

class UnscheduleEventsList extends StatelessWidget {
  final String viewId;
  final RowCache rowCache;
  final List<CalendarEventPB> unscheduleEvents;
  const UnscheduleEventsList({
    required this.viewId,
    required this.unscheduleEvents,
    required this.rowCache,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: FlowyText.medium(
          LocaleKeys.calendar_settings_clickToAdd.tr(),
          fontSize: 10,
          color: Theme.of(context).hintColor,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      ...unscheduleEvents.map(
        (e) => UnscheduledEventCell(
          event: e,
          onPressed: () {
            showEventDetails(
              context: context,
              event: e,
              viewId: viewId,
              rowCache: rowCache,
            );
            PopoverContainer.of(context).close();
          },
        ),
      )
    ];

    return ListView.separated(
      itemBuilder: (context, index) => cells[index],
      itemCount: cells.length,
      separatorBuilder: (context, index) =>
          VSpace(GridSize.typeOptionSeparatorHeight),
      shrinkWrap: true,
    );
  }
}

class UnscheduledEventCell extends StatelessWidget {
  final CalendarEventPB event;
  final VoidCallback onPressed;
  const UnscheduledEventCell({
    required this.event,
    required this.onPressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: FlowyButton(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        text: FlowyText.medium(
          event.title.isEmpty
              ? LocaleKeys.calendar_defaultNewCalendarTitle.tr()
              : event.title,
          fontSize: 11,
        ),
        onTap: onPressed,
      ),
    );
  }
}
