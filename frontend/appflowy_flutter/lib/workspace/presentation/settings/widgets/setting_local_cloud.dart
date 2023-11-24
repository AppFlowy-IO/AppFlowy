import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';

class SettingLocalCloud extends StatelessWidget {
  final VoidCallback didResetServerUrl;
  const SettingLocalCloud({
    required this.didResetServerUrl,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FlowyButton(
          isSelected: true,
          useIntrinsicWidth: true,
          margin: const EdgeInsets.symmetric(
            horizontal: 30,
            vertical: 10,
          ),
          text: FlowyText(
            LocaleKeys.settings_menu_restartApp.tr(),
          ),
          onTap: () {
            NavigatorAlertDialog(
              title: LocaleKeys.settings_menu_restartAppTip.tr(),
              confirm: didResetServerUrl,
            ).show(context);
          },
        ),
        const Spacer(),
      ],
    );
  }
}
