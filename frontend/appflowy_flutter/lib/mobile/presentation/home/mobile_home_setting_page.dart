import 'package:appflowy/env/env.dart';
import 'package:appflowy/mobile/presentation/presentation.dart';

import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/workspace/application/user/prelude.dart';
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
  // TODO(yijing):get value from backend
  bool isPushNotificationOn = false;
  bool isAutoDarkModeOn = false;
  bool isDarkModeOn = false;
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
                                  ? Text(userProfile.email)
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
                  MobileSettingGroupWidget(
                    groupTitle: 'Apperance',
                    settingItemWidgets: [
                      MobileSettingItemWidget(
                        name: 'Theme Mode',
                        trailing: Switch.adaptive(
                          activeColor: theme.colorScheme.primary,
                          value: isAutoDarkModeOn,
                          onChanged: (bool value) {
                            setState(() {
                              isAutoDarkModeOn = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  MobileSettingGroupWidget(
                    groupTitle: 'Support',
                    settingItemWidgets: [
                      MobileSettingItemWidget(
                        name: 'Help Center',
                        trailing: const Icon(
                          Icons.chevron_right,
                        ),
                        onTap: () {
                          // TODO:navigate to Help Center page
                        },
                      ),
                      MobileSettingItemWidget(
                        name: 'Report an issue',
                        trailing: const Icon(
                          Icons.chevron_right,
                        ),
                        onTap: () {
                          // TODO:navigate to Report an issue page
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

class MobileSettingGroupWidget extends StatelessWidget {
  const MobileSettingGroupWidget({
    required this.groupTitle,
    required this.settingItemWidgets,
    this.showDivider = true,
    super.key,
  });
  final String groupTitle;
  final List<MobileSettingItemWidget> settingItemWidgets;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: 8,
        ),
        Text(
          groupTitle,
          style: theme.textTheme.labelSmall,
        ),
        const SizedBox(
          height: 12,
        ),
        ...settingItemWidgets,
        showDivider ? const Divider() : const SizedBox.shrink(),
      ],
    );
  }
}

class MobileSettingItemWidget extends StatelessWidget {
  const MobileSettingItemWidget({
    super.key,
    required this.name,
    this.subtitle,
    required this.trailing,
    this.onTap,
  });
  final String name;
  final Widget? subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          name,
          style: theme.textTheme.labelMedium,
        ),
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
        visualDensity: VisualDensity.compact,
        // shape: RoundedRectangleBorder(
        //   side: BorderSide(
        //     color: theme.colorScheme.outline,
        //     width: 0.5,
        //   ),
        //   borderRadius: BorderRadius.circular(6),
        // ),
      ),
    );
  }
}
