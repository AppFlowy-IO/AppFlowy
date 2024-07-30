import 'package:appflowy/mobile/presentation/notifications/widgets/notification_item.dart';
import 'package:appflowy/mobile/presentation/notifications/widgets/widgets.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/user/application/reminder/reminder_extension.dart';
import 'package:appflowy_backend/appflowy_backend.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationTab extends StatelessWidget {
  const NotificationTab({
    super.key,
    required this.tabType,
  });

  final MobileNotificationTabType tabType;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReminderBloc, ReminderState>(
      builder: (context, state) {
        final reminders = _filterReminders(state.reminders);

        if (reminders.isEmpty) {
          return EmptyNotification(
            type: tabType,
          );
        }

        return RefreshIndicator.adaptive(
          onRefresh: () async {
            context.read<ReminderBloc>().add(const ReminderEvent.refresh());
            await context.read<ReminderBloc>().stream.firstOrNull;
          },
          child: ListView.separated(
            itemCount: reminders.length,
            separatorBuilder: (context, index) => const VSpace(8.0),
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              return NotificationItem(
                key: ValueKey('${tabType}_${reminder.id}'),
                tabType: tabType,
                reminder: reminder,
              );
            },
          ),
        );
      },
    );
  }

  List<ReminderPB> _filterReminders(List<ReminderPB> reminders) {
    switch (tabType) {
      case MobileNotificationTabType.inbox:
        return reminders.where((reminder) => !reminder.isArchived).toList();
      case MobileNotificationTabType.archive:
        return reminders.where((reminder) => reminder.isArchived).toList();
      case MobileNotificationTabType.unread:
        return reminders.where((reminder) => !reminder.isRead).toList();
    }
  }
}
