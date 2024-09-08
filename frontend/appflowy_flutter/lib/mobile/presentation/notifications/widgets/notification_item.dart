import 'package:appflowy/mobile/application/mobile_router.dart';
import 'package:appflowy/mobile/application/notification/notification_reminder_bloc.dart';
import 'package:appflowy/mobile/presentation/base/animated_gesture.dart';
import 'package:appflowy/mobile/presentation/notifications/widgets/widgets.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class NotificationItem extends StatelessWidget {
  const NotificationItem({
    super.key,
    required this.tabType,
    required this.reminder,
  });

  final MobileNotificationTabType tabType;
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

          final child = Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _SlidableNotificationItem(
              tabType: tabType,
              reminder: reminder,
              child: _InnerNotificationItem(
                tabType: tabType,
                reminder: reminder,
              ),
            ),
          );

          return AnimatedGestureDetector(
            scaleFactor: 0.99,
            child: child,
            onTapUp: () async {
              final view = state.view;
              if (view == null) {
                return;
              }

              await context.pushView(view);

              if (!reminder.isRead && context.mounted) {
                context.read<ReminderBloc>().add(
                      ReminderEvent.markAsRead([reminder.id]),
                    );
              }
            },
          );
        },
      ),
    );
  }
}

class _InnerNotificationItem extends StatelessWidget {
  const _InnerNotificationItem({
    required this.reminder,
    required this.tabType,
  });

  final MobileNotificationTabType tabType;
  final ReminderPB reminder;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HSpace(8.0),
        !reminder.isRead ? const UnreadRedDot() : const HSpace(6.0),
        const HSpace(4.0),
        NotificationIcon(reminder: reminder),
        const HSpace(12.0),
        Expanded(
          child: NotificationContent(reminder: reminder),
        ),
      ],
    );
  }
}

class _SlidableNotificationItem extends StatelessWidget {
  const _SlidableNotificationItem({
    required this.tabType,
    required this.reminder,
    required this.child,
  });

  final MobileNotificationTabType tabType;
  final ReminderPB reminder;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final List<NotificationPaneActionType> actions = switch (tabType) {
      MobileNotificationTabType.inbox => [
          NotificationPaneActionType.more,
          if (!reminder.isRead) NotificationPaneActionType.markAsRead,
        ],
      MobileNotificationTabType.unread => [
          NotificationPaneActionType.more,
          NotificationPaneActionType.markAsRead,
        ],
      MobileNotificationTabType.archive => [
          if (kDebugMode) NotificationPaneActionType.unArchive,
        ],
    };

    if (actions.isEmpty) {
      return child;
    }

    final children = actions
        .map(
          (action) => action.actionButton(
            context,
            tabType: tabType,
          ),
        )
        .toList();

    final extentRatio = actions.length == 1 ? 1 / 5 : 1 / 3;

    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: extentRatio,
        children: children,
      ),
      child: child,
    );
  }
}
