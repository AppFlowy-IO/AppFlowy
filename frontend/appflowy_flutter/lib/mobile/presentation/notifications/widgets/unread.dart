import 'package:appflowy/mobile/presentation/notifications/widgets/notification_item.dart';
import 'package:appflowy/mobile/presentation/notifications/widgets/widgets.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationUnreadTab extends StatelessWidget {
  const NotificationUnreadTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReminderBloc, ReminderState>(
      builder: (context, state) {
        final unreadReminders = state.reminders.reversed
            .where((reminder) => !reminder.isRead)
            .toList();

        if (unreadReminders.isEmpty) {
          return const EmptyNotification(
            type: MobileNotificationTabType.unread,
          );
        }

        return ListView.separated(
          itemCount: unreadReminders.length,
          separatorBuilder: (context, index) => const VSpace(8.0),
          itemBuilder: (context, index) {
            final reminder = unreadReminders[index];
            return NotificationItem(
              key: ValueKey('unread_${reminder.id}'),
              tabType: MobileNotificationTabType.unread,
              reminder: reminder,
            );
          },
        );
      },
    );
  }
}
