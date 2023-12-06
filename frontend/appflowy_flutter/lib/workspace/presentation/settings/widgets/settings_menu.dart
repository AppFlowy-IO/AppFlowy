import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/settings_dialog_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_menu_element.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class SettingsMenu extends StatelessWidget {
  const SettingsMenu({
    Key? key,
    required this.changeSelectedPage,
    required this.currentPage,
  }) : super(key: key);

  final Function changeSelectedPage;
  final SettingsPage currentPage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsMenuElement(
          page: SettingsPage.appearance,
          selectedPage: currentPage,
          label: LocaleKeys.settings_menu_appearance.tr(),
          icon: Icons.brightness_4,
          changeSelectedPage: changeSelectedPage,
        ),
        const SizedBox(height: 10),
        SettingsMenuElement(
          page: SettingsPage.language,
          selectedPage: currentPage,
          label: LocaleKeys.settings_menu_language.tr(),
          icon: Icons.translate,
          changeSelectedPage: changeSelectedPage,
        ),
        const SizedBox(height: 10),
        SettingsMenuElement(
          page: SettingsPage.files,
          selectedPage: currentPage,
          label: LocaleKeys.settings_menu_files.tr(),
          icon: Icons.file_present_outlined,
          changeSelectedPage: changeSelectedPage,
        ),
        const SizedBox(height: 10),
        SettingsMenuElement(
          page: SettingsPage.user,
          selectedPage: currentPage,
          label: LocaleKeys.settings_menu_user.tr(),
          icon: Icons.account_box_outlined,
          changeSelectedPage: changeSelectedPage,
        ),
        const SizedBox(height: 10),
        SettingsMenuElement(
          page: SettingsPage.notifications,
          selectedPage: currentPage,
          label: LocaleKeys.settings_menu_notifications.tr(),
          icon: Icons.notifications_outlined,
          changeSelectedPage: changeSelectedPage,
        ),
        const SizedBox(height: 10),
        SettingsMenuElement(
          page: SettingsPage.cloud,
          selectedPage: currentPage,
          label: LocaleKeys.settings_menu_cloudSettings.tr(),
          icon: Icons.sync,
          changeSelectedPage: changeSelectedPage,
        ),
        const SizedBox(height: 10),
        SettingsMenuElement(
          page: SettingsPage.shortcuts,
          selectedPage: currentPage,
          label: LocaleKeys.settings_shortcuts_shortcutsLabel.tr(),
          icon: Icons.cut,
          changeSelectedPage: changeSelectedPage,
        ),
      ],
    );
  }
}
