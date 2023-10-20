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
  @override
  Widget build(BuildContext context) {
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
                  PersonalInfoSettingGroup(
                    userProfile: userProfile,
                  ),
                  // TODO(yijing): implement this along with Notification Page
                  const NotificationsSettingGroup(),
                  const AppearanceSettingGroup(),
                  const SupportSettingGroup(),
                  const AboutSettingGroup(),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
