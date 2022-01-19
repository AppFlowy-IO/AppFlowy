import 'package:flowy_infra/theme.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_flowy/workspace/presentation/theme/theme_model.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';

class SettingsAppearanceView extends StatelessWidget {
  const SettingsAppearanceView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();

    return SingleChildScrollView(
      child: Column(
        children: [
          (theme.isDark ? _renderLightMode(context) : _renderDarkMode(context)),
        ],
      ),
    );
  }

  Widget _renderThemeToggle(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return CircleAvatar(
      backgroundColor: theme.surface,
      child: IconButton(
          icon: Icon(theme.isDark ? Icons.dark_mode : Icons.light_mode),
          color: (theme.iconColor),
          onPressed: () {
            context.read<ThemeModel>().swapTheme();
          }),
    );
  }

  Widget _renderDarkMode(BuildContext context) {
    return Tooltip(
      message: LocaleKeys.tooltip_darkMode.tr(),
      child: _renderThemeToggle(context),
    );
  }

  Widget _renderLightMode(BuildContext context) {
    return Tooltip(
      message: LocaleKeys.tooltip_lightMode.tr(),
      child: _renderThemeToggle(context),
    );
  }
}
