import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/feature_flags.dart';
import 'package:appflowy/workspace/application/settings/settings_dialog_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_menu_element.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/separated_flex.dart';

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
    return Column(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8) +
                const EdgeInsets.only(left: 8, right: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
            child: SingleChildScrollView(
              // Right padding is added to make the scrollbar centered
              // in the space between the menu and the content
              padding: const EdgeInsets.only(right: 4) +
                  const EdgeInsets.symmetric(vertical: 16),
              physics: const ClampingScrollPhysics(),
              child: SeparatedColumn(
                separatorBuilder: () => const SizedBox(height: 16),
                children: [
                  SettingsMenuElement(
                    page: SettingsPage.account,
                    selectedPage: currentPage,
                    label: LocaleKeys.settings_account_menuLabel.tr(),
                    icon: FlowySvgs.settings_account_m,
                    changeSelectedPage: changeSelectedPage,
                  ),
                  SettingsMenuElement(
                    page: SettingsPage.workspace,
                    selectedPage: currentPage,
                    label: LocaleKeys.settings_workspace_menuLabel.tr(),
                    icon: FlowySvgs.settings_workplace_m,
                    changeSelectedPage: changeSelectedPage,
                  ),
                  if (FeatureFlag.membersSettings.isOn)
                    SettingsMenuElement(
                      page: SettingsPage.member,
                      selectedPage: currentPage,
                      label: LocaleKeys.settings_appearance_members_label.tr(),
                      icon: FlowySvgs.settings_members_m,
                      changeSelectedPage: changeSelectedPage,
                    ),
                  SettingsMenuElement(
                    page: SettingsPage.manageData,
                    selectedPage: currentPage,
                    label: LocaleKeys.settings_manageData_menuLabel.tr(),
                    icon: FlowySvgs.settings_data_m,
                    changeSelectedPage: changeSelectedPage,
                  ),
                  // SettingsMenuElement(
                  //   page: SettingsPage.appearance,
                  //   selectedPage: currentPage,
                  //   label: LocaleKeys.settings_menu_appearance.tr(),
                  //   icon: Icons.brightness_4,
                  //   changeSelectedPage: changeSelectedPage,
                  // ),
                  // SettingsMenuElement(
                  //   page: SettingsPage.language,
                  //   selectedPage: currentPage,
                  //   label: LocaleKeys.settings_menu_language.tr(),
                  //   icon: Icons.translate,
                  //   changeSelectedPage: changeSelectedPage,
                  // ),
                  // SettingsMenuElement(
                  //   page: SettingsPage.files,
                  //   selectedPage: currentPage,
                  //   label: LocaleKeys.settings_menu_files.tr(),
                  //   icon: Icons.file_present_outlined,
                  //   changeSelectedPage: changeSelectedPage,
                  // ),
                  // SettingsMenuElement(
                  //   page: SettingsPage.user,
                  //   selectedPage: currentPage,
                  //   label: LocaleKeys.settings_menu_user.tr(),
                  //   icon: Icons.account_box_outlined,
                  //   changeSelectedPage: changeSelectedPage,
                  // ),
                  // SettingsMenuElement(
                  //   page: SettingsPage.notifications,
                  //   selectedPage: currentPage,
                  //   label: LocaleKeys.settings_menu_notifications.tr(),
                  //   icon: Icons.notifications_outlined,
                  //   changeSelectedPage: changeSelectedPage,
                  // ),
                  // SettingsMenuElement(
                  //   page: SettingsPage.cloud,
                  //   selectedPage: currentPage,
                  //   label: LocaleKeys.settings_menu_cloudSettings.tr(),
                  //   icon: Icons.sync,
                  //   changeSelectedPage: changeSelectedPage,
                  // ),
                  // SettingsMenuElement(
                  //   page: SettingsPage.shortcuts,
                  //   selectedPage: currentPage,
                  //   label: LocaleKeys.settings_shortcuts_shortcutsLabel.tr(),
                  //   icon: Icons.cut,
                  //   changeSelectedPage: changeSelectedPage,
                  // ),
                  if (kDebugMode)
                    SettingsMenuElement(
                      // no need to translate this page
                      page: SettingsPage.featureFlags,
                      selectedPage: currentPage,
                      label: 'Feature Flags',
                      icon: FlowySvgs.folder_m,
                      changeSelectedPage: changeSelectedPage,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
