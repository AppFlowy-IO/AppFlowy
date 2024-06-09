import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/sign_in_or_logout_button.dart';
import 'package:appflowy_editor/appflowy_editor.dart' show PlatformExtension;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class RestartButton extends StatelessWidget {
  const RestartButton({
    super.key,
    required this.showRestartHint,
    required this.onClick,
  });

  final bool showRestartHint;
  final VoidCallback onClick;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [_buildRestartButton()];
    if (showRestartHint) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: FlowyText(
            LocaleKeys.settings_menu_restartAppTip.tr(),
            maxLines: null,
          ),
        ),
      );
    }

    return Column(children: children);
  }

  Widget _buildRestartButton() {
    if (PlatformExtension.isDesktopOrWeb) {
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
            onTap: onClick,
          ),
          const Spacer(),
        ],
      );
    } else {
      return MobileSignInOrLogoutButton(
        labelText: LocaleKeys.settings_menu_restartApp.tr(),
        onPressed: onClick,
      );
    }
  }
}
