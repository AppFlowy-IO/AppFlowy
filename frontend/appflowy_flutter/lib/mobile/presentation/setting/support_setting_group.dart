import 'dart:io';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'widgets/widgets.dart';

class SupportSettingGroup extends StatelessWidget {
  const SupportSettingGroup({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) => MobileSettingGroup(
        groupTitle: LocaleKeys.settings_mobile_support.tr(),
        settingItemList: [
          MobileSettingItem(
            name: LocaleKeys.settings_mobile_joinDiscord.tr(),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () => safeLaunchUrl('https://discord.gg/JucBXeU2FE'),
          ),
          MobileSettingItem(
            name: LocaleKeys.workspace_errorActions_reportIssue.tr(),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () {
              final String? version = snapshot.data?.version;
              final String os = Platform.operatingSystem;
              safeLaunchUrl(
                'https://github.com/AppFlowy-IO/AppFlowy/issues/new?assignees=&labels=&projects=&template=bug_report.yaml&title=[Bug]%20Mobile:%20&version=$version&os=$os',
              );
            },
          ),
        ],
      ),
    );
  }
}
