import 'package:appflowy/mobile/presentation/notifications/widgets/_notification_item.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationUnreadTab extends StatefulWidget {
  const NotificationUnreadTab({super.key});

  @override
  State<NotificationUnreadTab> createState() => _NotificationUnreadTabState();
}

class _NotificationUnreadTabState extends State<NotificationUnreadTab> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReminderBloc, ReminderState>(
      builder: (context, state) {
        final unreadReminders =
            state.reminders.where((reminder) => !reminder.isRead).toList();
        return ListView.separated(
          itemCount: unreadReminders.length,
          separatorBuilder: (context, index) => const VSpace(8.0),
          itemBuilder: (context, index) {
            final reminders = unreadReminders.reversed.toList();
            final reminder = reminders[index];
            return NotificationItem(
              key: ValueKey('unread_${reminder.id}'),
              reminder: reminder,
            );
          },
        );
      },
    );
  }
}
