import 'dart:io';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Used to display error state and report error message in github
class FlowyMobileErrorStateContainer extends StatelessWidget {
  const FlowyMobileErrorStateContainer({
    this.emoji,
    required this.title,
    this.description,
    this.errorMsg,
    super.key,
  });

  final String? emoji;
  final String title;
  final String? description;
  final String? errorMsg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              emoji ?? '',
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 4),
            Text(
              description ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton(
                  onPressed: () {
                    // TODO(yijing): get app version before release
                    const String version = 'Beta';
                    final String os = Platform.operatingSystem;
                    safeLaunchUrl(
                      'https://github.com/AppFlowy-IO/AppFlowy/issues/new?assignees=&labels=&projects=&template=bug_report.yaml&title=[Bug]%20Mobile:%20&version=$version&os=$os&context=Error%20log:%20$errorMsg',
                    );
                  },
                  child: Text(
                    LocaleKeys.workspace_errorActions_reportIssue.tr(),
                  ),
                ),
                OutlinedButton(
                  onPressed: () =>
                      safeLaunchUrl('https://discord.gg/JucBXeU2FE'),
                  child: Text(
                    LocaleKeys.workspace_errorActions_reachOut.tr(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
