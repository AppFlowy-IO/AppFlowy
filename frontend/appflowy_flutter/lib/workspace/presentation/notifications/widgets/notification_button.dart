import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/application/home/home_setting_bloc.dart';
import 'package:appflowy/workspace/application/settings/notifications/notification_settings_cubit.dart';
import 'package:appflowy/workspace/presentation/notifications/number_red_dot.dart';
import 'package:appflowy_backend/protobuf/flowy-user/reminder.pb.dart';
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
    return BlocProvider<ReminderBloc>.value(
      value: getIt<ReminderBloc>(),
      child: BlocBuilder<HomeSettingBloc, HomeSettingState>(
        builder: (homeSettingContext, homeSettingState) {
          return BlocBuilder<NotificationSettingsCubit,
              NotificationSettingsState>(
            builder: (notificationSettingsContext, notificationSettingsState) {
              final homeSettingBloc = context.read<HomeSettingBloc>();
              return BlocBuilder<ReminderBloc, ReminderState>(
                builder: (context, state) {
                  return notificationSettingsState
                          .isShowNotificationsIconEnabled
                      ? _buildNotificationIcon(
                          context,
                          state.reminders,
                          () => homeSettingBloc.add(
                            HomeSettingEvent.collapseNotificationPanel(),
                          ),
                        )
                      : const SizedBox.shrink();
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationIcon(
    BuildContext context,
    List<ReminderPB> reminders,
    VoidCallback onTap,
  ) {
    return SizedBox.square(
      dimension: 28.0,
      child: Stack(
        children: [
          Center(
            child: SizedBox.square(
              dimension: 28.0,
              child: FlowyButton(
                useIntrinsicWidth: true,
                margin: EdgeInsets.zero,
                text: FlowySvg(
                  FlowySvgs.notification_s,
                  color: widget.isHover
                      ? Theme.of(context).colorScheme.onSurface
                      : null,
                  opacity: 0.7,
                ),
                onTap: onTap,
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: NumberedRedDot.desktop(),
          ),
        ],
      ),
    );
  }
}
