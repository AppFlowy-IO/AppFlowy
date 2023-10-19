import 'package:flutter/material.dart';

import 'widgets/widgets.dart';

class SettingNotificationsWidget extends StatefulWidget {
  const SettingNotificationsWidget({
    super.key,
  });

  @override
  State<SettingNotificationsWidget> createState() =>
      _SettingNotificationsWidgetState();
}

class _SettingNotificationsWidgetState
    extends State<SettingNotificationsWidget> {
  // TODO(yijing):remove this after notification page is implemented
  bool isPushNotificationOn = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MobileSettingGroupWidget(
      groupTitle: 'Notifications',
      settingItemWidgets: [
        MobileSettingItemWidget(
          name: 'Push Notifications',
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
