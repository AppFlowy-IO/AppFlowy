import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../common/theme/theme.dart';
import '../../../application/appearance.dart';

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
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              BlocSelector<AppearanceSettingsCubit, AppearanceSettingsState, FlowyTheme>(
                selector: (state) => state.theme,
                builder: (context, state) => Switch(
                  value: state.isDark,
                  onChanged: (_) => context.read<AppearanceSettingsCubit>().swapTheme(),
                ),
              ),
              Text(
                LocaleKeys.settings_appearance_darkLabel.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
