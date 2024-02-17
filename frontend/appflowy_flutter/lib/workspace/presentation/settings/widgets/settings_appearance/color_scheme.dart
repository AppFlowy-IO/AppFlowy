import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_appearance/theme_setting_entry_template.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/theme_upload/theme_upload_view.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/plugins/bloc/dynamic_plugin_bloc.dart';
import 'package:flowy_infra/plugins/bloc/dynamic_plugin_event.dart';
import 'package:flowy_infra/plugins/bloc/dynamic_plugin_state.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/dialog/styled_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ColorSchemeSetting extends StatelessWidget {
  const ColorSchemeSetting({
    super.key,
    required this.currentTheme,
    required this.bloc,
  });

  final String currentTheme;
  final DynamicPluginBloc bloc;

  @override
  Widget build(BuildContext context) {
    return FlowySettingListTile(
      label: LocaleKeys.settings_appearance_theme.tr(),
      onResetRequested: context.read<AppearanceSettingsCubit>().resetTheme,
      trailing: [
        ColorSchemeUploadPopover(currentTheme: currentTheme, bloc: bloc),
        ColorSchemeUploadOverlayButton(bloc: bloc),
      ],
    );
  }
}

class ColorSchemeUploadOverlayButton extends StatelessWidget {
  const ColorSchemeUploadOverlayButton({super.key, required this.bloc});

  final DynamicPluginBloc bloc;

  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      width: 24,
      icon: FlowySvg(
        FlowySvgs.folder_m,
        size: const Size.square(16),
        color: Theme.of(context).iconTheme.color,
      ),
      iconColorOnHover: Theme.of(context).colorScheme.onPrimary,
      hoverColor: Theme.of(context).colorScheme.secondaryContainer,
      tooltipText: LocaleKeys.settings_appearance_themeUpload_uploadTheme.tr(),
      onPressed: () => Dialogs.show(
        context,
        child: BlocProvider<DynamicPluginBloc>.value(
          value: bloc,
          child: const FlowyDialog(
            constraints: BoxConstraints(maxHeight: 300),
            child: ThemeUploadWidget(),
          ),
        ),
      ).then((value) {
        if (value == null) return;
        showSnackBarMessage(
          context,
          LocaleKeys.settings_appearance_themeUpload_uploadSuccess.tr(),
        );
      }),
    );
  }
}

class ColorSchemeUploadPopover extends StatelessWidget {
  const ColorSchemeUploadPopover({
    super.key,
    required this.currentTheme,
    required this.bloc,
  });

  final String currentTheme;
  final DynamicPluginBloc bloc;

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      direction: PopoverDirection.bottomWithRightAligned,
      child: FlowyTextButton(
        currentTheme,
        fontColor: Theme.of(context).colorScheme.onBackground,
        fillColor: Colors.transparent,
        onPressed: () {},
      ),
      popupBuilder: (BuildContext context) {
        return IntrinsicWidth(
          child: BlocBuilder<DynamicPluginBloc, DynamicPluginState>(
            bloc: bloc..add(DynamicPluginEvent.load()),
            buildWhen: (previous, current) => current is Ready,
            builder: (context, state) {
              return state.maybeWhen(
                ready: (plugins) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...AppTheme.builtins.map(
                      (theme) => _themeItemButton(context, theme.themeName),
                    ),
                    if (plugins.isNotEmpty) ...[
                      const Divider(),
                      ...plugins
                          .map((plugin) => plugin.theme)
                          .whereType<AppTheme>()
                          .map(
                            (theme) => _themeItemButton(
                              context,
                              theme.themeName,
                              false,
                            ),
                          ),
                    ],
                  ],
                ),
                orElse: () => const SizedBox.shrink(),
              );
            },
          ),
        );
      },
    );
  }

  Widget _themeItemButton(
    BuildContext context,
    String theme, [
    bool isBuiltin = true,
  ]) {
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          Expanded(
            child: FlowyButton(
              text: FlowyText.medium(theme),
              rightIcon: currentTheme == theme
                  ? const FlowySvg(
                      FlowySvgs.check_s,
                    )
                  : null,
              onTap: () {
                if (currentTheme != theme) {
                  context.read<AppearanceSettingsCubit>().setTheme(theme);
                }
                PopoverContainer.of(context).close();
              },
            ),
          ),
          // when the custom theme is not the current theme, show the remove button
          if (!isBuiltin && currentTheme != theme)
            FlowyIconButton(
              icon: const FlowySvg(
                FlowySvgs.close_s,
              ),
              width: 20,
              onPressed: () =>
                  bloc.add(DynamicPluginEvent.removePlugin(name: theme)),
            ),
        ],
      ),
    );
  }
}
