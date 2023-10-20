import 'package:flutter/material.dart';

import 'widgets/widgets.dart';

class NotificationsSettingGroup extends StatefulWidget {
  const NotificationsSettingGroup({
    super.key,
  });

  @override
  State<NotificationsSettingGroup> createState() =>
      _NotificationsSettingGroupState();
}

class _NotificationsSettingGroupState extends State<NotificationsSettingGroup> {
  // TODO(yijing):remove this after notification page is implemented
  bool isPushNotificationOn = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MobileSettingGroup(
      groupTitle: 'Notifications',
      settingItemList: [
        MobileSettingItem(
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
