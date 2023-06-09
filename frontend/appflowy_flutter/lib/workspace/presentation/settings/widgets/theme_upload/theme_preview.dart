import 'package:flowy_infra/colorscheme/colorscheme.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/plugins/bloc/dynamic_plugin_bloc.dart';
import 'package:flowy_infra/plugins/bloc/dynamic_plugin_event.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../application/appearance.dart';
import 'theme_confirm_delete_dialog.dart';

class ThemePreview extends StatelessWidget {
  const ThemePreview({
    super.key,
    required this.theme,
    required this.isCurrentTheme,
  });

  static final BoxDecoration fallbackDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(8),
  );

  final AppTheme theme;
  final bool isCurrentTheme;

  Color get checkboxButtonFillColor =>
      isCurrentTheme ? theme.lightTheme.primary : Colors.transparent;

  void setTheme(BuildContext context) =>
      context.read<AppearanceSettingsCubit>().setTheme(
            theme.themeName,
          );

  void removeTheme(BuildContext context) =>
      context.read<DynamicPluginBloc>().add(
            DynamicPluginEvent.removePlugin(name: theme.themeName),
          );

  void onConfirmationDialogResult(bool? result, BuildContext context) {
    if (result == null || false) {
      return;
    }
    context.read<DynamicPluginBloc>().add(
          DynamicPluginEvent.removePlugin(name: theme.themeName),
        );
  }

  @override
  Widget build(BuildContext context) {
    final FlowyColorScheme scheme =
        Theme.of(context).brightness == Brightness.light
            ? theme.lightTheme
            : theme.darkTheme;
    return GestureDetector(
      onTap: isCurrentTheme ? null : () => setTheme(context),
      child: Container(
        height: 80,
        width: 80,
        decoration: fallbackDecoration.copyWith(
          color: isCurrentTheme
              ? scheme.primary
              : Theme.of(context).colorScheme.background,
          border: Border.all(
            color: scheme.divider,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                FlowyText.regular(
                  theme.themeName,
                  color: isCurrentTheme
                      ? Theme.of(context).colorScheme.onPrimary
                      : null,
                ),
                const Spacer(),
                if (!theme.builtIn) ...[
                  FlowyIconButton(
                    icon: const FlowySvg(
                      name: 'home/trash',
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return ThemeConfirmDeleteDialog(
                            theme: theme,
                          );
                        },
                      ).then(
                        (value) => onConfirmationDialogResult(value, context),
                      );
                    },
                    height: 20,
                    width: 20,
                    iconPadding: const EdgeInsets.all(1),
                    fillColor: Colors.transparent,
                    hoverColor: Theme.of(context).colorScheme.primary,
                    iconColorOnHover: Theme.of(context).colorScheme.onPrimary,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                    border: Border.all(
                  width: 1,
                  color: scheme.divider,
                )),
                child: Row(
                  children: [
                    Flexible(
                      flex: 1,
                      child: Container(
                        color: scheme.sidebarBg,
                      ),
                    ),
                    VerticalDivider(width: 1, color: scheme.divider),
                    Flexible(
                      flex: 2,
                      child: Column(
                        children: [
                          Container(
                            height: 10,
                            color: scheme.topbarBg,
                          ),
                          Divider(height: 1, color: scheme.divider),
                          Expanded(
                            child: Container(
                              color: scheme.surface,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
