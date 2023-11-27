import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
import 'package:appflowy/plugins/database_view/calendar/application/calendar_bloc.dart';
import 'package:appflowy/plugins/database_view/calendar/presentation/calendar_event_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileCalendarEventsScreen extends StatefulWidget {
  static const routeName = "/calendar-events";

  // GoRouter Arguments
  static const calendarBlocKey = "calendar_bloc";
  static const calendarDateKey = "date";
  static const calendarEventsKey = "events";
  static const calendarRowCacheKey = "row_cache";
  static const calendarViewIdKey = "view_id";

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

  @override
  State<MobileCalendarEventsScreen> createState() =>
      _MobileCalendarEventsScreenState();
}

class _MobileCalendarEventsScreenState
    extends State<MobileCalendarEventsScreen> {
  late final List<CalendarDayEvent> _events = widget.events;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.calendarBloc,
      child: BlocBuilder<CalendarBloc, CalendarState>(
        buildWhen: (p, c) => p.newEvent != c.newEvent,
        builder: (context, state) {
          if (state.newEvent?.event != null) {
            _events.add(state.newEvent!.event!);
          }

          return Scaffold(
            floatingActionButton: FloatingActionButton(
              key: const Key('add_event_fab'),
              elevation: 6,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              onPressed: () => widget.calendarBloc
                  .add(CalendarEvent.createEvent(widget.date)),
              child: const Text('+'),
            ),
            appBar: AppBar(
              title: Text(
                DateFormat.yMMMMd(context.locale.toLanguageTag())
                    .format(widget.date),
              ),
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const VSpace(10),
                  ...widget.events.map((event) {
                    return ListTile(
                      dense: true,
                      title: EventCard(
                        fieldController: widget.calendarBloc.fieldController,
                        event: event,
                        viewId: widget.viewId,
                        rowCache: widget.rowCache,
                        constraints: const BoxConstraints.expand(),
                        autoEdit: false,
                        isDraggable: false,
                      ),
                    );
                  }),
                  const VSpace(24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
