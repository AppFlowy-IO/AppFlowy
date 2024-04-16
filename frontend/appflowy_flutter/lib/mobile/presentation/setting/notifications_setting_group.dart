import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

import 'widgets/widgets.dart';

class NotificationsSettingGroup extends StatefulWidget {
  const NotificationsSettingGroup({super.key});

  @override
  State<NotificationsSettingGroup> createState() =>
      _NotificationsSettingGroupState();
}

class _NotificationsSettingGroupState extends State<NotificationsSettingGroup> {
  bool isPushNotificationOn = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MobileSettingGroup(
      groupTitle: LocaleKeys.notificationHub_title.tr(),
      settingItemList: [
        MobileSettingItem(
          name: LocaleKeys.settings_mobile_pushNotifications.tr(),
          trailing: Switch.adaptive(
            activeColor: theme.colorScheme.primary,
            value: isPushNotificationOn,
            onChanged: (bool value) {
              setState(() {
                isPushNotificationOn = value;
              });
            },
          ),
        ),
      ],
    );
  }
}
