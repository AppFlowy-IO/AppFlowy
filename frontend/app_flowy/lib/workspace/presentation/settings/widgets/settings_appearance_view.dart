import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/workspace/application/appearance.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsAppearanceView extends StatelessWidget {
  const SettingsAppearanceView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 500,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: ThemeType.values.length,
              itemBuilder: (context, index) {
                final itemAppTheme = ThemeType.values[index];
                return Card(
                  color: getCardColor(itemAppTheme),
                  child: ListTile(
                    title: Text(
                      getThemeName(itemAppTheme),
                    ),
                    onTap: () {
                      setTheme(context, itemAppTheme);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String getThemeName(ThemeType ty) {
    switch (ty) {
      case ThemeType.light:
        return LocaleKeys.settings_appearance_lightLabel.tr();
      case ThemeType.dark:
        return LocaleKeys.settings_appearance_darkLabel.tr();
      case ThemeType.anne:
        return "Anne Mode";
      default:
        return "Try Me";
    }
  }

  void setTheme(BuildContext context, ThemeType ty) {
    context.read<AppearanceSettingsCubit>().setTheme(ty);
  }
}
