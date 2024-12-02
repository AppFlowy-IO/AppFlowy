import 'dart:ui';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Only displaying the add row / add column / add column and row button
///   when hovering on the last row / last column / last cell.
bool _enableHoveringLogicV2 = true;

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

class SimpleTableAddRowHoverButton extends StatefulWidget {
  const SimpleTableAddRowHoverButton({
    super.key,
    required this.editorState,
    required this.tableNode,
  });

  final EditorState editorState;
  final Node tableNode;

  @override
  State<SimpleTableAddRowHoverButton> createState() =>
      _SimpleTableAddRowHoverButtonState();
}

class _SimpleTableAddRowHoverButtonState
    extends State<SimpleTableAddRowHoverButton> {
  late final interceptorKey =
      'simple_table_add_row_hover_button_${widget.tableNode.id}';

  SelectionGestureInterceptor? interceptor;

  @override
  void initState() {
    super.initState();

    interceptor = SelectionGestureInterceptor(
      key: interceptorKey,
      canTap: (details) => !_isTapInBounds(details.globalPosition),
    );
    widget.editorState.service.selectionService
        .registerGestureInterceptor(interceptor!);
  }

  @override
  void dispose() {
    widget.editorState.service.selectionService.unregisterGestureInterceptor(
      interceptorKey,
    );

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.tableNode.type == SimpleTableBlockKeys.type);

    if (widget.tableNode.type != SimpleTableBlockKeys.type) {
      return const SizedBox.shrink();
    }

    final simpleTableContext = context.read<SimpleTableContext>();
    return ValueListenableBuilder(
      valueListenable: simpleTableContext.isHoveringOnTableBlock,
      builder: (context, isHoveringOnTableBlock, child) {
        return ValueListenableBuilder(
          valueListenable: simpleTableContext.hoveringTableCell,
          builder: (context, hoveringTableCell, child) {
            bool shouldShow = isHoveringOnTableBlock;
            if (hoveringTableCell != null && _enableHoveringLogicV2) {
              shouldShow =
                  hoveringTableCell.rowIndex + 1 == hoveringTableCell.rowLength;
            }
            return shouldShow
                ? Positioned(
                    bottom: 2 * SimpleTableConstants.addRowButtonPadding,
                    left: SimpleTableConstants.tableLeftPadding -
                        SimpleTableConstants.cellBorderWidth,
                    right: SimpleTableConstants.addRowButtonRightPadding,
                    child: SimpleTableAddRowButton(
                      onTap: () => widget.editorState.addRowInTable(
                        widget.tableNode,
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          },
        );
      },
    );
  }

  bool _isTapInBounds(Offset offset) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return false;
    }

    final localPosition = renderBox.globalToLocal(offset);
    final result = renderBox.paintBounds.contains(localPosition);

    return result;
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
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            height: SimpleTableConstants.addRowButtonHeight,
            margin: const EdgeInsets.symmetric(
              vertical: SimpleTableConstants.addColumnButtonPadding,
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

class SimpleTableAddColumnHoverButton extends StatefulWidget {
  const SimpleTableAddColumnHoverButton({
    super.key,
    required this.editorState,
    required this.node,
  });

  final EditorState editorState;
  final Node node;

  @override
  State<SimpleTableAddColumnHoverButton> createState() =>
      _SimpleTableAddColumnHoverButtonState();
}

class _SimpleTableAddColumnHoverButtonState
    extends State<SimpleTableAddColumnHoverButton> {
  late final interceptorKey =
      'simple_table_add_column_hover_button_${widget.node.id}';

  SelectionGestureInterceptor? interceptor;

  @override
  void initState() {
    super.initState();

    interceptor = SelectionGestureInterceptor(
      key: interceptorKey,
      canTap: (details) => !_isTapInBounds(details.globalPosition),
    );
    widget.editorState.service.selectionService
        .registerGestureInterceptor(interceptor!);
  }

  @override
  void dispose() {
    widget.editorState.service.selectionService.unregisterGestureInterceptor(
      interceptorKey,
    );

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.node.type == SimpleTableBlockKeys.type);

    if (widget.node.type != SimpleTableBlockKeys.type) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder(
      valueListenable:
          context.read<SimpleTableContext>().isHoveringOnTableBlock,
      builder: (context, isHoveringOnTableBlock, _) {
        return ValueListenableBuilder(
          valueListenable: context.read<SimpleTableContext>().hoveringTableCell,
          builder: (context, hoveringTableCell, _) {
            bool shouldShow = isHoveringOnTableBlock;
            if (hoveringTableCell != null && _enableHoveringLogicV2) {
              shouldShow = hoveringTableCell.columnIndex + 1 ==
                  hoveringTableCell.columnLength;
            }
            return shouldShow
                ? Positioned(
                    top: SimpleTableConstants.tableTopPadding -
                        SimpleTableConstants.cellBorderWidth,
                    bottom: SimpleTableConstants.addColumnButtonBottomPadding,
                    right: 0,
                    child: SimpleTableAddColumnButton(
                      onTap: () {
                        widget.editorState.addColumnInTable(widget.node);
                      },
                    ),
                  )
                : const SizedBox.shrink();
          },
        );
      },
    );
  }

  bool _isTapInBounds(Offset offset) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return false;
    }

    final localPosition = renderBox.globalToLocal(offset);
    final result = renderBox.paintBounds.contains(localPosition);

    return result;
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
      valueListenable:
          context.read<SimpleTableContext>().isHoveringOnTableBlock,
      builder: (context, isHoveringOnTableBlock, child) {
        return ValueListenableBuilder(
          valueListenable: context.read<SimpleTableContext>().hoveringTableCell,
          builder: (context, hoveringTableCell, child) {
            bool shouldShow = isHoveringOnTableBlock;
            if (hoveringTableCell != null && _enableHoveringLogicV2) {
              shouldShow = hoveringTableCell.isLastCellInTable;
            }
            return shouldShow
                ? Positioned(
                    bottom:
                        SimpleTableConstants.addColumnAndRowButtonBottomPadding,
                    right: SimpleTableConstants.addColumnButtonPadding,
                    child: SimpleTableAddColumnAndRowButton(
                      onTap: () => editorState.addColumnAndRowInTable(node),
                    ),
                  )
                : const SizedBox.shrink();
          },
        );
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
          // disable the two-finger drag on trackpad
          if (details.kind == PointerDeviceKind.trackpad) {
            return;
          }
          isStartDragging = true;
        },
        onHorizontalDragUpdate: (details) {
          if (!isStartDragging) {
            return;
          }
          context.read<EditorState>().updateColumnWidthInMemory(
                tableCellNode: widget.node,
                deltaX: details.delta.dx,
              );
        },
        onHorizontalDragEnd: (details) {
          if (!isStartDragging) {
            return;
          }
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
