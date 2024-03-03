import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/setting/language/language_picker_screen.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/language.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'setting.dart';

class LanguageSettingGroup extends StatefulWidget {
  const LanguageSettingGroup({
    super.key,
  });

  @override
  State<LanguageSettingGroup> createState() => _LanguageSettingGroupState();
}

class _LanguageSettingGroupState extends State<LanguageSettingGroup> {
  @override
  Widget build(BuildContext context) {
    return BlocSelector<AppearanceSettingsCubit, AppearanceSettingsState,
        Locale>(
      selector: (state) {
        return state.locale;
      },
      builder: (context, locale) {
        final theme = Theme.of(context);
        return MobileSettingGroup(
          groupTitle: LocaleKeys.settings_menu_language.tr(),
          settingItemList: [
            MobileSettingItem(
              name: LocaleKeys.settings_menu_language.tr(),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FlowyText(
                    languageFromLocale(locale),
                    color: theme.colorScheme.onSurface,
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () async {
                final newLocale =
                    await context.push<Locale>(LanguagePickerScreen.routeName);
                if (newLocale != null && newLocale != locale) {
                  if (context.mounted) {
                    context
                        .read<AppearanceSettingsCubit>()
                        .setLocale(context, newLocale);
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}
