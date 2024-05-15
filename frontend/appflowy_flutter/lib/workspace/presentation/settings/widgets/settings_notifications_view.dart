import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/notifications/notification_settings_cubit.dart';
import 'package:appflowy/workspace/presentation/settings/shared/setting_list_tile.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsNotificationsView extends StatelessWidget {
  const SettingsNotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationSettingsCubit, NotificationSettingsState>(
      builder: (context, state) {
        return SettingsBody(
          title: LocaleKeys.settings_menu_notifications.tr(),
          children: [
            SettingListTile(
              label: LocaleKeys.settings_notifications_enableNotifications_label
                  .tr(),
              hint: LocaleKeys.settings_notifications_enableNotifications_hint
                  .tr(),
              trailing: [
                Switch(
                  value: state.isNotificationsEnabled,
                  splashRadius: 0,
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: (value) => context
                      .read<NotificationSettingsCubit>()
                      .toggleNotificationsEnabled(),
                ),
              ],
            ),
            SettingListTile(
              label: LocaleKeys
                  .settings_notifications_showNotificationsIcon_label
                  .tr(),
              hint: LocaleKeys.settings_notifications_showNotificationsIcon_hint
                  .tr(),
              trailing: [
                Switch(
                  value: state.isShowNotificationsIconEnabled,
                  splashRadius: 0,
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: (_) => context
                      .read<NotificationSettingsCubit>()
                      .toogleShowNotificationIconEnabled(),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
