import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SimpleTableRowDivider extends StatelessWidget {
  const SimpleTableRowDivider({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return VerticalDivider(
      color: context.simpleTableBorderColor,
      width: 1.0,
    );
  }
}

class SimpleTableColumnDivider extends StatelessWidget {
  const SimpleTableColumnDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: context.simpleTableBorderColor,
      height: 1.0,
    );
  }
}

class SimpleTableAlignMenu extends StatefulWidget {
  const SimpleTableAlignMenu({
    super.key,
    required this.type,
    required this.tableCellNode,
    this.mutex,
  });

  final SimpleTableMoreActionType type;
  final Node tableCellNode;
  final PopoverMutex? mutex;

  @override
  State<SimpleTableAlignMenu> createState() => _SimpleTableAlignMenuState();
}

class _SimpleTableAlignMenuState extends State<SimpleTableAlignMenu> {
  @override
  Widget build(BuildContext context) {
    final align = switch (widget.type) {
      SimpleTableMoreActionType.column => widget.tableCellNode.columnAlign,
      SimpleTableMoreActionType.row => widget.tableCellNode.rowAlign,
    };
    return AppFlowyPopover(
      mutex: widget.mutex,
      child: SimpleTableBasicButton(
        leftIconSvg: align.leftIconSvg,
        text: LocaleKeys.document_plugins_simpleTable_moreActions_align.tr(),
        onTap: () {},
      ),
      popupBuilder: (popoverContext) {
        void onClose() => PopoverContainer.of(popoverContext).closeAll();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAlignButton(context, TableAlign.left, onClose),
            _buildAlignButton(context, TableAlign.center, onClose),
            _buildAlignButton(context, TableAlign.right, onClose),
          ],
        );
      },
    );
  }

  Widget _buildAlignButton(
    BuildContext context,
    TableAlign align,
    VoidCallback onClose,
  ) {
    return SimpleTableBasicButton(
      leftIconSvg: align.leftIconSvg,
      text: align.name,
      onTap: () {
        switch (widget.type) {
          case SimpleTableMoreActionType.column:
            context.read<EditorState>().updateColumnAlign(
                  tableCellNode: widget.tableCellNode,
                  align: align,
                );
            break;
          case SimpleTableMoreActionType.row:
            context.read<EditorState>().updateRowAlign(
                  tableCellNode: widget.tableCellNode,
                  align: align,
                );
            break;
        }

        onClose();
      },
    );
  }
}

class SimpleTableBasicButton extends StatelessWidget {
  const SimpleTableBasicButton({
    super.key,
    required this.text,
    required this.onTap,
    this.leftIconSvg,
    this.leftIconBuilder,
    this.rightIcon,
  });

  final FlowySvgData? leftIconSvg;
  final String text;
  final VoidCallback onTap;
  final Widget Function(bool onHover)? leftIconBuilder;
  final Widget? rightIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SimpleTableConstants.moreActionHeight,
      padding: SimpleTableConstants.moreActionPadding,
      child: FlowyIconTextButton(
        margin: SimpleTableConstants.moreActionHorizontalMargin,
        leftIconBuilder: _buildLeftIcon,
        iconPadding: 10.0,
        textBuilder: (onHover) => FlowyText.regular(
          text,
          fontSize: 14.0,
          figmaLineHeight: 18.0,
        ),
        onTap: onTap,
        rightIconBuilder: (onHover) => rightIcon ?? const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildLeftIcon(bool onHover) {
    if (leftIconBuilder != null) {
      return leftIconBuilder!(onHover);
    }
    return leftIconSvg != null
        ? FlowySvg(leftIconSvg!)
        : const SizedBox.shrink();
  }
}

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
