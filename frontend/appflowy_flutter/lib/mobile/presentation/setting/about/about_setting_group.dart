import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/tasks/device_info_task.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

class AboutSettingGroup extends StatelessWidget {
  const AboutSettingGroup({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MobileSettingGroup(
      groupTitle: LocaleKeys.settings_mobile_about.tr(),
      settingItemList: [
        MobileSettingItem(
          name: LocaleKeys.settings_mobile_privacyPolicy.tr(),
          trailing: const Icon(
            Icons.chevron_right,
          ),
          onTap: () => safeLaunchUrl('https://appflowy.io/privacy/mobile'),
        ),
        MobileSettingItem(
          name: LocaleKeys.settings_mobile_termsAndConditions.tr(),
          trailing: const Icon(
            Icons.chevron_right,
          ),
          onTap: () => safeLaunchUrl('https://appflowy.io/terms'),
        ),
        MobileSettingItem(
          name: LocaleKeys.settings_mobile_version.tr(),
          trailing: FlowyText(
            '${DeviceOrApplicationInfoTask.applicationVersion} (${DeviceOrApplicationInfoTask.buildNumber})',
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
