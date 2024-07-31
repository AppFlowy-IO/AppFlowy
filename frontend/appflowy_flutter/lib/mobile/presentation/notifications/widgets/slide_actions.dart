import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/application/notification/notification_reminder_bloc.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/notifications/widgets/widgets.dart';
import 'package:appflowy/mobile/presentation/page_item/mobile_slide_action_button.dart';
import 'package:appflowy/mobile/presentation/presentation.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/user/application/reminder/reminder_extension.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum NotificationPaneActionType {
  more,
  markAsRead,
  // only used in the debug mode.
  unArchive;

  MobileSlideActionButton actionButton(
    BuildContext context, {
    required MobileNotificationTabType tabType,
  }) {
    switch (this) {
      case NotificationPaneActionType.markAsRead:
        return MobileSlideActionButton(
          backgroundColor: const Color(0xFF00C8FF),
          svg: FlowySvgs.m_notification_action_mark_as_read_s,
          size: 24.0,
          onPressed: (context) {
            showToastNotification(
              context,
              message: LocaleKeys
                  .settings_notifications_markAsReadNotifications_success
                  .tr(),
            );

            context.read<ReminderBloc>().add(
                  ReminderEvent.update(
                    ReminderUpdate(
                      id: context.read<NotificationReminderBloc>().reminder.id,
                      isRead: true,
                    ),
                  ),
                );
          },
        );
      // this action is only used in the debug mode.
      case NotificationPaneActionType.unArchive:
        return MobileSlideActionButton(
          backgroundColor: const Color(0xFF00C8FF),
          svg: FlowySvgs.m_notification_action_mark_as_read_s,
          size: 24.0,
          onPressed: (context) {
            showToastNotification(
              context,
              message: 'Unarchive notification success',
            );

            context.read<ReminderBloc>().add(
                  ReminderEvent.update(
                    ReminderUpdate(
                      id: context.read<NotificationReminderBloc>().reminder.id,
                      isArchived: false,
                    ),
                  ),
                );
          },
        );
      case NotificationPaneActionType.more:
        return MobileSlideActionButton(
          backgroundColor: const Color(0xE5515563),
          svg: FlowySvgs.three_dots_s,
          size: 24.0,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            bottomLeft: Radius.circular(10),
          ),
          onPressed: (context) {
            final reminderBloc = context.read<ReminderBloc>();
            final notificationReminderBloc =
                context.read<NotificationReminderBloc>();

            showMobileBottomSheet(
              context,
              showDragHandle: true,
              showDivider: false,
              useRootNavigator: true,
              backgroundColor: Theme.of(context).colorScheme.surface,
              builder: (_) {
                return MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: reminderBloc),
                    BlocProvider.value(value: notificationReminderBloc),
                  ],
                  child: _NotificationMoreActions(
                    onClickMultipleChoice: () {
                      Future.delayed(const Duration(milliseconds: 250), () {
                        bottomNavigationActionType.value =
                            BottomNavigationBarActionType.notification;
                      });
                    },
                  ),
                );
              },
            );
          },
        );
    }
  }
}

class _NotificationMoreActions extends StatelessWidget {
  const _NotificationMoreActions({
    required this.onClickMultipleChoice,
  });

  final VoidCallback onClickMultipleChoice;

  @override
  Widget build(BuildContext context) {
    final reminder = context.read<NotificationReminderBloc>().reminder;
    return Column(
      children: [
        if (!reminder.isRead)
          FlowyOptionTile.text(
            height: 52.0,
            text: LocaleKeys.settings_notifications_action_markAsRead.tr(),
            leftIcon: const FlowySvg(
              FlowySvgs.m_notification_action_mark_as_read_s,
              size: Size.square(20),
            ),
            showTopBorder: false,
            showBottomBorder: false,
            onTap: () => _onMarkAsRead(context),
          ),
        FlowyOptionTile.text(
          height: 52.0,
          text: LocaleKeys.settings_notifications_action_multipleChoice.tr(),
          leftIcon: const FlowySvg(
            FlowySvgs.m_notification_action_multiple_choice_s,
            size: Size.square(20),
          ),
          showTopBorder: false,
          showBottomBorder: false,
          onTap: () => _onMultipleChoice(context),
        ),
        if (!reminder.isArchived)
          FlowyOptionTile.text(
            height: 52.0,
            text: LocaleKeys.settings_notifications_action_archive.tr(),
            leftIcon: const FlowySvg(
              FlowySvgs.m_notification_action_archive_s,
              size: Size.square(20),
            ),
            showTopBorder: false,
            showBottomBorder: false,
            onTap: () => _onArchive(context),
          ),
      ],
    );
  }

  void _onMarkAsRead(BuildContext context) {
    Navigator.of(context).pop();

    showToastNotification(
      context,
      message: LocaleKeys.settings_notifications_markAsReadNotifications_success
          .tr(),
    );

    context.read<ReminderBloc>().add(
          ReminderEvent.update(
            ReminderUpdate(
              id: context.read<NotificationReminderBloc>().reminder.id,
              isRead: true,
            ),
          ),
        );
  }

  void _onMultipleChoice(BuildContext context) {
    Navigator.of(context).pop();

    onClickMultipleChoice();
  }

  void _onArchive(BuildContext context) {
    showToastNotification(
      context,
      message: LocaleKeys.settings_notifications_archiveNotifications_success
          .tr()
          .tr(),
    );

    context.read<ReminderBloc>().add(
          ReminderEvent.update(
            ReminderUpdate(
              id: context.read<NotificationReminderBloc>().reminder.id,
              isRead: true,
              isArchived: true,
            ),
          ),
        );

    Navigator.of(context).pop();
  }
}
