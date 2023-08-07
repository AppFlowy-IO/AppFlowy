import 'package:appflowy/env/env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/settings_dialog_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_menu_element.dart';
import 'package:appflowy_backend/protobuf/flowy-user/auth.pbenum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
        const SizedBox(
          height: 10,
        ),
        SettingsMenuElement(
          page: SettingsPage.language,
          selectedPage: currentPage,
          label: LocaleKeys.settings_menu_language.tr(),
          icon: Icons.translate,
          changeSelectedPage: changeSelectedPage,
        ),
        const SizedBox(
          height: 10,
        ),
        SettingsMenuElement(
          page: SettingsPage.files,
          selectedPage: currentPage,
          label: LocaleKeys.settings_menu_files.tr(),
          icon: Icons.file_present_outlined,
          changeSelectedPage: changeSelectedPage,
        ),
        const SizedBox(
          height: 10,
        ),
        SettingsMenuElement(
          page: SettingsPage.user,
          selectedPage: currentPage,
          label: LocaleKeys.settings_menu_user.tr(),
          icon: Icons.account_box_outlined,
          changeSelectedPage: changeSelectedPage,
        ),

        // Only show supabase setting if supabase is enabled and the current auth type is not local
        if (isSupabaseEnabled &&
            context.read<SettingsDialogBloc>().state.userProfile.authType !=
                AuthTypePB.Local)
          SettingsMenuElement(
            page: SettingsPage.syncSetting,
            selectedPage: currentPage,
            label: LocaleKeys.settings_menu_syncSetting.tr(),
            icon: Icons.sync,
            changeSelectedPage: changeSelectedPage,
          ),
        const SizedBox(
          height: 10,
        ),
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
