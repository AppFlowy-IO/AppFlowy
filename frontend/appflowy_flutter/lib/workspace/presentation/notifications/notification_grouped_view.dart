import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/date_time/date_format_ext.dart';
import 'package:appflowy/workspace/presentation/notifications/notification_group.dart';
import 'package:appflowy/workspace/presentation/notifications/notifications_hub_empty.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/reminder.pb.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationsGroupView extends StatelessWidget {
  const NotificationsGroupView({
    super.key,
    required this.groupedReminders,
    required this.reminderBloc,
    required this.views,
    this.isUpcoming = false,
    this.onAction,
    this.onDelete,
    this.onReadChanged,
  });

  final Map<DateTime, List<ReminderPB>> groupedReminders;
  final ReminderBloc reminderBloc;
  final List<ViewPB> views;
  final bool isUpcoming;
  final Function(ReminderPB reminder)? onAction;
  final Function(ReminderPB reminder)? onDelete;
  final Function(ReminderPB reminder, bool isRead)? onReadChanged;

  @override
  Widget build(BuildContext context) {
    if (groupedReminders.isEmpty) {
      return const Center(child: NotificationsHubEmpty());
    }

    final dateFormat = context.read<AppearanceSettingsCubit>().state.dateFormat;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...groupedReminders.values.mapIndexed(
            (index, reminders) {
              final formattedDate = dateFormat.formatDate(
                groupedReminders.keys.elementAt(index),
                false,
              );

              return NotificationGroup(
                reminders: reminders,
                formattedDate: formattedDate,
                isUpcoming: isUpcoming,
                onReadChanged: onReadChanged,
                onDelete: onDelete,
                onAction: onAction,
              );
            },
          ),
        ],
      ),
    );
  }
}
