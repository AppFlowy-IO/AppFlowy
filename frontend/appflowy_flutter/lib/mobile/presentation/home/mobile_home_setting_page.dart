import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/env/env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar/app_bar.dart';
import 'package:appflowy/mobile/presentation/presentation.dart';
import 'package:appflowy/mobile/presentation/setting/cloud/cloud_setting_group.dart';
import 'package:appflowy/mobile/presentation/setting/user_session_setting_group.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
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
      builder: (context, snapshot) {
        String? errorMsg;
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        final userProfile = snapshot.data?.fold(
          (userProfile) {
            return userProfile;
          },
          (error) {
            errorMsg = error.msg;
            return null;
          },
        );

        return Scaffold(
          appBar: FlowyAppBar(
            titleText: LocaleKeys.settings_title.tr(),
          ),
          body: userProfile == null
              ? _buildErrorWidget(errorMsg)
              : _buildSettingsWidget(userProfile),
        );
      },
    );
  }

  Widget _buildErrorWidget(String? errorMsg) {
    return FlowyMobileStateContainer.error(
      emoji: '🛸',
      title: LocaleKeys.settings_mobile_userprofileError.tr(),
      description: LocaleKeys.settings_mobile_userprofileErrorDescription.tr(),
      errorMsg: errorMsg,
    );
  }

  Widget _buildSettingsWidget(UserProfilePB userProfile) {
    // show the third-party sign in buttons if user logged in with local session and auth is enabled.

    final showThirdPartyLogin =
        userProfile.authenticator == AuthenticatorPB.Local && isAuthEnabled;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            PersonalInfoSettingGroup(
              userProfile: userProfile,
            ),
            // TODO: Enable and implement along with Push Notifications
            // const NotificationsSettingGroup(),
            const AppearanceSettingGroup(),
            const LanguageSettingGroup(),
            if (Env.enableCustomCloud) const CloudSettingGroup(),
            const SupportSettingGroup(),
            const AboutSettingGroup(),
            UserSessionSettingGroup(
              showThirdPartyLogin: showThirdPartyLogin,
            ),
            const VSpace(20),
          ],
        ),
      ),
    );
  }
}
