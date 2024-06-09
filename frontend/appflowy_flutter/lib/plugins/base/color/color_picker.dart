import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class FlowyMobileColorPicker extends StatelessWidget {
  const FlowyMobileColorPicker({
    super.key,
    required this.onSelectedColor,
  });

  final void Function(FlowyColorOption? option) onSelectedColor;

  @override
  Widget build(BuildContext context) {
    const defaultColor = Colors.transparent;
    final colors = [
      // reset to default background color
      FlowyColorOption(
        color: defaultColor,
        i18n: LocaleKeys.document_plugins_optionAction_defaultColor.tr(),
        id: optionActionColorDefaultColor,
      ),
      ...FlowyTint.values.map(
        (e) => FlowyColorOption(
          color: e.color(context),
          i18n: e.tintName(AppFlowyEditorL10n.current),
          id: e.id,
        ),
      ),
    ];
    return ListView.separated(
      itemBuilder: (context, index) {
        final color = colors[index];
        return SizedBox(
          height: 56,
          child: FlowyButton(
            useIntrinsicWidth: true,
            text: FlowyText(
              color.i18n,
            ),
            leftIcon: _ColorIcon(
              color: color.color,
            ),
            leftIconSize: const Size.square(36.0),
            iconPadding: 12.0,
            margin: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 16.0,
            ),
            onTap: () => onSelectedColor(color),
          ),
        );
      },
      separatorBuilder: (_, __) => const Divider(
        height: 1,
      ),
      itemCount: colors.length,
    );
  }
}

class _ColorIcon extends StatelessWidget {
  const _ColorIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 24,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
