import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/tasks/device_info_task.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/feature_flags/mobile_feature_flag_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
          onTap: () => afLaunchUrlString('https://appflowy.io/privacy/app'),
        ),
        MobileSettingItem(
          name: LocaleKeys.settings_mobile_termsAndConditions.tr(),
          trailing: const Icon(
            Icons.chevron_right,
          ),
          onTap: () => afLaunchUrlString('https://appflowy.io/terms/app'),
        ),
        if (kDebugMode)
          MobileSettingItem(
            name: 'Feature Flags',
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () {
              context.push(FeatureFlagScreen.routeName);
            },
          ),
        MobileSettingItem(
          name: LocaleKeys.settings_mobile_version.tr(),
          trailing: FlowyText(
            '${ApplicationInfo.applicationVersion} (${ApplicationInfo.buildNumber})',
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
