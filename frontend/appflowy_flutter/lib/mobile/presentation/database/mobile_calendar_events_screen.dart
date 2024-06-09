import 'package:appflowy/mobile/presentation/base/app_bar/app_bar.dart';
import 'package:appflowy/mobile/presentation/database/mobile_calendar_events_empty.dart';
import 'package:appflowy/plugins/database/application/row/row_cache.dart';
import 'package:appflowy/plugins/database/calendar/application/calendar_bloc.dart';
import 'package:appflowy/plugins/database/calendar/presentation/calendar_event_card.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileCalendarEventsScreen extends StatefulWidget {
  const MobileCalendarEventsScreen({
    super.key,
    required this.calendarBloc,
    required this.date,
    required this.events,
    required this.rowCache,
    required this.viewId,
  });

  final CalendarBloc calendarBloc;
  final DateTime date;
  final List<CalendarDayEvent> events;
  final RowCache rowCache;
  final String viewId;

  static const routeName = '/calendar_events';

  // GoRouter Arguments
  static const calendarBlocKey = 'calendar_bloc';
  static const calendarDateKey = 'date';
  static const calendarEventsKey = 'events';
  static const calendarRowCacheKey = 'row_cache';
  static const calendarViewIdKey = 'view_id';

  @override
  State<MobileCalendarEventsScreen> createState() =>
      _MobileCalendarEventsScreenState();
}

class _MobileCalendarEventsScreenState
    extends State<MobileCalendarEventsScreen> {
  late final List<CalendarDayEvent> _events = widget.events;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        key: const Key('add_event_fab'),
        elevation: 6,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        onPressed: () =>
            widget.calendarBloc.add(CalendarEvent.createEvent(widget.date)),
        child: const Text('+'),
      ),
      appBar: FlowyAppBar(
        titleText: DateFormat.yMMMMd(context.locale.toLanguageTag())
            .format(widget.date),
      ),
      body: BlocProvider<CalendarBloc>.value(
        value: widget.calendarBloc,
        child: BlocBuilder<CalendarBloc, CalendarState>(
          buildWhen: (p, c) =>
              p.newEvent != c.newEvent &&
              c.newEvent?.date.withoutTime == widget.date,
          builder: (context, state) {
            if (state.newEvent?.event != null &&
                _events
                    .none((e) => e.eventId == state.newEvent!.event!.eventId) &&
                state.newEvent!.date.withoutTime == widget.date) {
              _events.add(state.newEvent!.event!);
            }

            if (_events.isEmpty) {
              return const MobileCalendarEventsEmpty();
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  const VSpace(10),
                  ..._events.map((event) {
                    return EventCard(
                      databaseController:
                          widget.calendarBloc.databaseController,
                      event: event,
                      constraints: const BoxConstraints.expand(),
                      autoEdit: false,
                      isDraggable: false,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 3,
                      ),
                    );
                  }),
                  const VSpace(24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
