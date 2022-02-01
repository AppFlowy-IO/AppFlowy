import 'package:app_flowy/workspace/application/appearance.dart';
import 'package:flutter/foundation.dart';
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
    return DropdownButton<AppLanguage>(
      value: fullStringFromLanguage(context.read<AppearanceSettingModel>().language),
      onChanged: (val) {
        setState(() {
          context.read<AppearanceSettingModel>().setLanguage(context, languageFromFullString(val!));
        });
      },
      autofocus: true,
      items: AppLanguage.values.map((language) {
        return DropdownMenuItem<AppLanguage>(
          value: fullStringFromLanguage(language),
          child: Text(describeEnum(language)),
        );
      }).toList(),
    );
  }
}
