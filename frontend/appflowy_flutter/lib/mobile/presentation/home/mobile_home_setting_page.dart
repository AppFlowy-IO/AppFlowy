import 'dart:io';

import 'package:appflowy/env/env.dart';
import 'package:appflowy/mobile/presentation/presentation.dart';

import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/workspace/application/user/prelude.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
                  BlocProvider<SettingsUserViewBloc>(
                    create: (context) => getIt<SettingsUserViewBloc>(
                      param1: userProfile,
                    )..add(const SettingsUserEvent.initial()),
                    child: BlocSelector<SettingsUserViewBloc, SettingsUserState,
                        String>(
                      selector: (state) => state.userProfile.name,
                      builder: (context, userName) {
                        return MobileSettingGroupWidget(
                          groupTitle: 'Personal Information',
                          settingItemWidgets: [
                            MobileSettingItemWidget(
                              name: userName,
                              subtitle: isCloudEnabled && userProfile != null
                                  ? Text(
                                      userProfile.email,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    )
                                  : null,
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                showModalBottomSheet<void>(
                                  context: context,
                                  // avoid bottom sheet overflow from resizing when keyboard appears
                                  isScrollControlled: true,
                                  builder: (_) {
                                    return EditUsernameBottomSheet(
                                      context,
                                      userName: userName,
                                      onSubmitted: (value) {
                                        context
                                            .read<SettingsUserViewBloc>()
                                            .add(
                                              SettingsUserEvent.updateUserName(
                                                value,
                                              ),
                                            );
                                      },
                                    );
                                  },
                                );
                              },
                            )
                          ],
                        );
                      },
                    ),
                  ),
                  // TODO(yijing): implement this along with Notification Page
                  MobileSettingGroupWidget(
                    groupTitle: 'Notifications',
                    settingItemWidgets: [
                      MobileSettingItemWidget(
                        name: 'Push Notifications',
                        trailing: Switch.adaptive(
                          activeColor: theme.colorScheme.primary,
                          value: isPushNotificationOn,
                          onChanged: (bool value) {
                            setState(() {
                              isPushNotificationOn = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SettingAppearanceWidget(),
                  MobileSettingGroupWidget(
                    groupTitle: 'Support',
                    settingItemWidgets: [
                      // 'Help Center'
                      MobileSettingItemWidget(
                        name: 'Join us in Discord',
                        trailing: const Icon(
                          Icons.chevron_right,
                        ),
                        onTap: () =>
                            safeLaunchUrl('https://discord.gg/JucBXeU2FE'),
                      ),
                      MobileSettingItemWidget(
                        name: 'Report an issue',
                        trailing: const Icon(
                          Icons.chevron_right,
                        ),
                        onTap: () {
                          // TODO(yijing): get app version before release
                          const String version = 'Beta';
                          final String os = Platform.operatingSystem;
                          safeLaunchUrl(
                            'https://github.com/AppFlowy-IO/AppFlowy/issues/new?assignees=&labels=&projects=&template=bug_report.yaml&title=[Bug]%20Mobile:%20&version=$version&os=$os',
                          );
                        },
                      ),
                    ],
                  ),
                  MobileSettingGroupWidget(
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
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
