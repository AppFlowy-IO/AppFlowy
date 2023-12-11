import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/util/theme_mode_extension.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../setting.dart';

class ThemeSetting extends StatelessWidget {
  const ThemeSetting({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = context.watch<AppearanceSettingsCubit>().state.themeMode;
    return MobileSettingItem(
      name: LocaleKeys.settings_appearance_themeMode_label.tr(),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FlowyText(
            themeMode.labelText,
            color: theme.colorScheme.onSurface,
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () {
        showMobileBottomSheet(
          context,
          showHeader: true,
          showCloseButton: true,
          showDragHandle: true,
          title: LocaleKeys.settings_appearance_themeMode_label.tr(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          builder: (_) {
            return Column(
              children: [
                _ThemeModeRadioListTile(
                  title: LocaleKeys.settings_appearance_themeMode_system.tr(),
                  value: ThemeMode.system,
                ),
                _ThemeModeRadioListTile(
                  title: LocaleKeys.settings_appearance_themeMode_light.tr(),
                  value: ThemeMode.light,
                ),
                _ThemeModeRadioListTile(
                  title: LocaleKeys.settings_appearance_themeMode_dark.tr(),
                  value: ThemeMode.dark,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ThemeModeRadioListTile extends StatelessWidget {
  const _ThemeModeRadioListTile({
    required this.title,
    required this.value,
  });
  final String title;
  final ThemeMode value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RadioListTile<ThemeMode>(
      dense: true,
      contentPadding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
      controlAffinity: ListTileControlAffinity.trailing,
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      groupValue: context.read<AppearanceSettingsCubit>().state.themeMode,
      value: value,
      onChanged: (selectedThemeMode) {
        if (selectedThemeMode == null) return;
        context.read<AppearanceSettingsCubit>().setThemeMode(selectedThemeMode);
      },
    );
  }
}
