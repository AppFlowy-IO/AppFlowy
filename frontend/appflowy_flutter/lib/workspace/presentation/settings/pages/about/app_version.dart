import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/tasks/device_info_task.dart';
import 'package:appflowy_backend/log.dart';
import 'package:auto_updater/auto_updater.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class SettingsAppVersion extends StatelessWidget {
  const SettingsAppVersion({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ApplicationInfo.isUpdateAvailable
        ? const _UpdateAppSection()
        : _buildIsUpToDate();
  }

  Widget _buildIsUpToDate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FlowyText.regular('AppFlowy is up to date!'),
        FlowyText.regular(
          'Version ${ApplicationInfo.applicationVersion} (Official build)',
        ),
      ],
    );
  }
}

class _UpdateAppSection extends StatelessWidget {
  const _UpdateAppSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildDescription(context)),
        _buildUpdateButton(),
      ],
    );
  }

  Widget _buildUpdateButton() {
    return PrimaryRoundedButton(
      text: LocaleKeys.autoUpdate_settingsUpdateButton.tr(),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      fontWeight: FontWeight.w500,
      radius: 8.0,
      onTap: () {
        Log.info('[AutoUpdater] Checking for updates');
        autoUpdater.checkForUpdates();
      },
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildRedDot(),
            const HSpace(6),
            Flexible(
              child: FlowyText.medium(
                LocaleKeys.autoUpdate_settingsUpdateTitle.tr(
                  namedArgs: {
                    'newVersion': ApplicationInfo.latestVersion,
                  },
                ),
                figmaLineHeight: 17,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const VSpace(4),
        _buildCurrentVersionAndLatestVersion(context),
      ],
    );
  }

  Widget _buildCurrentVersionAndLatestVersion(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Opacity(
            opacity: 0.7,
            child: FlowyText.regular(
              LocaleKeys.autoUpdate_settingsUpdateDescription.tr(
                namedArgs: {
                  'currentVersion': ApplicationInfo.applicationVersion,
                  'newVersion': ApplicationInfo.latestVersion,
                },
              ),
              fontSize: 12,
              figmaLineHeight: 13,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const HSpace(6),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              afLaunchUrlString('https://www.appflowy.io/what-is-new');
            },
            child: FlowyText.regular(
              LocaleKeys.autoUpdate_settingsUpdateWhatsNew.tr(),
              decoration: TextDecoration.underline,
              color: Theme.of(context).colorScheme.primary,
              fontSize: 12,
              figmaLineHeight: 13,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRedDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Color(0xFFFB006D),
        shape: BoxShape.circle,
      ),
    );
  }
}
