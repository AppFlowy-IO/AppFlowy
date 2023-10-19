import 'package:appflowy/mobile/presentation/presentation.dart';

import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:flutter/material.dart';

class MobileHomeSettingPage extends StatefulWidget {
  const MobileHomeSettingPage({
    super.key,
  });

  static const routeName = '/MobileHomeSettingPage';

  @override
  State<MobileHomeSettingPage> createState() => _MobileHomeSettingPageState();
}

class _MobileHomeSettingPageState extends State<MobileHomeSettingPage> {
  // TODO(yijing):remove this after notification page is implemented
  bool isPushNotificationOn = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder(
      future: getIt<AuthService>().getUser(),
      builder: ((context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        final userProfile = snapshot.data?.fold((error) => null, (userProfile) {
          return userProfile;
        });
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  //Personal Information
                  SettingPersonalInfoWidget(
                    userProfile: userProfile,
                  ),
                  // TODO(yijing): implement this along with Notification Page
                  const SettingNotificationsWidget(),
                  const SettingAppearanceWidget(),
                  const SettingSupportWidget(),
                  const SettingAboutWidget(),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
