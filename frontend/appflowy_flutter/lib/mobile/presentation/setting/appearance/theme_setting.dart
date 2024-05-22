import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
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
          showDragHandle: true,
          showDivider: false,
          title: LocaleKeys.settings_appearance_themeMode_label.tr(),
          builder: (context) {
            final themeMode =
                context.read<AppearanceSettingsCubit>().state.themeMode;
            return Column(
              children: [
                FlowyOptionTile.checkbox(
                  text: LocaleKeys.settings_appearance_themeMode_system.tr(),
                  leftIcon: const FlowySvg(
                    FlowySvgs.m_theme_mode_system_s,
                  ),
                  isSelected: themeMode == ThemeMode.system,
                  onTap: () {
                    context
                        .read<AppearanceSettingsCubit>()
                        .setThemeMode(ThemeMode.system);
                    Navigator.pop(context);
                  },
                ),
                FlowyOptionTile.checkbox(
                  showTopBorder: false,
                  text: LocaleKeys.settings_appearance_themeMode_light.tr(),
                  leftIcon: const FlowySvg(
                    FlowySvgs.m_theme_mode_light_s,
                  ),
                  isSelected: themeMode == ThemeMode.light,
                  onTap: () {
                    context
                        .read<AppearanceSettingsCubit>()
                        .setThemeMode(ThemeMode.light);
                    Navigator.pop(context);
                  },
                ),
                FlowyOptionTile.checkbox(
                  showTopBorder: false,
                  text: LocaleKeys.settings_appearance_themeMode_dark.tr(),
                  leftIcon: const FlowySvg(
                    FlowySvgs.m_theme_mode_dark_s,
                  ),
                  isSelected: themeMode == ThemeMode.dark,
                  onTap: () {
                    context
                        .read<AppearanceSettingsCubit>()
                        .setThemeMode(ThemeMode.dark);
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
