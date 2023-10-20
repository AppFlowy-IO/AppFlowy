import 'dart:io';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

import 'widgets/widgets.dart';

class SupportSettingGroup extends StatelessWidget {
  const SupportSettingGroup({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MobileSettingGroup(
      groupTitle: 'Support',
      settingItemList: [
        // 'Help Center'
        MobileSettingItem(
          name: 'Join us in Discord',
          trailing: const Icon(
            Icons.chevron_right,
          ),
          onTap: () => safeLaunchUrl('https://discord.gg/JucBXeU2FE'),
        ),
        MobileSettingItem(
          name: 'Report an issue',
          trailing: const Icon(
            Icons.chevron_right,
          ),
          onTap: () {
            // TODO(yijing): get app version before release
            const String version = 'Beta';
            final String os = Platform.operatingSystem;
            safeLaunchUrl(
              'https://github.com/AppFlowy-IO/AppFlowy/issues/new?assignees=&labels=&projects=&template=bug_report.yaml&title=[Bug]%20Mobile:%20&version=$version&os=$os',
            );
          },
        ),
      ],
    );
  }
}
