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
      groupTitle: 'About',
      settingItemList: [
        MobileSettingItem(
          name: 'Privacy Policy',
          trailing: const Icon(
            Icons.chevron_right,
          ),
          onTap: () {
            context.push(PrivacyPolicyPage.routeName);
          },
        ),
        MobileSettingItem(
          name: 'User Agreement',
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
