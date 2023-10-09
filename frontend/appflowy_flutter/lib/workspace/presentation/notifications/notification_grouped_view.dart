import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/application/appearance.dart';
import 'package:appflowy/workspace/application/settings/date_time/date_format_ext.dart';
import 'package:appflowy/workspace/presentation/notifications/notification_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/reminder.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationsGroupView extends StatelessWidget {
  const NotificationsGroupView({
    super.key,
    required this.groupedReminders,
    required this.reminderBloc,
    required this.views,
    required this.mutex,
    this.isUpcoming = false,
  });

  final Map<DateTime, List<ReminderPB>> groupedReminders;
  final ReminderBloc reminderBloc;
  final List<ViewPB> views;
  final PopoverMutex mutex;
  final bool isUpcoming;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (groupedReminders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: FlowyText.regular(
                  LocaleKeys.notificationHub_empty.tr(),
                ),
              ),
            )
          else
            ...groupedReminders.values.mapIndexed((index, reminders) {
              final formattedDate = context
                  .read<AppearanceSettingsCubit>()
                  .state
                  .dateFormat
                  .formatDate(groupedReminders.keys.elementAt(index), false);

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
                            onReadChanged: !isUpcoming
                                ? (isRead) => reminderBloc.add(
                                      ReminderEvent.update(
                                        ReminderUpdate(
                                            id: reminder.id, isRead: isRead),
                                      ),
                                    )
                                : null,
                            onDelete: !isUpcoming
                                ? () => reminderBloc.add(
                                    ReminderEvent.remove(reminder: reminder))
                                : null,
                            onAction: () {
                              final view = views.firstWhereOrNull(
                                (view) => view.id == reminder.objectId,
                              );

                              if (view == null) {
                                return;
                              }

                              reminderBloc.add(
                                ReminderEvent.pressReminder(
                                    reminderId: reminder.id),
                              );

                              mutex.close();
                            },
                          ),
                        )
                        .toList(),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
