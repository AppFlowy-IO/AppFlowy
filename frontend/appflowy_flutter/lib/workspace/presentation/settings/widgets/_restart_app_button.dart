import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/sign_in_or_logout_button.dart';
import 'package:appflowy_editor/appflowy_editor.dart' show PlatformExtension;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

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
    final List<Widget> children = [_buildRestartButton(context)];
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

  Widget _buildRestartButton(BuildContext context) {
    if (PlatformExtension.isDesktopOrWeb) {
      return Row(
        children: [
          SizedBox(
            height: 42,
            child: FlowyTextButton(
              LocaleKeys.settings_manageDataPage_dataStorage_actions_change
                  .tr(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              fontWeight: FontWeight.w600,
              radius: BorderRadius.circular(12),
              fillColor: Theme.of(context).colorScheme.primary,
              hoverColor: const Color(0xFF005483),
              fontHoverColor: Colors.white,
              onPressed: onClick,
            ),
          ),
        ],
      );
      // Row(
      //   children: [
      //     FlowyButton(
      //       isSelected: true,
      //       useIntrinsicWidth: true,
      //       margin: const EdgeInsets.symmetric(
      //         horizontal: 30,
      //         vertical: 10,
      //       ),
      //       text: FlowyText(
      //         LocaleKeys.settings_menu_restartApp.tr(),
      //       ),
      //       onTap: onClick,
      //     ),
      //     const Spacer(),
      //   ],
      // );
    } else {
      return MobileSignInOrLogoutButton(
        labelText: LocaleKeys.settings_menu_restartApp.tr(),
        onPressed: onClick,
      );
    }
  }
}
