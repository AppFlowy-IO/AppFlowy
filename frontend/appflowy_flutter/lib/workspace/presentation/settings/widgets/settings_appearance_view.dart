import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/appearance.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/theme_upload/theme_upload_view.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/plugins/bloc/dynamic_plugin_bloc.dart';
import 'package:flowy_infra/plugins/bloc/dynamic_plugin_state.dart';
import 'package:flowy_infra/plugins/service/models/flowy_dynamic_plugin.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'theme_upload/theme_preview.dart';
import 'utils/form_factor.dart';

class SettingsAppearanceView extends StatelessWidget {
  const SettingsAppearanceView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: BlocProvider<DynamicPluginBloc>(
        create: (_) => DynamicPluginBloc(),
        child: BlocBuilder<AppearanceSettingsCubit, AppearanceSettingsState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ThemeModeSetting(currentThemeMode: state.themeMode),
                const ThemeUploadWidget(),
                const SizedBox(height: ThemeSetting.mainAxisSpacing),
                ThemeSetting(currentTheme: state.appTheme.themeName),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ThemeSetting extends StatefulWidget {
  const ThemeSetting({
    super.key,
    required this.currentTheme,
  });

  final String currentTheme;
  static const double crossAxisSpacing = 16;
  static const double mainAxisSpacing = 16;

  @override
  State<ThemeSetting> createState() => _ThemeSettingState();
}

class _ThemeSettingState extends State<ThemeSetting> {
  int get crossAxisCount {
    final factor = FormFactor.fromWidth(MediaQuery.of(context).size.width);
    return switch (factor) {
      FormFactor.mobile => 1,
      FormFactor.tablet => 2,
      FormFactor.desktop => 3,
    };
  }

  Widget get uninitialized => const SizedBox.shrink();
  Widget get processing => const SizedBox.shrink();
  Widget get compilationFailure => const SizedBox.shrink();
  Widget get deletionFailure => const SizedBox.shrink();
  Widget get deletionSuccess => const SizedBox.shrink();
  Widget get compilationSuccess => const SizedBox.shrink();
  Widget ready(Iterable<FlowyDynamicPlugin> plugins) {
    final themes = [
      ...AppTheme.builtins,
      ...plugins.map((plugin) => plugin.theme).whereType<AppTheme>(),
    ];
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: ThemeSetting.crossAxisSpacing,
        mainAxisSpacing: ThemeSetting.mainAxisSpacing,
      ),
      itemCount: themes.length,
      itemBuilder: (context, index) {
        final theme = themes.elementAt(index);
        return ThemePreview(
          // TODO(a-wallen): bad there could be multiple themes
          theme: theme,
          isCurrentTheme: theme.themeName == widget.currentTheme,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<DynamicPluginBloc, DynamicPluginState>(
          buildWhen: (previous, current) => current is Ready,
          builder: (context, state) {
            return state.when(
              uninitialized: () => uninitialized,
              processing: () => processing,
              compilationFailure: (message) => compilationFailure,
              deletionFailure: (message) => deletionFailure,
              deletionSuccess: () => deletionSuccess,
              compilationSuccess: () => compilationSuccess,
              ready: (plugins) => ready(plugins),
            );
          },
        ),
      ],
    );
  }

  Widget _themeItemButton(BuildContext context, String theme) {
    return SizedBox(
      height: 32,
      child: FlowyButton(
        text: FlowyText.medium(theme),
        rightIcon: widget.currentTheme == theme
            ? const FlowySvg(name: 'grid/checkmark')
            : null,
        onTap: () {
          if (widget.currentTheme != theme) {
            context.read<AppearanceSettingsCubit>().setTheme(theme);
          }
        },
      ),
    );
  }
}

class ThemeModeSetting extends StatelessWidget {
  final ThemeMode currentThemeMode;
  const ThemeModeSetting({required this.currentThemeMode, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FlowyText.medium(
            LocaleKeys.settings_appearance_themeMode_label.tr(),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppFlowyPopover(
          direction: PopoverDirection.bottomWithRightAligned,
          child: FlowyTextButton(
            _themeModeLabelText(currentThemeMode),
            fontColor: Theme.of(context).colorScheme.onBackground,
            fillColor: Colors.transparent,
            onPressed: () {},
          ),
          popupBuilder: (BuildContext context) {
            return IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _themeModeItemButton(context, ThemeMode.light),
                  _themeModeItemButton(context, ThemeMode.dark),
                  _themeModeItemButton(context, ThemeMode.system),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _themeModeItemButton(BuildContext context, ThemeMode themeMode) {
    return SizedBox(
      height: 32,
      child: FlowyButton(
        text: FlowyText.medium(_themeModeLabelText(themeMode)),
        rightIcon: currentThemeMode == themeMode
            ? const FlowySvg(name: 'grid/checkmark')
            : null,
        onTap: () {
          if (currentThemeMode != themeMode) {
            context.read<AppearanceSettingsCubit>().setThemeMode(themeMode);
          }
        },
      ),
    );
  }

  String _themeModeLabelText(ThemeMode themeMode) {
    switch (themeMode) {
      case (ThemeMode.light):
        return LocaleKeys.settings_appearance_themeMode_light.tr();
      case (ThemeMode.dark):
        return LocaleKeys.settings_appearance_themeMode_dark.tr();
      case (ThemeMode.system):
        return LocaleKeys.settings_appearance_themeMode_system.tr();
      default:
        return "";
    }
  }
}
