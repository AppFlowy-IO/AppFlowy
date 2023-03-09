import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/row/row_data_controller.dart';
import 'package:appflowy/plugins/database_view/calendar/application/calendar_bloc.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/card/card_cell_builder.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../grid/presentation/layout/sizes.dart';
import '../../widgets/row/row_detail.dart';
import 'layout/sizes.dart';
import 'toolbar/calendar_toolbar.dart';

class CalendarPage extends StatefulWidget {
  final ViewPB view;
  const CalendarPage({required this.view, super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final _eventController = EventController<CalendarCardData>();
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
        child: BlocListener<CalendarBloc, CalendarState>(
          listenWhen: (previous, current) => previous.events != current.events,
          listener: (context, state) {
            if (state.events.isNotEmpty) {
              _eventController.removeWhere((element) => true);
              _eventController.addAll(state.events);
            }
          },
          child: BlocBuilder<CalendarBloc, CalendarState>(
            builder: (context, state) {
              return Column(
                children: [
                  // const _ToolbarBlocAdaptor(),
                  _toolbar(),
                  _buildCalendar(_eventController),
                ],
              );
            },
          ),
        ),
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

  Widget _calendarDayBuilder(
    DateTime date,
    List<CalendarEventData<CalendarCardData>> calenderEvents,
    isToday,
    isInMonth,
  ) {
    final builder = CardCellBuilder(_calendarBloc.cellCache);
    final cells = calenderEvents.map((value) => value.event!).map((event) {
      final child = builder.buildCell(cellId: event.cellId);

      return FlowyHover(
        child: GestureDetector(
          onTap: () {
            final dataController = RowController(
              rowId: event.cellId.rowId,
              viewId: widget.view.id,
              rowCache: _calendarBloc.rowCache,
            );

            FlowyOverlay.show(
              context: context,
              builder: (BuildContext context) {
                return RowDetailPage(
                  cellBuilder:
                      GridCellBuilder(cellCache: _calendarBloc.cellCache),
                  dataController: dataController,
                );
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: child,
          ),
        ),
      );
    }).toList();

    return _CalendarCard(
      isToday: isToday,
      isInMonth: isInMonth,
      date: date,
      children: cells,
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
}

class _CalendarCard extends StatelessWidget {
  final bool isToday;
  final bool isInMonth;
  final DateTime date;
  final List<Widget> children;
  final void Function(DateTime) onCreateEvent;

  const _CalendarCard({
    required this.isToday,
    required this.isInMonth,
    required this.date,
    required this.children,
    required this.onCreateEvent,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = Theme.of(context).colorScheme.surface;
    if (!isInMonth) {
      backgroundColor = AFThemeExtension.of(context).lightGreyHover;
    }

    return ChangeNotifierProvider(
      create: (_) => _CardEnterNotifier(),
      builder: ((context, child) {
        return Container(
          color: backgroundColor,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (p) => notifyEnter(context, true),
            onExit: (p) => notifyEnter(context, false),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  _Header(
                    date: date,
                    isInMonth: isInMonth,
                    isToday: isToday,
                    onCreate: () => onCreateEvent(date),
                  ),
                  ...children
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  notifyEnter(BuildContext context, bool isEnter) {
    Provider.of<_CardEnterNotifier>(
      context,
      listen: false,
    ).onEnter = isEnter;
  }
}

class _Header extends StatelessWidget {
  final bool isToday;
  final bool isInMonth;
  final DateTime date;
  final VoidCallback onCreate;
  const _Header({
    required this.isToday,
    required this.isInMonth,
    required this.date,
    required this.onCreate,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<_CardEnterNotifier>(
      builder: (context, notifier, _) {
        final badge = _DayBadge(
          isToday: isToday,
          isInMonth: isInMonth,
          date: date,
        );
        return Row(
          children: [
            if (notifier.onEnter) _NewEventButton(onClick: onCreate),
            const Spacer(),
            badge,
          ],
        );
      },
    );
  }
}

class _NewEventButton extends StatelessWidget {
  final VoidCallback onClick;
  const _NewEventButton({
    required this.onClick,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      onPressed: onClick,
      iconPadding: EdgeInsets.zero,
      icon: svgWidget(
        "home/add",
        color: Theme.of(context).colorScheme.onSurface,
      ),
      width: 22,
    );
  }
}

class _DayBadge extends StatelessWidget {
  final bool isToday;
  final bool isInMonth;
  final DateTime date;
  const _DayBadge({
    required this.isToday,
    required this.isInMonth,
    required this.date,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color dayTextColor = Theme.of(context).colorScheme.onSurface;
    String dayString = date.day == 1
        ? DateFormat('MMM d', context.locale.toLanguageTag()).format(date)
        : date.day.toString();

    if (isToday) {
      dayTextColor = Theme.of(context).colorScheme.onPrimary;
    }
    if (!isInMonth) {
      dayTextColor = Theme.of(context).disabledColor;
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

    return day;
  }
}

class _CardEnterNotifier extends ChangeNotifier {
  bool _onEnter = false;

  _CardEnterNotifier();

  set onEnter(bool value) {
    if (_onEnter != value) {
      _onEnter = value;
      notifyListeners();
    }
  }

  bool get onEnter => _onEnter;
}
