import 'dart:io';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/util/share_log_files.dart';
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
              showMobileBottomSheet(
                context,
                showDragHandle: true,
                showHeader: true,
                title: LocaleKeys.workspace_errorActions_reportIssue.tr(),
                backgroundColor: Theme.of(context).colorScheme.surface,
                builder: (context) {
                  return _ReportIssuesWidget(
                    version: snapshot.data?.version ?? '',
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReportIssuesWidget extends StatelessWidget {
  const _ReportIssuesWidget({
    required this.version,
  });

  final String version;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FlowyOptionTile.text(
          showTopBorder: false,
          text: LocaleKeys.workspace_errorActions_reportIssueOnGithub.tr(),
          onTap: () {
            final String os = Platform.operatingSystem;
            safeLaunchUrl(
              'https://github.com/AppFlowy-IO/AppFlowy/issues/new?assignees=&labels=&projects=&template=bug_report.yaml&title=[Bug]%20Mobile:%20&version=$version&os=$os',
            );
          },
        ),
        FlowyOptionTile.text(
          showTopBorder: false,
          text: LocaleKeys.workspace_errorActions_exportLogFiles.tr(),
          onTap: () => shareLogFiles(context),
        ),
      ],
    );
  }
}
