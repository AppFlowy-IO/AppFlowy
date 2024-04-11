import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/database/mobile_calendar_events_screen.dart';
import 'package:appflowy/plugins/database/application/row/row_cache.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra/time/duration.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../grid/presentation/layout/sizes.dart';
import '../application/calendar_bloc.dart';
import 'calendar_event_card.dart';

class CalendarDayCard extends StatelessWidget {
  const CalendarDayCard({
    super.key,
    required this.viewId,
    required this.isToday,
    required this.isInMonth,
    required this.date,
    required this.rowCache,
    required this.events,
    required this.onCreateEvent,
    required this.position,
  });

  final String viewId;
  final bool isToday;
  final bool isInMonth;
  final DateTime date;
  final RowCache rowCache;
  final List<CalendarDayEvent> events;
  final void Function(DateTime) onCreateEvent;
  final CellPosition position;

  @override
  Widget build(BuildContext context) {
    final hoverBackgroundColor =
        Theme.of(context).brightness == Brightness.light
            ? Theme.of(context).colorScheme.secondaryContainer
            : Colors.transparent;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return ChangeNotifierProvider(
          create: (_) => _CardEnterNotifier(),
          builder: (context, child) {
            final child = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Header(
                  date: date,
                  isInMonth: isInMonth,
                  isToday: isToday,
                ),

                // Add a separator between the header and the content.
                const VSpace(6.0),

                // List of cards or empty space
                if (events.isNotEmpty && !PlatformExtension.isMobile) ...[
                  _EventList(
                    events: events,
                    viewId: viewId,
                    rowCache: rowCache,
                    constraints: constraints,
                  ),
                ] else if (events.isNotEmpty && PlatformExtension.isMobile) ...[
                  const _EventIndicator(),
                ],
              ],
            );

            return Stack(
              children: [
                GestureDetector(
                  onDoubleTap: () => onCreateEvent(date),
                  onTap: PlatformExtension.isMobile
                      ? () => _mobileOnTap(context)
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: date.isWeekend
                          ? AFThemeExtension.of(context).calendarWeekendBGColor
                          : Colors.transparent,
                      border: _borderFromPosition(context, position),
                    ),
                  ),
                ),
                DragTarget<CalendarDayEvent>(
                  builder: (context, candidate, __) {
                    return Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          color:
                              candidate.isEmpty ? null : hoverBackgroundColor,
                          padding: const EdgeInsets.only(top: 5.0),
                          child: child,
                        ),
                        if (candidate.isEmpty && !PlatformExtension.isMobile)
                          NewEventButton(
                            onCreate: () => onCreateEvent(date),
                          ),
                      ],
                    );
                  },
                  onAcceptWithDetails: (details) {
                    final event = details.data;
                    if (event.date != date) {
                      context
                          .read<CalendarBloc>()
                          .add(CalendarEvent.moveEvent(event, date));
                    }
                  },
                ),
                MouseRegion(
                  onEnter: (p) => notifyEnter(context, true),
                  onExit: (p) => notifyEnter(context, false),
                  opaque: false,
                  hitTestBehavior: HitTestBehavior.translucent,
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _mobileOnTap(BuildContext context) {
    context.push(
      MobileCalendarEventsScreen.routeName,
      extra: {
        MobileCalendarEventsScreen.calendarBlocKey:
            context.read<CalendarBloc>(),
        MobileCalendarEventsScreen.calendarDateKey: date,
        MobileCalendarEventsScreen.calendarEventsKey: events,
        MobileCalendarEventsScreen.calendarRowCacheKey: rowCache,
        MobileCalendarEventsScreen.calendarViewIdKey: viewId,
      },
    );
  }

  bool notifyEnter(BuildContext context, bool isEnter) =>
      Provider.of<_CardEnterNotifier>(context, listen: false).onEnter = isEnter;

  Border _borderFromPosition(BuildContext context, CellPosition position) {
    final BorderSide borderSide =
        BorderSide(color: Theme.of(context).dividerColor);

    return Border(
      top: borderSide,
      left: borderSide,
      bottom: [
        CellPosition.bottom,
        CellPosition.bottomLeft,
        CellPosition.bottomRight,
      ].contains(position)
          ? borderSide
          : BorderSide.none,
      right: [
        CellPosition.topRight,
        CellPosition.bottomRight,
        CellPosition.right,
      ].contains(position)
          ? borderSide
          : BorderSide.none,
    );
  }
}

