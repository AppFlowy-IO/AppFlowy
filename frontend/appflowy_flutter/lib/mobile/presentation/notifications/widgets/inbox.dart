import 'package:appflowy/mobile/presentation/notifications/widgets/notification_item.dart';
import 'package:appflowy/mobile/presentation/notifications/widgets/widgets.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/user/application/reminder/reminder_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationInboxTab extends StatelessWidget {
  const NotificationInboxTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReminderBloc, ReminderState>(
      builder: (context, state) {
        final unArchivedReminders = state.reminders.reversed
            .where((reminder) => !reminder.isArchived)
            .toList();
        return ListView.separated(
          itemCount: unArchivedReminders.length,
          separatorBuilder: (context, index) => const VSpace(8.0),
          itemBuilder: (context, index) {
            final reminder = unArchivedReminders[index];
            return NotificationItem(
              key: ValueKey('inbox_${reminder.id}'),
              tabType: MobileNotificationTabType.inbox,
              reminder: reminder,
            );
          },
        );
      },
    );
  }
}
