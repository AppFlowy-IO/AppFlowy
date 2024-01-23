import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/_restart_app_button.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class SettingLocalCloud extends StatelessWidget {
  final VoidCallback didResetServerUrl;
  const SettingLocalCloud({
    required this.didResetServerUrl,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return RestartButton(
      onClick: () => onPressed(context),
    );
  }

  void onPressed(BuildContext context) {
    NavigatorAlertDialog(
      title: LocaleKeys.settings_menu_restartAppTip.tr(),
      confirm: () async {
        await setAuthenticatorType(
          AuthenticatorType.local,
        );
        didResetServerUrl();
      },
    ).show(context);
  }
}
