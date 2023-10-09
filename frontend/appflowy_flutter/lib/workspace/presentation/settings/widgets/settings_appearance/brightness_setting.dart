import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/appearance.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'theme_setting_entry_template.dart';

class BrightnessSetting extends StatelessWidget {
  final ThemeMode currentThemeMode;
  const BrightnessSetting({required this.currentThemeMode, super.key});

  @override
  Widget build(BuildContext context) {
    return ThemeSettingEntryTemplateWidget(
      label: LocaleKeys.settings_appearance_themeMode_label.tr(),
      hint: hintText,
      onResetRequested: context.read<AppearanceSettingsCubit>().resetThemeMode,
      trailing: [
        ThemeValueDropDown(
          currentValue: _themeModeLabelText(currentThemeMode),
          popupBuilder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _themeModeItemButton(context, ThemeMode.light),
              _themeModeItemButton(context, ThemeMode.dark),
              _themeModeItemButton(context, ThemeMode.system),
            ],
          ),
        ),
      ],
    );
  }

  String get hintText =>
      '${LocaleKeys.settings_files_change.tr()} ${LocaleKeys.settings_appearance_themeMode_label.tr()} : ${Platform.isMacOS ? '⌘+Shift+L' : 'Ctrl+Shift+L'}';

  Widget _themeModeItemButton(
    BuildContext context,
    ThemeMode themeMode,
  ) {
    return SizedBox(
      height: 32,
      child: FlowyButton(
        text: FlowyText.medium(_themeModeLabelText(themeMode)),
        rightIcon: currentThemeMode == themeMode
            ? const FlowySvg(
                FlowySvgs.check_s,
              )
            : null,
        onTap: () {
          if (currentThemeMode != themeMode) {
            context.read<AppearanceSettingsCubit>().setThemeMode(themeMode);
          }
          PopoverContainer.of(context).close();
        },
      ),
    );
  }

  String _themeModeLabelText(ThemeMode themeMode) {
    switch (themeMode) {
      case (ThemeMode.light):
        return LocaleKeys.settings_appearance_themeMode_light.tr();
      case (ThemeMode.dark):
        return LocaleKeys.settings_appearance_themeMode_dark.tr();
      case (ThemeMode.system):
        return LocaleKeys.settings_appearance_themeMode_system.tr();
      default:
        return "";
    }
  }
}
