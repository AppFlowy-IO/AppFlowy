import 'package:appflowy/workspace/presentation/notifications/notification_item.dart';
import 'package:appflowy_backend/protobuf/flowy-user/reminder.pb.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

class NotificationGroup extends StatelessWidget {
  const NotificationGroup({
    super.key,
    required this.reminders,
    required this.formattedDate,
    required this.isUpcoming,
    required this.onReadChanged,
    required this.onDelete,
    required this.onAction,
  });

  final List<ReminderPB> reminders;
  final String formattedDate;
  final bool isUpcoming;
  final Function(ReminderPB reminder, bool isRead)? onReadChanged;
  final Function(ReminderPB reminder)? onDelete;
  final Function(ReminderPB reminder)? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: FlowyText(formattedDate),
          ),
          const VSpace(4),
          ...reminders
              .map(
                (reminder) => NotificationItem(
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
                ),
              )
              .toList(),
        ],
      ),
    );
  }
}
