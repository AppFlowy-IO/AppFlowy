import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/presentation/notifications/notification_item.dart';
import 'package:appflowy/workspace/presentation/notifications/notifications_hub_empty.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/reminder.pb.dart';
import 'package:flutter/material.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({
    super.key,
    required this.shownReminders,
    required this.reminderBloc,
    required this.views,
    this.isUpcoming = false,
    this.onAction,
    this.onDelete,
    this.onReadChanged,
  });

  final List<ReminderPB> shownReminders;
  final ReminderBloc reminderBloc;
  final List<ViewPB> views;
  final bool isUpcoming;
  final Function(ReminderPB reminder)? onAction;
  final Function(ReminderPB reminder)? onDelete;
  final Function(ReminderPB reminder, bool isRead)? onReadChanged;

  @override
  Widget build(BuildContext context) {
    if (shownReminders.isEmpty) {
      return const Center(child: NotificationsHubEmpty());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...shownReminders.map(
            (reminder) {
              return NotificationItem(
                reminderId: reminder.id,
                key: ValueKey(reminder.id),
                title: reminder.title,
                scheduled: reminder.scheduledAt,
                body: reminder.message,
                isRead: reminder.isRead,
                readOnly: isUpcoming,
                onReadChanged: (isRead) =>
                    onReadChanged?.call(reminder, isRead),
                onDelete: () => onDelete?.call(reminder),
                onAction: () => onAction?.call(reminder),
              );
            },
          ),
        ],
      ),
    );
  }
}
