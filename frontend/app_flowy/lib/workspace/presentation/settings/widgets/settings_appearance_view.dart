import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/workspace/application/appearance.dart';
import 'package:app_flowy/workspace/presentation/widgets/toggle/toggle_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:textstyle_extensions/textstyle_extensions.dart';

import '../../widgets/toggle/toggle.dart';

class SettingsAppearanceView extends StatelessWidget {
  const SettingsAppearanceView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                LocaleKeys.settings_appearance_lightLabel.tr(),
                style: TextStyles.body1.size(FontSizes.s14),
              ),
              Toggle(
                value: Theme.of(context).brightness == Brightness.dark,
                onChanged: (_) => setTheme(context),
                style: ToggleStyle.big,
              ),
              Text(
                LocaleKeys.settings_appearance_darkLabel.tr(),
                style: TextStyles.body1.size(FontSizes.s14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void setTheme(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      context.read<AppearanceSettingsCubit>().setTheme(Brightness.light);
    } else {
      context.read<AppearanceSettingsCubit>().setTheme(Brightness.dark);
    }
  }
}
