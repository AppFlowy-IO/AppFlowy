import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SimpleTableBackgroundColorMenu extends StatefulWidget {
  const SimpleTableBackgroundColorMenu({
    super.key,
    required this.type,
    required this.tableCellNode,
    this.mutex,
  });

  final SimpleTableMoreActionType type;
  final Node tableCellNode;
  final PopoverMutex? mutex;

  @override
  State<SimpleTableBackgroundColorMenu> createState() =>
      _SimpleTableBackgroundColorMenuState();
}

class _SimpleTableBackgroundColorMenuState
    extends State<SimpleTableBackgroundColorMenu> {
  @override
  Widget build(BuildContext context) {
    final theme = AFThemeExtension.of(context);
    final backgroundColor = switch (widget.type) {
      SimpleTableMoreActionType.row =>
        widget.tableCellNode.buildRowColor(context),
      SimpleTableMoreActionType.column =>
        widget.tableCellNode.buildColumnColor(context),
    };
    return AppFlowyPopover(
      mutex: widget.mutex,
      popupBuilder: (popoverContext) {
        return _buildColorOptionMenu(
          context,
          theme: theme,
          onClose: () => PopoverContainer.of(popoverContext).closeAll(),
        );
      },
      direction: PopoverDirection.rightWithCenterAligned,
      child: SimpleTableBasicButton(
        leftIconBuilder: (onHover) => ColorOptionIcon(
          color: backgroundColor ?? Colors.transparent,
        ),
        text: LocaleKeys.document_plugins_simpleTable_moreActions_color.tr(),
        onTap: () {},
      ),
    );
  }

  Widget _buildColorOptionMenu(
    BuildContext context, {
    required AFThemeExtension theme,
    required VoidCallback onClose,
  }) {
    final colors = [
      // reset to default background color
      FlowyColorOption(
        color: Colors.transparent,
        i18n: LocaleKeys.document_plugins_optionAction_defaultColor.tr(),
        id: optionActionColorDefaultColor,
      ),
      ...FlowyTint.values.map(
        (e) => FlowyColorOption(
          color: e.color(context, theme: theme),
          i18n: e.tintName(AppFlowyEditorL10n.current),
          id: e.id,
        ),
      ),
    ];

    return FlowyColorPicker(
      colors: colors,
      border: Border.all(
        color: theme.onBackground,
      ),
      onTap: (option, index) {
        switch (widget.type) {
          case SimpleTableMoreActionType.column:
            context.read<EditorState>().updateColumnBackgroundColor(
                  tableCellNode: widget.tableCellNode,
                  color: option.id,
                );
            break;
          case SimpleTableMoreActionType.row:
            context.read<EditorState>().updateRowBackgroundColor(
                  tableCellNode: widget.tableCellNode,
                  color: option.id,
                );
            break;
        }

        onClose();
      },
    );
  }
}
