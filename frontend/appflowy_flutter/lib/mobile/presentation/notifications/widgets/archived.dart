import 'package:appflowy/mobile/presentation/notifications/widgets/notification_item.dart';
import 'package:appflowy/mobile/presentation/notifications/widgets/widgets.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/user/application/reminder/reminder_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationArchivedTab extends StatelessWidget {
  const NotificationArchivedTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReminderBloc, ReminderState>(
      builder: (context, state) {
        final archivedReminders = state.reminders.reversed
            .where((reminder) => reminder.isArchived)
            .toList();

        if (archivedReminders.isEmpty) {
          return const EmptyNotification(
            type: MobileNotificationTabType.archive,
          );
        }

        return ListView.separated(
          itemCount: archivedReminders.length,
          separatorBuilder: (context, index) => const VSpace(8.0),
          itemBuilder: (context, index) {
            final reminder = archivedReminders[index];
            return NotificationItem(
              key: ValueKey('archived_${reminder.id}'),
              tabType: MobileNotificationTabType.archive,
              reminder: reminder,
            );
          },
        );
      },
    );
  }
}
