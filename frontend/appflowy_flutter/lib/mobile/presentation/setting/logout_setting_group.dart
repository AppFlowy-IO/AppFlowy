import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class LogoutSettingGroup extends StatelessWidget {
  const LogoutSettingGroup({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: FlowyButton(
            margin: const EdgeInsets.symmetric(
              vertical: 16.0,
            ),
            text: FlowyText.medium(
              LocaleKeys.settings_menu_logout.tr(),
              textAlign: TextAlign.center,
              fontSize: 14.0,
            ),
            onTap: () async {
              await getIt<AuthService>().signOut();
              runAppFlowy();
            },
          ),
        ),
      ],
    );
  }
}
