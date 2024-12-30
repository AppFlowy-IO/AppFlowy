import 'package:appflowy/mobile/application/notification/notification_reminder_bloc.dart';
import 'package:appflowy/mobile/presentation/base/animated_gesture.dart';
import 'package:appflowy/mobile/presentation/notifications/mobile_notifications_screen.dart';
import 'package:appflowy/mobile/presentation/notifications/widgets/widgets.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MultiSelectNotificationItem extends StatelessWidget {
  const MultiSelectNotificationItem({
    super.key,
    required this.reminder,
  });

  final ReminderPB reminder;

  @override
  Widget build(BuildContext context) {
    final settings = context.read<AppearanceSettingsCubit>().state;
    final dateFormate = settings.dateFormat;
    final timeFormate = settings.timeFormat;
    return BlocProvider<NotificationReminderBloc>(
      create: (context) => NotificationReminderBloc()
        ..add(
          NotificationReminderEvent.initial(
            reminder,
            dateFormate,
            timeFormate,
          ),
        ),
      child: BlocBuilder<NotificationReminderBloc, NotificationReminderState>(
        builder: (context, state) {
          if (state.status == NotificationReminderStatus.loading ||
              state.status == NotificationReminderStatus.initial) {
            return const SizedBox.shrink();
          }

          if (state.status == NotificationReminderStatus.error) {
            // error handle.
            return const SizedBox.shrink();
          }

          final child = ValueListenableBuilder(
            valueListenable: mSelectedNotificationIds,
            builder: (_, selectedIds, child) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: selectedIds.contains(reminder.id)
                    ? ShapeDecoration(
                        color: const Color(0x1900BCF0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      )
                    : null,
                child: child,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _InnerNotificationItem(
                reminder: reminder,
              ),
            ),
          );

          return AnimatedGestureDetector(
            scaleFactor: 0.99,
            onTapUp: () {
              if (mSelectedNotificationIds.value.contains(reminder.id)) {
                mSelectedNotificationIds.value = mSelectedNotificationIds.value
                  ..remove(reminder.id);
              } else {
                mSelectedNotificationIds.value = mSelectedNotificationIds.value
                  ..add(reminder.id);
              }
            },
            child: child,
          );
        },
      ),
    );
  }
}

class _InnerNotificationItem extends StatelessWidget {
  const _InnerNotificationItem({
    required this.reminder,
  });

  final ReminderPB reminder;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HSpace(10.0),
        NotificationCheckIcon(
          isSelected: mSelectedNotificationIds.value.contains(reminder.id),
        ),
        const HSpace(3.0),
        !reminder.isRead ? const UnreadRedDot() : const HSpace(6.0),
        const HSpace(3.0),
        NotificationIcon(reminder: reminder),
        const HSpace(12.0),
        Expanded(
          child: NotificationContent(reminder: reminder),
        ),
      ],
    );
  }
}
