import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/notifications/notification_settings_cubit.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_appearance/theme_setting_entry_template.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsNotificationsView extends StatelessWidget {
  const SettingsNotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationSettingsCubit, NotificationSettingsState>(
      builder: (context, state) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FlowySettingListTile(
                label: LocaleKeys
                    .settings_notifications_enableNotifications_label
                    .tr(),
                hint: LocaleKeys.settings_notifications_enableNotifications_hint
                    .tr(),
                trailing: [
                  Switch(
                    value: state.isNotificationsEnabled,
                    splashRadius: 0,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (value) {
                      context
                          .read<NotificationSettingsCubit>()
                          .toggleNotificationsEnabled();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
