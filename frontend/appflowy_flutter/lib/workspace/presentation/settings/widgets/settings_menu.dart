import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/feature_flags.dart';
import 'package:appflowy/workspace/application/settings/settings_dialog_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_menu_element.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SettingsMenu extends StatelessWidget {
  const SettingsMenu({
    super.key,
    required this.changeSelectedPage,
    required this.currentPage,
    required this.userProfile,
  });

  final Function changeSelectedPage;
  final SettingsPage currentPage;
  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SeparatedColumn(
        separatorBuilder: () => const SizedBox(height: 10),
        children: [
          SettingsMenuElement(
            page: SettingsPage.appearance,
            selectedPage: currentPage,
            label: LocaleKeys.settings_menu_appearance.tr(),
            icon: Icons.brightness_4,
            changeSelectedPage: changeSelectedPage,
          ),
          SettingsMenuElement(
            page: SettingsPage.language,
            selectedPage: currentPage,
            label: LocaleKeys.settings_menu_language.tr(),
            icon: Icons.translate,
            changeSelectedPage: changeSelectedPage,
          ),
          SettingsMenuElement(
            page: SettingsPage.files,
            selectedPage: currentPage,
            label: LocaleKeys.settings_menu_files.tr(),
            icon: Icons.file_present_outlined,
            changeSelectedPage: changeSelectedPage,
          ),
          SettingsMenuElement(
            page: SettingsPage.user,
            selectedPage: currentPage,
            label: LocaleKeys.settings_menu_user.tr(),
            icon: Icons.account_box_outlined,
            changeSelectedPage: changeSelectedPage,
          ),
          SettingsMenuElement(
            page: SettingsPage.notifications,
            selectedPage: currentPage,
            label: LocaleKeys.settings_menu_notifications.tr(),
            icon: Icons.notifications_outlined,
            changeSelectedPage: changeSelectedPage,
          ),
          SettingsMenuElement(
            page: SettingsPage.cloud,
            selectedPage: currentPage,
            label: LocaleKeys.settings_menu_cloudSettings.tr(),
            icon: Icons.sync,
            changeSelectedPage: changeSelectedPage,
          ),
          SettingsMenuElement(
            page: SettingsPage.shortcuts,
            selectedPage: currentPage,
            label: LocaleKeys.settings_shortcuts_shortcutsLabel.tr(),
            icon: Icons.cut,
            changeSelectedPage: changeSelectedPage,
          ),
          if (FeatureFlag.membersSettings.isOn &&
              userProfile.authenticator == AuthenticatorPB.AppFlowyCloud)
            SettingsMenuElement(
              page: SettingsPage.member,
              selectedPage: currentPage,
              label: LocaleKeys.settings_appearance_members_label.tr(),
              icon: Icons.people,
              changeSelectedPage: changeSelectedPage,
            ),
          if (kDebugMode)
            SettingsMenuElement(
              // no need to translate this page
              page: SettingsPage.featureFlags,
              selectedPage: currentPage,
              label: 'Feature Flags',
              icon: Icons.flag,
              changeSelectedPage: changeSelectedPage,
            ),
        ],
      ),
    );
  }
}
