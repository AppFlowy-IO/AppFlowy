import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/mobile/presentation/home/mobile_home_setting_page.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MobileHomePageHeader extends StatelessWidget {
  const MobileHomePageHeader({
    super.key,
    required this.userProfile,
  });

  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // TODO: implement the details later.
    return SizedBox(
      height: 80,
      child: Row(
        children: [
          const FlowyText(
            '🐻',
            fontSize: 26,
          ),
          const HSpace(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TODO: replace with the real data
                Row(
                  children: [
                    const FlowyText.medium(
                      'AppFlowy',
                      fontSize: 18,
                    ),
                    // temporary placeholder for log out icon button
                    // needs to be replaced with workspace switcher and log out
                    IconButton(
                      onPressed: () => showDialog<String>(
                        context: context,
                        builder: (BuildContext context) => AlertDialog(
                          title: const Text('Log out'),
                          content:
                              const Text('Are you sure you want to log out?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.pop(context, 'Cancel'),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                await getIt<AuthService>().signOut();
                                runAppFlowy();
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      ),
                      icon: const Icon(
                        Icons.arrow_drop_down,
                      ),
                    )
                  ],
                ),
                FlowyText.regular(
                  userProfile.email.isNotEmpty
                      ? userProfile.email
                      : userProfile.name,
                  fontSize: 12,
                  color: theme.colorScheme.onSurface,
                  overflow: TextOverflow.ellipsis,
                )
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              context.push(MobileHomeSettingPage.routeName);
            },
            icon: const FlowySvg(
              FlowySvgs.m_setting_m,
            ),
          )
        ],
      ),
    );
  }
}
