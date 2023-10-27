import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/widgets.dart';
import 'about.dart';

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
          onTap: () {
            context.push(PrivacyPolicyPage.routeName);
          },
        ),
        MobileSettingItem(
          name: LocaleKeys.settings_mobile_userAgreement.tr(),
          trailing: const Icon(
            Icons.chevron_right,
          ),
          onTap: () {
            context.push(UserAgreementPage.routeName);
          },
        ),
      ],
      showDivider: false,
    );
  }
}
