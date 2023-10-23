import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/widgets/mobile_bottom_sheet_title.dart';
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
    final theme = Theme.of(context);

    return BlocSelector<AppearanceSettingsCubit, AppearanceSettingsState,
        ThemeMode>(
      selector: (state) {
        return state.themeMode;
      },
      builder: (context, themeMode) {
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
                  const Icon(Icons.chevron_right)
                ],
              ),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) {
                    final currentThemeMode =
                        context.read<AppearanceSettingsCubit>().state.themeMode;
                    final theme = Theme.of(context);
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          MobileBottomSheetTitle(
                            LocaleKeys.settings_appearance_themeMode_label.tr(),
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          RadioListTile<ThemeMode>(
                            controlAffinity: ListTileControlAffinity.trailing,
                            title: Text(
                              LocaleKeys.settings_appearance_themeMode_system
                                  .tr(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            groupValue: currentThemeMode,
                            value: ThemeMode.system,
                            onChanged: (selectedThemeMode) {
                              if (selectedThemeMode == null) return;
                              context
                                  .read<AppearanceSettingsCubit>()
                                  .setThemeMode(selectedThemeMode);
                            },
                          ),
                          RadioListTile<ThemeMode>(
                            controlAffinity: ListTileControlAffinity.trailing,
                            title: Text(
                              LocaleKeys.settings_appearance_themeMode_light
                                  .tr(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            groupValue: currentThemeMode,
                            value: ThemeMode.light,
                            onChanged: (selectedThemeMode) {
                              if (selectedThemeMode == null) return;

                              context
                                  .read<AppearanceSettingsCubit>()
                                  .setThemeMode(selectedThemeMode);
                            },
                          ),
                          RadioListTile<ThemeMode>(
                            controlAffinity: ListTileControlAffinity.trailing,
                            title: Text(
                              LocaleKeys.settings_appearance_themeMode_dark
                                  .tr(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            groupValue: currentThemeMode,
                            value: ThemeMode.dark,
                            onChanged: (selectedThemeMode) {
                              if (selectedThemeMode == null) return;
                              context
                                  .read<AppearanceSettingsCubit>()
                                  .setThemeMode(selectedThemeMode);
                            },
                          ),
                        ],
                      ),
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
