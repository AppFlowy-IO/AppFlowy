import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
import 'package:appflowy/plugins/database_view/calendar/application/calendar_bloc.dart';
import 'package:appflowy/plugins/database_view/calendar/presentation/calendar_event_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileCalendatEventsScreen extends StatelessWidget {
  static const routeName = "/calendar-events";

  // GoRouter Arguments
  static const calendarBlocKey = "calendar_bloc";
  static const calendarDateKey = "date";
  static const calendarEventsKey = "events";
  static const calendarRowCacheKey = "row_cache";
  static const calendarViewIdKey = "view_id";

  const MobileCalendatEventsScreen({
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
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: calendarBloc,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          key: const Key('add_event_fab'),
          elevation: 6,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          onPressed: () => calendarBloc.add(CalendarEvent.createEvent(date)),
          child: const Text('+'),
        ),
        appBar: AppBar(
          title: Text(
            DateFormat.yMMMMd(context.locale.toLanguageTag()).format(date),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const VSpace(10),
              ...events.map((event) {
                return ListTile(
                  dense: true,
                  title: EventCard(
                    event: event,
                    viewId: viewId,
                    rowCache: rowCache,
                    constraints: const BoxConstraints.expand(),
                    autoEdit: false,
                    isDraggable: false,
                  ),
                );
              }),
              // const VSpace(6),
              // ListTile(
              //   dense: true,
              //   title: const Padding(
              //     padding: EdgeInsets.symmetric(horizontal: 8),
              //     child: FlowyText.medium("+ Add new event", fontSize: 14.0),
              //   ),
              //   onTap: () => calendarBloc.add(CalendarEvent.createEvent(date)),
              // ),
              const VSpace(24),
            ],
          ),
        ),
      ),
    );
  }
}
