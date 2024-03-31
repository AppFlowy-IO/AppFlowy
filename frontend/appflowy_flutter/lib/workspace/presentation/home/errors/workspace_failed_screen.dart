import 'dart:io';

import 'package:flutter/material.dart';

import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:package_info_plus/package_info_plus.dart';

class WorkspaceFailedScreen extends StatefulWidget {
  const WorkspaceFailedScreen({super.key});

  @override
  State<WorkspaceFailedScreen> createState() => _WorkspaceFailedScreenState();
}

class _WorkspaceFailedScreenState extends State<WorkspaceFailedScreen> {
  String version = '';
  final String os = Platform.operatingSystem;

  @override
  void initState() {
    super.initState();
    initVersion();
  }

  Future<void> initVersion() async {
    final platformInfo = await PackageInfo.fromPlatform();
    setState(() {
      version = platformInfo.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(LocaleKeys.workspace_failedToLoad.tr()),
                const VSpace(20),
                Row(
                  children: [
                    Flexible(
                      child: RoundedTextButton(
                        title:
                            LocaleKeys.workspace_errorActions_reportIssue.tr(),
                        height: 40,
                        onPressed: () => afLaunchUrlString(
                          'https://github.com/AppFlowy-IO/AppFlowy/issues/new?assignees=&labels=&projects=&template=bug_report.yaml&title=[Bug]%20Workspace%20failed%20to%20load&version=$version&os=$os',
                        ),
                      ),
                    ),
                    const HSpace(20),
                    Flexible(
                      child: RoundedTextButton(
                        title: LocaleKeys.workspace_errorActions_reachOut.tr(),
                        height: 40,
                        onPressed: () =>
                            afLaunchUrlString('https://discord.gg/JucBXeU2FE'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
