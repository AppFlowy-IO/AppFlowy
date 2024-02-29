import 'package:appflowy/workspace/application/appearance_defaults.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_appearance/create_file_setting.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_appearance/date_format_setting.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_appearance/time_format_setting.dart';
import 'package:flowy_infra/plugins/bloc/dynamic_plugin_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'settings_appearance/settings_appearance.dart';

class SettingsAppearanceView extends StatelessWidget {
  const SettingsAppearanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: BlocProvider<DynamicPluginBloc>(
        create: (_) => DynamicPluginBloc(),
        child: BlocBuilder<AppearanceSettingsCubit, AppearanceSettingsState>(
          builder: (context, state) {
            return Column(
              children: [
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
                      DefaultAppearanceSettings
                          .getDefaultDocumentSelectionColor(
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
      ),
    );
  }
}
