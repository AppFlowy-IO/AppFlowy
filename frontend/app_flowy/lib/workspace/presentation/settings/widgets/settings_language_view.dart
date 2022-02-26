import 'package:app_flowy/workspace/application/appearance.dart';
import 'package:easy_localization/easy_localization.dart';
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
        children: const [LanguageSelectorDropdown()],
      ),
    );
  }
}

class LanguageSelectorDropdown extends StatefulWidget {
  const LanguageSelectorDropdown({
    Key? key,
  }) : super(key: key);

  @override
  State<LanguageSelectorDropdown> createState() => _LanguageSelectorDropdownState();
}

class _LanguageSelectorDropdownState extends State<LanguageSelectorDropdown> {
  @override
  Widget build(BuildContext context) {
    return DropdownButton<Locale>(
      value: context.read<AppearanceSettingModel>().locale,
      onChanged: (val) {
        setState(() {
          context.read<AppearanceSettingModel>().setLocale(context, val!);
        });
      },
      autofocus: true,
      items: EasyLocalization.of(context)!.supportedLocales.map((locale) {
        return DropdownMenuItem<Locale>(
          value: locale,
          child: Text(languageFromLocale(locale)),
        );
      }).toList(),
    );
  }
}
