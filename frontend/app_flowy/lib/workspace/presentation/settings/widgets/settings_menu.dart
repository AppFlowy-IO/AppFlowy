import 'package:app_flowy/workspace/presentation/settings/widgets/settings_menu_element.dart';
import 'package:flutter/material.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

class SettingsMenu extends StatelessWidget {
  const SettingsMenu({
    Key? key,
    required this.changeSelectedIndex,
    required this.currentIndex,
  }) : super(key: key);

  final Function changeSelectedIndex;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsMenuElement(
          index: 0,
          currentIndex: currentIndex,
          label: LocaleKeys.settings_menu_appearance.tr(),
          icon: Icons.brightness_4,
          changeSelectedIndex: changeSelectedIndex,
        ),
        const SizedBox(
          height: 10,
        ),
        SettingsMenuElement(
          index: 1,
          currentIndex: currentIndex,
          label: LocaleKeys.settings_menu_language.tr(),
          icon: Icons.translate,
          changeSelectedIndex: changeSelectedIndex,
        ),
      ],
    );
  }
}
