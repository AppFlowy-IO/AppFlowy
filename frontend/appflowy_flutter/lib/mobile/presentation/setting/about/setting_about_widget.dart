import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/widgets.dart';
import 'about.dart';

class SettingAboutWidget extends StatelessWidget {
  const SettingAboutWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MobileSettingGroupWidget(
      groupTitle: 'About',
      settingItemWidgets: [
        MobileSettingItemWidget(
          name: 'Privacy Policy',
          trailing: const Icon(
            Icons.chevron_right,
          ),
          onTap: () {
            context.push(PrivacyPolicyPage.routeName);
          },
        ),
        MobileSettingItemWidget(
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
