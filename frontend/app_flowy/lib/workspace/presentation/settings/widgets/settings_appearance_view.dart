import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/workspace/application/appearance.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsAppearanceView extends StatelessWidget {
  const SettingsAppearanceView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: BlocBuilder<AppearanceSettingsCubit, AppearanceSettingsState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ThemeModeSetting(currentThemeMode: state.themeMode),
              ThemeTypeSetting(currentThemeType: state.appTheme.themeName),
            ],
          );
        },
      ),
    );
  }
}

class ThemeTypeSetting extends StatelessWidget {
  final String currentThemeType;
  const ThemeTypeSetting({
    super.key,
    required this.currentThemeType,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FlowyText.medium(
            LocaleKeys.settings_appearance_themeType_label.tr(),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppFlowyPopover(
          direction: PopoverDirection.bottomWithRightAligned,
          child: FlowyTextButton(
            getThemeNameForDisplaying(currentThemeType),
            fillColor: Colors.transparent,
            hoverColor: Theme.of(context).colorScheme.secondary,
            onPressed: () {},
          ),
          popupBuilder: (BuildContext context) {
            return IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _themeTypeItemButton(context, BuiltInTheme.light),
                  _themeTypeItemButton(context, BuiltInTheme.dandelion),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _themeTypeItemButton(BuildContext context, String themeType) {
    return SizedBox(
      height: 32,
      child: FlowyButton(
        text: FlowyText.medium(getThemeNameForDisplaying(themeType)),
        rightIcon: currentThemeType == themeType
            ? svgWidget("grid/checkmark")
            : const SizedBox(),
        onTap: () {
          if (currentThemeType != themeType) {
            context.read<AppearanceSettingsCubit>().setTheme(themeType);
          }
        },
      ),
    );
  }

  String getThemeNameForDisplaying(String themeName) {
    switch (themeName) {
      case BuiltInTheme.light:
        return LocaleKeys.settings_appearance_themeType_defaultTheme.tr();
      case BuiltInTheme.dandelion:
        return LocaleKeys.settings_appearance_themeType_dandelionCommunity.tr();
      default:
        throw Exception("Unknown ThemeType");
    }
  }
}

class ThemeModeSetting extends StatelessWidget {
  final ThemeMode currentThemeMode;
  const ThemeModeSetting({required this.currentThemeMode, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FlowyText.medium(
            LocaleKeys.settings_appearance_themeMode_label.tr(),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppFlowyPopover(
          direction: PopoverDirection.bottomWithRightAligned,
          child: FlowyTextButton(
            _themeModeLabelText(currentThemeMode),
            fillColor: Colors.transparent,
            hoverColor: Theme.of(context).colorScheme.secondary,
            onPressed: () {},
          ),
          popupBuilder: (BuildContext context) {
            return IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _themeModeItemButton(context, ThemeMode.light),
                  _themeModeItemButton(context, ThemeMode.dark),
                  _themeModeItemButton(context, ThemeMode.system),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _themeModeItemButton(BuildContext context, ThemeMode themeMode) {
    return SizedBox(
      height: 32,
      child: FlowyButton(
        text: FlowyText.medium(_themeModeLabelText(themeMode)),
        rightIcon: currentThemeMode == themeMode
            ? svgWidget("grid/checkmark")
            : const SizedBox(),
        onTap: () {
          if (currentThemeMode != themeMode) {
            context.read<AppearanceSettingsCubit>().setThemeMode(themeMode);
          }
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
