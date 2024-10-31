import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/red_dot.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/application/menu/sidebar_sections_bloc.dart';
import 'package:appflowy/workspace/application/settings/notifications/notification_settings_cubit.dart';
import 'package:appflowy/workspace/presentation/notifications/notification_dialog.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationButton extends StatefulWidget {
  const NotificationButton({
    super.key,
    this.isHover = false,
  });

  final bool isHover;

  @override
  State<NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<NotificationButton> {
  final mutex = PopoverMutex();

  @override
  void initState() {
    super.initState();
    getIt<ReminderBloc>().add(const ReminderEvent.started());
  }

  @override
  void dispose() {
    mutex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final views = context.watch<SidebarSectionsBloc>().state.section.views;

    return BlocProvider<ReminderBloc>.value(
      value: getIt<ReminderBloc>(),
      child: BlocBuilder<NotificationSettingsCubit, NotificationSettingsState>(
        builder: (notificationSettingsContext, notificationSettingsState) {
          return BlocBuilder<ReminderBloc, ReminderState>(
            builder: (context, state) {
              final hasUnreads = state.pastReminders.any((r) => !r.isRead);
              return notificationSettingsState.isShowNotificationsIconEnabled
                  ? FlowyTooltip(
                      message: LocaleKeys.notificationHub_title.tr(),
                      child: AppFlowyPopover(
                        mutex: mutex,
                        direction: PopoverDirection.bottomWithLeftAligned,
                        constraints:
                            const BoxConstraints(maxHeight: 500, maxWidth: 425),
                        windowPadding: EdgeInsets.zero,
                        margin: EdgeInsets.zero,
                        popupBuilder: (_) =>
                            NotificationDialog(views: views, mutex: mutex),
                        child: SizedBox.square(
                          dimension: 24.0,
                          child: FlowyButton(
                            useIntrinsicWidth: true,
                            margin: EdgeInsets.zero,
                            text: _buildNotificationIcon(
                              context,
                              hasUnreads,
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationIcon(BuildContext context, bool hasUnreads) {
    return Stack(
      children: [
        Center(
          child: FlowySvg(
            FlowySvgs.notification_s,
            color:
                widget.isHover ? Theme.of(context).colorScheme.onSurface : null,
            opacity: 0.7,
          ),
        ),
        if (hasUnreads)
          const Positioned(
            top: 4,
            right: 6,
            child: NotificationRedDot(
              size: 5,
            ),
          ),
      ],
    );
  }
}
