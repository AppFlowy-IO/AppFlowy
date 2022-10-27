import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/workspace/application/appearance.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flowy_infra/language.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:textstyle_extensions/textstyle_extensions.dart';

class SettingsLanguageView extends StatelessWidget {
  const SettingsLanguageView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    context.watch<AppearanceSettingsCubit>().state.theme;
    return BlocBuilder<AppearanceSettingsCubit, AppearanceSettingsState>(
      builder: (context, state) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  LocaleKeys.settings_menu_language.tr(),
                  style: TextStyles.body1.size(FontSizes.s14),
                ),
                const LanguageSelectorDropdown(),
              ],
            ),
          ],
        ),
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
  late Color themedHoverColor;
  void hoverExitLanguage() {
    setState(() {
      currHoverColor = Colors.white.withOpacity(0.0);
    });
  }

  void hoverEnterLanguage() {
    setState(() {
      currHoverColor = themedHoverColor;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppearanceSettingsCubit>().state.theme;
    themedHoverColor = theme.main2;
    return MouseRegion(
      onEnter: (event) => {hoverEnterLanguage()},
      onExit: (event) => {hoverExitLanguage()},
      child: Container(
        margin: const EdgeInsets.only(left: 8, right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: currHoverColor,
        ),
        child: DropdownButtonHideUnderline(
          child: BlocBuilder<AppearanceSettingsCubit, AppearanceSettingsState>(
            builder: (context, state) => DropdownButton<Locale>(
              value: state.locale,
              onChanged: (val) {
                setState(() {
                  context
                      .read<AppearanceSettingsCubit>()
                      .setLocale(context, val!);
                });
              },
              icon: const Visibility(
                visible: false,
                child: (Icon(Icons.arrow_downward)),
              ),
              borderRadius: BorderRadius.circular(8),
              items:
                  EasyLocalization.of(context)!.supportedLocales.map((locale) {
                return DropdownMenuItem<Locale>(
                  value: locale,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      languageFromLocale(locale),
                      style: TextStyles.body1.size(FontSizes.s14),
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
