import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/widgets/show_flowy_mobile_bottom_sheet.dart';
import 'package:appflowy/util/theme_mode_extension.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'setting.dart';

class AppearanceSettingGroup extends StatefulWidget {
  const AppearanceSettingGroup({
    super.key,
  });

  @override
  State<AppearanceSettingGroup> createState() => _AppearanceSettingGroupState();
}

class _AppearanceSettingGroupState extends State<AppearanceSettingGroup> {
  @override
  Widget build(BuildContext context) {
    return BlocSelector<AppearanceSettingsCubit, AppearanceSettingsState,
        ThemeMode>(
      selector: (state) {
        return state.themeMode;
      },
      builder: (context, themeMode) {
        final theme = Theme.of(context);
        return MobileSettingGroup(
          groupTitle: LocaleKeys.settings_menu_appearance.tr(),
          settingItemList: [
            MobileSettingItem(
              name: LocaleKeys.settings_appearance_themeMode_label.tr(),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    themeMode.labelText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () {
                showFlowyMobileBottomSheet(
                  context,
                  title: LocaleKeys.settings_appearance_themeMode_label.tr(),
                  builder: (_) {
                    return Column(
                      children: [
                        _ThemeModeRadioListTile(
                          title: LocaleKeys.settings_appearance_themeMode_system
                              .tr(),
                          value: ThemeMode.system,
                        ),
                        _ThemeModeRadioListTile(
                          title: LocaleKeys.settings_appearance_themeMode_light
                              .tr(),
                          value: ThemeMode.light,
                        ),
                        _ThemeModeRadioListTile(
                          title: LocaleKeys.settings_appearance_themeMode_dark
                              .tr(),
                          value: ThemeMode.dark,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
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
