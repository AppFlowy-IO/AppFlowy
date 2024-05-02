import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/appearance_defaults.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_header.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_appearance/create_file_setting.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_appearance/date_format_setting.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_appearance/time_format_setting.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/plugins/bloc/dynamic_plugin_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'settings_appearance/settings_appearance.dart';

class SettingsAppearanceView extends StatelessWidget {
  const SettingsAppearanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DynamicPluginBloc>(
      create: (_) => DynamicPluginBloc(),
      child: BlocBuilder<AppearanceSettingsCubit, AppearanceSettingsState>(
        builder: (context, state) {
          return SettingsBody(
            children: [
              SettingsHeader(title: LocaleKeys.settings_menu_appearance.tr()),
              ColorSchemeSetting(
                currentTheme: state.appTheme.themeName,
                bloc: context.read<DynamicPluginBloc>(),
              ),
              BrightnessSetting(
                currentThemeMode: state.themeMode,
              ),
              const Divider(),
              ThemeFontFamilySetting(
                currentFontFamily: state.font,
              ),
              const Divider(),
              DocumentCursorColorSetting(
                currentCursorColor: state.documentCursorColor ??
                    DefaultAppearanceSettings.getDefaultDocumentCursorColor(
                      context,
                    ),
              ),
              DocumentSelectionColorSetting(
                currentSelectionColor: state.documentSelectionColor ??
                    DefaultAppearanceSettings.getDefaultDocumentSelectionColor(
                      context,
                    ),
              ),
              const Divider(),
              LayoutDirectionSetting(
                currentLayoutDirection: state.layoutDirection,
              ),
              TextDirectionSetting(
                currentTextDirection: state.textDirection,
              ),
              const EnableRTLToolbarItemsSetting(),
              const Divider(),
              DateFormatSetting(
                currentFormat: state.dateFormat,
              ),
              TimeFormatSetting(
                currentFormat: state.timeFormat,
              ),
              const Divider(),
              CreateFileSettings(),
            ],
          );
        },
      ),
    );
  }
}
