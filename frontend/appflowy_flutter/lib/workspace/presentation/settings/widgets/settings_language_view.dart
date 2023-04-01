import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/appearance.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flowy_infra/language.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsLanguageView extends StatelessWidget {
  const SettingsLanguageView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FlowyText.medium(LocaleKeys.settings_menu_language.tr()),
              const LanguageSelectorDropdown(),
            ],
          ),
        ],
      ),
    );
  }
}

class LanguageSelectorDropdown extends StatefulWidget {
  const LanguageSelectorDropdown({
    Key? key,
  }) : super(key: key);

  @override
  State<LanguageSelectorDropdown> createState() =>
      _LanguageSelectorDropdownState();
}

class _LanguageSelectorDropdownState extends State<LanguageSelectorDropdown> {
  Color currHoverColor = Colors.white.withOpacity(0.0);
  void hoverExitLanguage() {
    setState(() {
      currHoverColor = Colors.white.withOpacity(0.0);
    });
  }

  void hoverEnterLanguage() {
    setState(() {
      currHoverColor = Theme.of(context).colorScheme.secondaryContainer;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => hoverEnterLanguage(),
      onExit: (_) => hoverExitLanguage(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: currHoverColor,
        ),
        child: DropdownButtonHideUnderline(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: DropdownButton<Locale>(
              value: context.locale,
              dropdownColor: Theme.of(context).cardColor,
              onChanged: (locale) {
                context
                    .read<AppearanceSettingsCubit>()
                    .setLocale(context, locale!);
              },
              autofocus: true,
              borderRadius: BorderRadius.circular(8),
              items:
                  EasyLocalization.of(context)!.supportedLocales.map((locale) {
                return DropdownMenuItem<Locale>(
                  value: locale,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: FlowyText.medium(
                      languageFromLocale(locale),
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
