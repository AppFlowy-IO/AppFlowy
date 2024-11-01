import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/notification_filter/notification_filter_bloc.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/presentation/notifications/reminder_extension.dart';
import 'package:appflowy/workspace/presentation/notifications/widgets/inbox_action_bar.dart';
import 'package:appflowy/workspace/presentation/notifications/widgets/notification_hub_title.dart';
import 'package:appflowy/workspace/presentation/notifications/widgets/notification_tab_bar.dart';
import 'package:appflowy/workspace/presentation/notifications/widgets/notification_view.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/reminder.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationDialog extends StatefulWidget {
  const NotificationDialog({
    super.key,
    required this.views,
    required this.mutex,
  });

  final List<ViewPB> views;
  final PopoverMutex mutex;

  @override
  State<NotificationDialog> createState() => _NotificationDialogState();
}

class _NotificationDialogState extends State<NotificationDialog>
    with SingleTickerProviderStateMixin {
  late final TabController controller = TabController(length: 2, vsync: this);
  final PopoverMutex mutex = PopoverMutex();
  final ReminderBloc reminderBloc = getIt<ReminderBloc>();

  @override
  void initState() {
    super.initState();
    // Get all the past and upcoming reminders
    reminderBloc.add(const ReminderEvent.started());
    controller.addListener(updateState);
  }

  void updateState() => setState(() {});

  @override
  void dispose() {
    mutex.dispose();
    controller.removeListener(updateState);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ReminderBloc>.value(value: reminderBloc),
        BlocProvider<NotificationFilterBloc>(
          create: (_) => NotificationFilterBloc(),
        ),
      ],
      child: BlocBuilder<NotificationFilterBloc, NotificationFilterState>(
        builder: (context, filterState) =>
            BlocBuilder<ReminderBloc, ReminderState>(
          builder: (context, state) {
            final pastReminders = state.pastReminders.sortByScheduledAt();
            final upcomingReminders =
                state.upcomingReminders.sortByScheduledAt();
            final hasUnreads = pastReminders.any((r) => !r.isRead);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const NotificationHubTitle(),
                NotificationTabBar(tabController: controller),
                Expanded(
                  child: TabBarView(
                    controller: controller,
                    children: [
                      NotificationsView(
                        shownReminders: pastReminders,
                        reminderBloc: reminderBloc,
                        views: widget.views,
                        onAction: onAction,
                        onReadChanged: _onReadChanged,
                        actionBar: InboxActionBar(
                          hasUnreads: hasUnreads,
                          showUnreadsOnly: filterState.showUnreadsOnly,
                        ),
                      ),
                      NotificationsView(
                        shownReminders: upcomingReminders,
                        reminderBloc: reminderBloc,
                        views: widget.views,
                        isUpcoming: true,
                        onAction: onAction,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void onAction(ReminderPB reminder, int? path, ViewPB? view) {
    reminderBloc.add(
      ReminderEvent.pressReminder(reminderId: reminder.id, path: path),
    );

    widget.mutex.close();
  }

  void _onReadChanged(ReminderPB reminder, bool isRead) {
    reminderBloc.add(
      ReminderEvent.update(ReminderUpdate(id: reminder.id, isRead: isRead)),
    );
  }
}
