import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';

import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra/time/duration.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../grid/presentation/layout/sizes.dart';
import '../application/calendar_bloc.dart';
import 'calendar_event_card.dart';

class CalendarDayCard extends StatelessWidget {
  final String viewId;
  final bool isToday;
  final bool isInMonth;
  final DateTime date;
  final RowCache rowCache;
  final List<CalendarDayEvent> events;
  final void Function(DateTime) onCreateEvent;

  const CalendarDayCard({
    required this.viewId,
    required this.isToday,
    required this.isInMonth,
    required this.date,
    required this.onCreateEvent,
    required this.rowCache,
    required this.events,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = Colors.transparent;
    if (date.isWeekend) {
      backgroundColor = AFThemeExtension.of(context).calendarWeekendBGColor;
    }
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
                if (events.isNotEmpty)
                  _EventList(
                    events: events,
                    viewId: viewId,
                    rowCache: rowCache,
                    constraints: constraints,
                  ),
              ],
            );

            return Stack(
              children: <Widget>[
                GestureDetector(
                  onDoubleTap: () => onCreateEvent(date),
                  child: Container(color: backgroundColor),
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
                        if (candidate.isEmpty)
                          NewEventButton(onCreate: () => onCreateEvent(date)),
                      ],
                    );
                  },
                  onAccept: (CalendarDayEvent event) {
                    if (event.date == date) {
                      return;
                    }
                    context
                        .read<CalendarBloc>()
                        .add(CalendarEvent.moveEvent(event, date));
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
  const _Header({
    required this.isToday,
    required this.isInMonth,
    required this.date,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: _DayBadge(
        isToday: isToday,
        isInMonth: isInMonth,
        date: date,
      ),
    );
  }
}

@visibleForTesting
class NewEventButton extends StatelessWidget {
  final VoidCallback onCreate;
  const NewEventButton({required this.onCreate, Key? key}) : super(key: key);

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
            iconPadding: EdgeInsets.zero,
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
                  spreadRadius: 0,
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

    return SizedBox(
      height: 18,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (date.day == 1)
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
            width: isToday ? 18 : null,
            height: isToday ? 18 : null,
            // padding: GridSize.typeOptionContentInsets,
            child: Center(
              child: FlowyText.medium(
                dayString,
                fontSize: 11,
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
  final List<CalendarDayEvent> events;
  final String viewId;
  final RowCache rowCache;
  final BoxConstraints constraints;

  const _EventList({
    required this.events,
    required this.viewId,
    required this.rowCache,
    required this.constraints,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final editingEvent = context.watch<CalendarBloc>().state.editingEvent;
    return Flexible(
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          scrollbars: true,
        ),
        child: ListView.separated(
          itemBuilder: (BuildContext context, int index) {
            final autoEdit =
                editingEvent?.event?.eventId == events[index].eventId;
            return EventCard(
              event: events[index],
              viewId: viewId,
              rowCache: rowCache,
              constraints: constraints,
              autoEdit: autoEdit,
            );
          },
          itemCount: events.length,
          padding: const EdgeInsets.fromLTRB(4.0, 0, 4.0, 4.0),
          separatorBuilder: (BuildContext context, int index) =>
              VSpace(GridSize.typeOptionSeparatorHeight),
          shrinkWrap: true,
        ),
      ),
    );
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
