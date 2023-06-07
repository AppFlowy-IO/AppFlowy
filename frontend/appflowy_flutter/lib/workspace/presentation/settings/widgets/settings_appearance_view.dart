import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/appearance.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/theme_upload/theme_upload_view.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ThemeModeSetting(currentThemeMode: state.themeMode),
              ThemeSetting(currentTheme: state.appTheme.themeName),
              const ThemeUploadWidget(),
            ],
          );
        },
      ),
    );
  }
}

class ThemeSetting extends StatelessWidget {
  final String currentTheme;
  const ThemeSetting({
    super.key,
    required this.currentTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FlowyText.medium(
            LocaleKeys.settings_appearance_theme.tr(),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppFlowyPopover(
          direction: PopoverDirection.bottomWithRightAligned,
          child: FlowyTextButton(
            currentTheme,
            fontColor: Theme.of(context).colorScheme.onBackground,
            fillColor: Colors.transparent,
            onPressed: () {},
          ),
          popupBuilder: (BuildContext context) {
            return FutureBuilder<Iterable<String>>(
              future: AppTheme.themes.then(
                (value) => value.map((e) => e.themeName),
              ),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return IntrinsicWidth(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final theme in snapshot.data!)
                          _themeItemButton(context, theme),
                      ],
                    ),
                  );
                } else {
                  // return indicator
                  return const SizedBox();
                }
              },
            );
          },
        ),
      ],
    );
  }

  Widget _themeItemButton(BuildContext context, String theme) {
    return SizedBox(
      height: 32,
      child: FlowyButton(
        text: FlowyText.medium(theme),
        rightIcon: currentTheme == theme
            ? const FlowySvg(name: 'grid/checkmark')
            : null,
        onTap: () {
          if (currentTheme != theme) {
            context.read<AppearanceSettingsCubit>().setTheme(theme);
          }
        },
      ),
    );
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
            fontColor: Theme.of(context).colorScheme.onBackground,
            fillColor: Colors.transparent,
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
            ? const FlowySvg(name: 'grid/checkmark')
            : null,
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
