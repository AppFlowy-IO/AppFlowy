import 'package:flutter/material.dart';

class MobileHomeSettingPage extends StatefulWidget {
  const MobileHomeSettingPage({super.key});

  // sub-route path may not start or end with '/'
  static const routeName = 'MobileHomeSettingPage';

  @override
  State<MobileHomeSettingPage> createState() => _MobileHomeSettingPageState();
}

class _MobileHomeSettingPageState extends State<MobileHomeSettingPage> {
  // TODO(yijing):get value from backend
  bool isPushNotificationOn = false;
  bool isEmailNotificationOn = false;
  bool isAutoDarkModeOn = false;
  bool isDarkModeOn = false;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              MobileSettingGroupWidget(
                groupTitle: 'Personal Information',
                settingItems: [
                  MobileSettingItem(
                    name: 'Name',
                    trailing: Text(
                      'username',
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
                  MobileSettingItem(
                    name: 'Email',
                    trailing: Text(
                      'email@gmail.com',
                      style: theme.textTheme.labelMedium,
                    ),
                  )
                ],
              ),
              MobileSettingGroupWidget(
                groupTitle: 'Password',
                settingItems: [
                  MobileSettingItem(
                    name: 'Change Password',
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () {
                      // TODO:navigate to change password page
                    },
                  ),
                ],
              ),
              MobileSettingGroupWidget(
                groupTitle: 'Notifications',
                settingItems: [
                  MobileSettingItem(
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
                  MobileSettingItem(
                    name: 'Email Notifications',
                    trailing: Switch.adaptive(
                      activeColor: theme.colorScheme.primary,
                      value: isEmailNotificationOn,
                      onChanged: (bool value) {
                        setState(() {
                          isEmailNotificationOn = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              MobileSettingGroupWidget(
                groupTitle: 'Apperance',
                settingItems: [
                  MobileSettingItem(
                    name: 'Auto Dark Mode',
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
                  MobileSettingItem(
                    name: 'Dark Mode',
                    trailing: Switch.adaptive(
                      activeColor: theme.colorScheme.primary,
                      value: isDarkModeOn,
                      onChanged: (bool value) {
                        setState(() {
                          isDarkModeOn = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              MobileSettingGroupWidget(
                groupTitle: 'Support',
                settingItems: [
                  MobileSettingItem(
                    name: 'Help Center',
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () {
                      // TODO:navigate to Help Center page
                    },
                  ),
                  MobileSettingItem(
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
                settingItems: [
                  MobileSettingItem(
                    name: 'Privacy Policy',
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () {
                      // TODO:navigate to Privacy Policy page
                    },
                  ),
                  MobileSettingItem(
                    name: 'User Agreement',
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () {
                      // TODO:navigate to User Agreement page
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
  }
}

class MobileSettingGroupWidget extends StatelessWidget {
  const MobileSettingGroupWidget({
    required this.groupTitle,
    required this.settingItems,
    this.showDivider = true,
    super.key,
  });
  final String groupTitle;
  final List<MobileSettingItem> settingItems;
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
        ...settingItems
            .map(
              (settingItem) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    settingItem.name,
                    style: theme.textTheme.labelMedium,
                  ),
                  trailing: settingItem.trailing,
                  onTap: settingItem.onTap,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: theme.colorScheme.outline,
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            )
            .toList(),
        showDivider ? const Divider() : const SizedBox.shrink(),
      ],
    );
  }
}

class MobileSettingItem {
  final String name;
  final Widget trailing;
  final VoidCallback? onTap;

  MobileSettingItem({
    required this.name,
    required this.trailing,
    this.onTap,
  });
}