class _EventIndicator extends StatelessWidget {
  const _EventIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).hintColor,
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.isToday,
    required this.isInMonth,
    required this.date,
  });

  final bool isToday;
  final bool isInMonth;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: _DayBadge(isToday: isToday, isInMonth: isInMonth, date: date),
    );
  }
}

@visibleForTesting
class NewEventButton extends StatelessWidget {
  const NewEventButton({super.key, required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Consumer<_CardEnterNotifier>(
      builder: (context, notifier, _) {
        if (!notifier.onEnter) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.all(4.0),
          child: FlowyIconButton(
            onPressed: onCreate,
            icon: const FlowySvg(FlowySvgs.add_s),
            fillColor: Theme.of(context).colorScheme.background,
            hoverColor: AFThemeExtension.of(context).lightGreyHover,
            width: 22,
            tooltipText: LocaleKeys.calendar_newEventButtonTooltip.tr(),
            decoration: BoxDecoration(
              border: Border.fromBorderSide(
                BorderSide(
                  color: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xffd0d3d6)
                      : const Color(0xff59647a),
                  width: 0.5,
                ),
              ),
              borderRadius: Corners.s5Border,
              boxShadow: [
                BoxShadow(
                  spreadRadius: -2,
                  color: const Color(0xFF1F2329).withOpacity(0.02),
                  blurRadius: 2,
                ),
                BoxShadow(
                  color: const Color(0xFF1F2329).withOpacity(0.02),
                  blurRadius: 4,
                ),
                BoxShadow(
                  spreadRadius: 2,
                  color: const Color(0xFF1F2329).withOpacity(0.02),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DayBadge extends StatelessWidget {
  const _DayBadge({
    required this.isToday,
    required this.isInMonth,
    required this.date,
  });

  final bool isToday;
  final bool isInMonth;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    Color dayTextColor = Theme.of(context).colorScheme.onBackground;
    Color monthTextColor = Theme.of(context).colorScheme.onBackground;
    final String monthString =
        DateFormat("MMM ", context.locale.toLanguageTag()).format(date);
    final String dayString = date.day.toString();

    if (!isInMonth) {
      dayTextColor = Theme.of(context).disabledColor;
      monthTextColor = Theme.of(context).disabledColor;
    }
    if (isToday) {
      dayTextColor = Theme.of(context).colorScheme.onPrimary;
    }

    final double size = PlatformExtension.isMobile ? 20 : 18;

    return SizedBox(
      height: size,
      child: Row(
        mainAxisAlignment: PlatformExtension.isMobile
            ? MainAxisAlignment.center
            : MainAxisAlignment.end,
        children: [
          if (date.day == 1 && !PlatformExtension.isMobile)
            FlowyText.medium(
              monthString,
              fontSize: 11,
              color: monthTextColor,
            ),
          Container(
            decoration: BoxDecoration(
              color: isToday ? Theme.of(context).colorScheme.primary : null,
              borderRadius: BorderRadius.circular(10),
            ),
            width: isToday ? size : null,
            height: isToday ? size : null,
            child: Center(
              child: FlowyText.medium(
                dayString,
                fontSize: PlatformExtension.isMobile ? 12 : 11,
                color: dayTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventList extends StatelessWidget {
  const _EventList({
    required this.events,
    required this.viewId,
    required this.rowCache,
    required this.constraints,
  });

  final List<CalendarDayEvent> events;
  final String viewId;
  final RowCache rowCache;
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final editingEvent = context.watch<CalendarBloc>().state.editingEvent;

    return Flexible(
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: true),
        child: ListView.separated(
          itemBuilder: (BuildContext context, int index) {
            final autoEdit =
                editingEvent?.event?.eventId == events[index].eventId;
            return EventCard(
              databaseController:
                  context.read<CalendarBloc>().databaseController,
              event: events[index],
              constraints: constraints,
              autoEdit: autoEdit,
            );
          },
          itemCount: events.length,
          padding: const EdgeInsets.fromLTRB(4.0, 0, 4.0, 4.0),
          separatorBuilder: (_, __) =>
              VSpace(GridSize.typeOptionSeparatorHeight),
          shrinkWrap: true,
        ),
      ),
    );
  }
}

class _CardEnterNotifier extends ChangeNotifier {
  _CardEnterNotifier();

  bool _onEnter = false;

  set onEnter(bool value) {
    if (_onEnter != value) {
      _onEnter = value;
      notifyListeners();
    }
  }

  bool get onEnter => _onEnter;
}
