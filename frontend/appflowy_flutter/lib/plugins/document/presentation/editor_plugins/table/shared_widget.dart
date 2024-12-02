import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_constants.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_more_action.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/table_operations/table_operations.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SimpleTableReorderButton extends StatelessWidget {
  const SimpleTableReorderButton({
    super.key,
    required this.isShowingMenu,
    required this.type,
  });

  final ValueNotifier<bool> isShowingMenu;
  final SimpleTableMoreActionType type;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isShowingMenu,
      builder: (context, isShowingMenu, child) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            decoration: BoxDecoration(
              color: isShowingMenu
                  ? context.simpleTableMoreActionHoverColor
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: context.simpleTableMoreActionBorderColor,
              ),
            ),
            height: 16.0,
            width: 16.0,
            child: FlowySvg(
              type.reorderIconSvg,
              color: isShowingMenu ? Colors.white : null,
              size: const Size.square(16.0),
            ),
          ),
        );
      },
    );
  }
}

class SimpleTableAddRowHoverButton extends StatelessWidget {
  const SimpleTableAddRowHoverButton({
    super.key,
    required this.editorState,
    required this.node,
  });

  final EditorState editorState;
  final Node node;

  @override
  Widget build(BuildContext context) {
    assert(node.type == SimpleTableBlockKeys.type);

    if (node.type != SimpleTableBlockKeys.type) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder(
      valueListenable: context.read<SimpleTableContext>().hoveringTableCell,
      builder: (context, tableCell, child) {
        if (tableCell == null) {
          return const SizedBox.shrink();
        }
        final showRowButton = tableCell.rowIndex + 1 == tableCell.rowLength;
        return showRowButton
            ? Positioned(
                bottom: 0,
                left: SimpleTableConstants.tableLeftPadding -
                    SimpleTableConstants.cellBorderWidth,
                right: SimpleTableConstants.addRowButtonRightPadding,
                child: SimpleTableAddRowButton(
                  onTap: () => editorState.addRowInTable(node),
                ),
              )
            : const SizedBox.shrink();
      },
    );
  }
}

class SimpleTableAddRowButton extends StatelessWidget {
  const SimpleTableAddRowButton({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FlowyTooltip(
      message: LocaleKeys.document_plugins_simpleTable_clickToAddNewRow.tr(),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            height: SimpleTableConstants.addRowButtonHeight,
            margin: const EdgeInsets.symmetric(
              vertical: SimpleTableConstants.addRowButtonPadding,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                SimpleTableConstants.addRowButtonRadius,
              ),
              color: context.simpleTableMoreActionBackgroundColor,
            ),
            child: const FlowySvg(
              FlowySvgs.add_s,
            ),
          ),
        ),
      ),
    );
  }
}

class SimpleTableAddColumnHoverButton extends StatelessWidget {
  const SimpleTableAddColumnHoverButton({
    super.key,
    required this.editorState,
    required this.node,
  });

  final EditorState editorState;
  final Node node;

  @override
  Widget build(BuildContext context) {
    assert(node.type == SimpleTableBlockKeys.type);

    if (node.type != SimpleTableBlockKeys.type) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder(
      valueListenable: context.read<SimpleTableContext>().hoveringTableCell,
      builder: (context, tableCell, child) {
        if (tableCell == null) {
          return const SizedBox.shrink();
        }
        final showColumnButton =
            tableCell.columnIndex + 1 == tableCell.columnLength;
        return showColumnButton
            ? Positioned(
                top: SimpleTableConstants.tableTopPadding -
                    SimpleTableConstants.cellBorderWidth,
                bottom: SimpleTableConstants.addColumnButtonBottomPadding,
                right: 0,
                child: SimpleTableAddColumnButton(
                  onTap: () {
                    editorState.addColumnInTable(node);
                  },
                ),
              )
            : const SizedBox.shrink();
      },
    );
  }
}

class SimpleTableAddColumnButton extends StatelessWidget {
  const SimpleTableAddColumnButton({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FlowyTooltip(
      message: LocaleKeys.document_plugins_simpleTable_clickToAddNewColumn.tr(),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: SimpleTableConstants.addColumnButtonWidth,
            margin: const EdgeInsets.symmetric(
              horizontal: SimpleTableConstants.addColumnButtonPadding,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                SimpleTableConstants.addColumnButtonRadius,
              ),
              color: context.simpleTableMoreActionBackgroundColor,
            ),
            child: const FlowySvg(
              FlowySvgs.add_s,
            ),
          ),
        ),
      ),
    );
  }
}

