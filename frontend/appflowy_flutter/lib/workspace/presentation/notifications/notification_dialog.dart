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
  late final TabController _controller = TabController(length: 2, vsync: this);
  final PopoverMutex _mutex = PopoverMutex();
  final ReminderBloc _reminderBloc = getIt<ReminderBloc>();

  @override
  void initState() {
    super.initState();
    // Get all the past and upcoming reminders
    _reminderBloc.add(const ReminderEvent.started());
    _controller.addListener(_updateState);
  }

  void _updateState() => setState(() {});

  @override
  void dispose() {
    _mutex.dispose();
    _controller.removeListener(_updateState);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ReminderBloc>.value(value: _reminderBloc),
        BlocProvider<NotificationFilterBloc>(
          create: (_) => NotificationFilterBloc(),
        ),
      ],
      child: BlocBuilder<NotificationFilterBloc, NotificationFilterState>(
        builder: (context, filterState) =>
            BlocBuilder<ReminderBloc, ReminderState>(
          builder: (context, state) {
            final reminders = state.reminders.sortByScheduledAt();
            final upcomingReminders =
                state.upcomingReminders.sortByScheduledAt();
            final hasUnreads = reminders.any((r) => !r.isRead);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const NotificationHubTitle(),
                NotificationTabBar(tabController: _controller),
                Expanded(
                  child: TabBarView(
                    controller: _controller,
                    children: [
                      NotificationsView(
                        shownReminders: reminders,
                        reminderBloc: _reminderBloc,
                        views: widget.views,
                        onDelete: _onDelete,
                        onAction: _onAction,
                        onReadChanged: _onReadChanged,
                        actionBar: InboxActionBar(
                          hasUnreads: hasUnreads,
                          showUnreadsOnly: filterState.showUnreadsOnly,
                        ),
                      ),
                      NotificationsView(
                        shownReminders: upcomingReminders,
                        reminderBloc: _reminderBloc,
                        views: widget.views,
                        isUpcoming: true,
                        onAction: _onAction,
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

  void _onAction(ReminderPB reminder, int? path, ViewPB? view) {
    _reminderBloc.add(
      ReminderEvent.pressReminder(reminderId: reminder.id, path: path),
    );

    widget.mutex.close();
  }

  void _onDelete(ReminderPB reminder) {
    _reminderBloc.add(ReminderEvent.remove(reminderId: reminder.id));
  }

  void _onReadChanged(ReminderPB reminder, bool isRead) {
    _reminderBloc.add(
      ReminderEvent.update(ReminderUpdate(id: reminder.id, isRead: isRead)),
    );
  }
}
