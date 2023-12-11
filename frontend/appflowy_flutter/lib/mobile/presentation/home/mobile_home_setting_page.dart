import 'package:appflowy/env/env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/setting/cloud/cloud_setting_group.dart';
import 'package:appflowy/mobile/presentation/presentation.dart';
import 'package:appflowy/mobile/presentation/setting/logout_setting_group.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class MobileHomeSettingPage extends StatefulWidget {
  const MobileHomeSettingPage({
    super.key,
  });

  static const routeName = '/settings';

  @override
  State<MobileHomeSettingPage> createState() => _MobileHomeSettingPageState();
}

class _MobileHomeSettingPageState extends State<MobileHomeSettingPage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getIt<AuthService>().getUser(),
      builder: ((context, snapshot) {
        String? errorMsg;
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        final userProfile = snapshot.data?.fold((error) {
          errorMsg = error.msg;
          return null;
        }, (userProfile) {
          return userProfile;
        });

        return Scaffold(
          appBar: AppBar(
            title: Text(LocaleKeys.settings_title.tr()),
          ),
          body: userProfile == null
              ? FlowyMobileStateContainer.error(
                  emoji: '🛸',
                  title: LocaleKeys.settings_mobile_userprofileError.tr(),
                  description: LocaleKeys
                      .settings_mobile_userprofileErrorDescription
                      .tr(),
                  errorMsg: errorMsg,
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        PersonalInfoSettingGroup(
                          userProfile: userProfile,
                        ),
                        // TODO(yijing): implement this along with Notification Page
                        const NotificationsSettingGroup(),
                        const AppearanceSettingGroup(),
                        const LanguageSettingGroup(),
                        if (Env.enableCustomCloud) const CloudSettingGroup(),
                        const SupportSettingGroup(),
                        const AboutSettingGroup(),
                        const LogoutSettingGroup(),
                      ],
                    ),
                  ),
                ),
        );
      }),
    );
  }
}