class SimpleTableAddColumnAndRowHoverButton extends StatelessWidget {
  const SimpleTableAddColumnAndRowHoverButton({
    super.key,
    required this.editorState,
    required this.node,
  });

  final EditorState editorState;
  final Node node;

  @override
  Widget build(BuildContext context) {
    assert(node.type == SimpleTableBlockKeys.type);

    if (node.type != SimpleTableBlockKeys.type) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder(
      valueListenable: context.read<SimpleTableContext>().hoveringTableCell,
      builder: (context, tableCell, child) {
        if (tableCell == null) {
          return const SizedBox.shrink();
        }
        final showAddColumnAndRowButton =
            tableCell.rowIndex + 1 == tableCell.rowLength ||
                tableCell.columnIndex + 1 == tableCell.columnLength;
        return showAddColumnAndRowButton
            ? Positioned(
                bottom: SimpleTableConstants.addRowButtonPadding,
                right: SimpleTableConstants.addColumnButtonPadding,
                child: SimpleTableAddColumnAndRowButton(
                  onTap: () => editorState.addColumnAndRowInTable(node),
                ),
              )
            : const SizedBox.shrink();
      },
    );
  }
}

class SimpleTableAddColumnAndRowButton extends StatelessWidget {
  const SimpleTableAddColumnAndRowButton({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FlowyTooltip(
      message: LocaleKeys.document_plugins_simpleTable_clickToAddNewRowAndColumn
          .tr(),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: SimpleTableConstants.addColumnAndRowButtonWidth,
            height: SimpleTableConstants.addColumnAndRowButtonHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                SimpleTableConstants.addColumnAndRowButtonCornerRadius,
              ),
              color: context.simpleTableMoreActionBackgroundColor,
            ),
            child: const FlowySvg(
              FlowySvgs.add_s,
            ),
          ),
        ),
      ),
    );
  }
}

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

class SimpleTableColumnResizeHandle extends StatefulWidget {
  const SimpleTableColumnResizeHandle({
    super.key,
    required this.node,
  });

  final Node node;

  @override
  State<SimpleTableColumnResizeHandle> createState() =>
      _SimpleTableColumnResizeHandleState();
}

class _SimpleTableColumnResizeHandleState
    extends State<SimpleTableColumnResizeHandle> {
  bool isStartDragging = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (event) => context
          .read<SimpleTableContext>()
          .hoveringOnResizeHandle
          .value = widget.node,
      onExit: (event) {
        Future.delayed(const Duration(milliseconds: 100), () {
          // the onExit event will be triggered before dragging started.
          // delay the hiding of the resize handle to avoid flickering.
          if (!isStartDragging) {
            context.read<SimpleTableContext>().hoveringOnResizeHandle.value =
                null;
          }
        });
      },
      child: GestureDetector(
        onHorizontalDragStart: (details) {
          isStartDragging = true;
        },
        onHorizontalDragUpdate: (details) {
          context.read<EditorState>().updateColumnWidthInMemory(
                tableCellNode: widget.node,
                deltaX: details.delta.dx,
              );
        },
        onHorizontalDragEnd: (details) {
          context.read<SimpleTableContext>().hoveringOnResizeHandle.value =
              null;
          isStartDragging = false;
          context.read<EditorState>().updateColumnWidth(
                tableCellNode: widget.node,
                width: widget.node.columnWidth,
              );
        },
        child: ValueListenableBuilder<Node?>(
          valueListenable: context.read<SimpleTableContext>().hoveringTableCell,
          builder: (context, hoveringCell, child) {
            return ValueListenableBuilder(
              valueListenable:
                  context.read<SimpleTableContext>().hoveringOnResizeHandle,
              builder: (context, hoveringOnResizeHandle, child) {
                final isSameRowIndex = hoveringOnResizeHandle?.columnIndex ==
                    widget.node.columnIndex;
                return Opacity(
                  opacity: isSameRowIndex ? 1.0 : 0.0,
                  child: Container(
                    height: double.infinity,
                    width: SimpleTableConstants.resizeHandleWidth,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
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
          () => PopoverContainer.of(popoverContext).closeAll(),
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
    BuildContext context,
    VoidCallback onClose,
  ) {
    final colors = [
      // reset to default background color
      FlowyColorOption(
        color: Colors.transparent,
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

    return FlowyColorPicker(
      colors: colors,
      border: Border.all(
        color: AFThemeExtension.of(context).onBackground,
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
