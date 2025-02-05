import 'package:appflowy/startup/tasks/device_info_task.dart';
import 'package:auto_updater/auto_updater.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class SettingsAppVersion extends StatelessWidget {
  const SettingsAppVersion({super.key});

  @override
  Widget build(BuildContext context) {
    return ApplicationInfo.isUpdateAvailable
        ? _buildUpdateButton()
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

  Widget _buildUpdateButton() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildRedDot(),
                const HSpace(6),
                FlowyText.medium(
                  'New Version (${ApplicationInfo.latestVersion}) Available!',
                  figmaLineHeight: 17,
                ),
              ],
            ),
            const VSpace(4),
            Opacity(
              opacity: 0.7,
              child: FlowyText.regular(
                'Current Version ${ApplicationInfo.applicationVersion} (Official build) → ${ApplicationInfo.latestVersion}',
                fontSize: 12,
                figmaLineHeight: 13,
              ),
            ),
          ],
        ),
        const Spacer(),
        PrimaryRoundedButton(
          text: 'Update now',
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          fontWeight: FontWeight.w500,
          radius: 8.0,
          onTap: () {
            autoUpdater.checkForUpdates();
          },
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
