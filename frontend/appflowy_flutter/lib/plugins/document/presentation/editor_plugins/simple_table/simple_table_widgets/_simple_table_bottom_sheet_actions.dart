import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/mobile/presentation/base/animated_gesture.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/block_action_option_cubit.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/option/option_actions.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Base class for all simple table bottom sheet actions
abstract class ISimpleTableBottomSheetActions extends StatelessWidget {
  const ISimpleTableBottomSheetActions({
    super.key,
    required this.type,
    required this.cellNode,
    required this.editorState,
  });

  final SimpleTableMoreActionType type;
  final Node cellNode;
  final EditorState editorState;
}

/// Quick actions for the table cell
///
/// - Copy
/// - Paste
/// - Cut
/// - Delete
class SimpleTableCellQuickActions extends ISimpleTableBottomSheetActions {
  const SimpleTableCellQuickActions({
    super.key,
    required super.type,
    required super.cellNode,
    required super.editorState,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SimpleTableConstants.actionSheetQuickActionSectionHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SimpleTableQuickAction(
            type: SimpleTableMoreAction.cut,
            onTap: () => _onActionTap(
              context,
              SimpleTableMoreAction.cut,
            ),
          ),
          SimpleTableQuickAction(
            type: SimpleTableMoreAction.copy,
            onTap: () => _onActionTap(
              context,
              SimpleTableMoreAction.copy,
            ),
          ),
          FutureBuilder(
            future: getIt<ClipboardService>().getData(),
            builder: (context, snapshot) {
              final hasContent = snapshot.data?.tableJson != null;
              return SimpleTableQuickAction(
                type: SimpleTableMoreAction.paste,
                isEnabled: hasContent,
                onTap: () => _onActionTap(
                  context,
                  SimpleTableMoreAction.paste,
                ),
              );
            },
          ),
          SimpleTableQuickAction(
            type: SimpleTableMoreAction.delete,
            onTap: () => _onActionTap(
              context,
              SimpleTableMoreAction.delete,
            ),
          ),
        ],
      ),
    );
  }

  void _onActionTap(BuildContext context, SimpleTableMoreAction action) {
    final tableNode = cellNode.parentTableNode;
    if (tableNode == null) {
      Log.error('unable to find table node when performing action: $action');
      return;
    }

    switch (action) {
      case SimpleTableMoreAction.cut:
        _onCut(tableNode);
      case SimpleTableMoreAction.copy:
        _onCopy(tableNode);
      case SimpleTableMoreAction.paste:
        _onPaste(tableNode);
      case SimpleTableMoreAction.delete:
        _onDelete(tableNode);
      default:
        assert(false, 'Unsupported action: $type');
    }

    // close the action menu
    Navigator.of(context).pop();
  }

  void _onCut(Node tableNode) {
    switch (type) {
      case SimpleTableMoreActionType.column:
        editorState.copyColumn(
          tableNode: tableNode,
          columnIndex: cellNode.columnIndex,
          clearContent: true,
        );
      case SimpleTableMoreActionType.row:
        editorState.copyRow(
          tableNode: tableNode,
          rowIndex: cellNode.rowIndex,
          clearContent: true,
        );
    }
  }

  void _onCopy(
    Node tableNode,
  ) {
    switch (type) {
      case SimpleTableMoreActionType.column:
        editorState.copyColumn(
          tableNode: tableNode,
          columnIndex: cellNode.columnIndex,
        );
      case SimpleTableMoreActionType.row:
        editorState.copyRow(
          tableNode: tableNode,
          rowIndex: cellNode.rowIndex,
        );
    }
  }

  void _onPaste(Node tableNode) {
    switch (type) {
      case SimpleTableMoreActionType.column:
        editorState.pasteColumn(
          tableNode: tableNode,
          columnIndex: cellNode.columnIndex,
        );
      case SimpleTableMoreActionType.row:
        editorState.pasteRow(
          tableNode: tableNode,
          rowIndex: cellNode.rowIndex,
        );
    }
  }

  void _onDelete(Node tableNode) {
    switch (type) {
      case SimpleTableMoreActionType.column:
        editorState.deleteColumnInTable(
          tableNode,
          cellNode.columnIndex,
        );
      case SimpleTableMoreActionType.row:
        editorState.deleteRowInTable(
          tableNode,
          cellNode.rowIndex,
        );
    }
  }
}

class SimpleTableQuickAction extends StatelessWidget {
  const SimpleTableQuickAction({
    super.key,
    required this.type,
    required this.onTap,
    this.isEnabled = true,
  });

  final SimpleTableMoreAction type;
  final VoidCallback onTap;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: AnimatedGestureDetector(
        onTapUp: isEnabled ? onTap : null,
        child: FlowySvg(
          type.leftIconSvg,
          blendMode: null,
          size: const Size.square(24),
        ),
      ),
    );
  }
}

/// Insert actions
///
/// - Column: Insert left or insert right
/// - Row: Insert above or insert below
class SimpleTableInsertActions extends ISimpleTableBottomSheetActions {
  const SimpleTableInsertActions({
    super.key,
    required super.type,
    required super.cellNode,
    required super.editorState,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: SimpleTableConstants.actionSheetInsertSectionHeight,
      child: _buildAction(context),
    );
  }

  Widget _buildAction(BuildContext context) {
    return switch (type) {
      SimpleTableMoreActionType.row => Row(
          children: [
            SimpleTableInsertAction(
              type: SimpleTableMoreAction.insertAbove,
              enableLeftBorder: true,
              onTap: () => _onActionTap(
                context,
                SimpleTableMoreAction.insertAbove,
              ),
            ),
            const HSpace(2),
            SimpleTableInsertAction(
              type: SimpleTableMoreAction.insertBelow,
              enableRightBorder: true,
              onTap: () => _onActionTap(
                context,
                SimpleTableMoreAction.insertBelow,
              ),
            ),
          ],
        ),
      SimpleTableMoreActionType.column => Row(
          children: [
            SimpleTableInsertAction(
              type: SimpleTableMoreAction.insertLeft,
              enableLeftBorder: true,
              onTap: () => _onActionTap(
                context,
                SimpleTableMoreAction.insertLeft,
              ),
            ),
            const HSpace(2),
            SimpleTableInsertAction(
              type: SimpleTableMoreAction.insertRight,
              enableRightBorder: true,
              onTap: () => _onActionTap(
                context,
                SimpleTableMoreAction.insertRight,
              ),
            ),
          ],
        ),
    };
  }

  void _onActionTap(BuildContext context, SimpleTableMoreAction type) {
    final simpleTableContext = context.read<SimpleTableContext>();
    final tableNode = cellNode.parentTableNode;
    if (tableNode == null) {
      Log.error('unable to find table node when performing action: $type');
      return;
    }

    switch (type) {
      case SimpleTableMoreAction.insertAbove:
        // update the highlight status for the selecting row
        simpleTableContext.selectingRow.value = cellNode.rowIndex + 1;
        editorState.insertRowInTable(
          tableNode,
          cellNode.rowIndex,
        );
      case SimpleTableMoreAction.insertBelow:
        editorState.insertRowInTable(
          tableNode,
          cellNode.rowIndex + 1,
        );
      case SimpleTableMoreAction.insertLeft:
        // update the highlight status for the selecting column
        simpleTableContext.selectingColumn.value = cellNode.columnIndex + 1;
        editorState.insertColumnInTable(
          tableNode,
          cellNode.columnIndex,
        );
      case SimpleTableMoreAction.insertRight:
        editorState.insertColumnInTable(
          tableNode,
          cellNode.columnIndex + 1,
        );
      default:
        assert(false, 'Unsupported action: $type');
    }
  }
}

class SimpleTableInsertAction extends StatelessWidget {
  const SimpleTableInsertAction({
    super.key,
    required this.type,
    this.enableLeftBorder = false,
    this.enableRightBorder = false,
    required this.onTap,
  });

  final SimpleTableMoreAction type;
  final bool enableLeftBorder;
  final bool enableRightBorder;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: context.simpleTableInsertActionBackgroundColor,
          shape: _buildBorder(),
        ),
        child: AnimatedGestureDetector(
          onTapUp: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(1),
                child: FlowySvg(
                  type.leftIconSvg,
                  size: const Size.square(22),
                ),
              ),
              FlowyText(
                type.name,
                fontSize: 12,
                figmaLineHeight: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  RoundedRectangleBorder _buildBorder() {
    const radius = Radius.circular(
      SimpleTableConstants.actionSheetButtonRadius,
    );
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: enableLeftBorder ? radius : Radius.zero,
        bottomLeft: enableLeftBorder ? radius : Radius.zero,
        topRight: enableRightBorder ? radius : Radius.zero,
        bottomRight: enableRightBorder ? radius : Radius.zero,
      ),
    );
  }
}

/// Cell Action buttons
///
/// - Distribute columns evenly
/// - Set to page width
/// - Duplicate row
/// - Duplicate column
/// - Clear contents
class SimpleTableCellActionButtons extends ISimpleTableBottomSheetActions {
  const SimpleTableCellActionButtons({
    super.key,
    required super.type,
    required super.cellNode,
    required super.editorState,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _buildActions(context),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    // the actions are grouped into different sections
    // we need to get the index of the table cell node
    // and the length of the columns and rows
    final (index, columnLength, rowLength) = switch (type) {
      SimpleTableMoreActionType.row => (
          cellNode.rowIndex,
          cellNode.columnLength,
          cellNode.rowLength,
        ),
      SimpleTableMoreActionType.column => (
          cellNode.columnIndex,
          cellNode.rowLength,
          cellNode.columnLength,
        ),
    };
    final actionGroups = type.buildMobileActions(
      index: index,
      columnLength: columnLength,
      rowLength: rowLength,
    );
    final List<Widget> widgets = [];

    for (final (actionGroupIndex, actionGroup) in actionGroups.indexed) {
      for (final (index, action) in actionGroup.indexed) {
        widgets.add(
          // enable the corner border if the cell is the first or last in the group
          switch (action) {
            SimpleTableMoreAction.enableHeaderColumn =>
              SimpleTableHeaderActionButton(
                type: action,
                isEnabled: cellNode.isHeaderColumnEnabled,
                onTap: (value) => _onActionTap(
                  context,
                  action: action,
                  toggleHeaderValue: value,
                ),
              ),
            SimpleTableMoreAction.enableHeaderRow =>
              SimpleTableHeaderActionButton(
                type: action,
                isEnabled: cellNode.isHeaderRowEnabled,
                onTap: (value) => _onActionTap(
                  context,
                  action: action,
                  toggleHeaderValue: value,
                ),
              ),
            _ => SimpleTableActionButton(
                type: action,
                enableTopBorder: index == 0,
                enableBottomBorder: index == actionGroup.length - 1,
                onTap: () => _onActionTap(
                  context,
                  action: action,
                ),
              ),
          },
        );
        // if the action is not the first or last in the group, add a divider
        if (index != actionGroup.length - 1) {
          widgets.add(const FlowyDivider());
        }
      }

      // add padding to separate the action groups
      if (actionGroupIndex != actionGroups.length - 1) {
        widgets.add(const VSpace(16));
      }
    }

    return widgets;
  }

  void _onActionTap(
    BuildContext context, {
    required SimpleTableMoreAction action,
    bool toggleHeaderValue = false,
  }) {
    final tableNode = cellNode.parentTableNode;
    if (tableNode == null) {
      Log.error('unable to find table node when performing action: $action');
      return;
    }

    switch (action) {
      case SimpleTableMoreAction.enableHeaderColumn:
        editorState.toggleEnableHeaderColumn(
          tableNode: tableNode,
          enable: toggleHeaderValue,
        );
      case SimpleTableMoreAction.enableHeaderRow:
        editorState.toggleEnableHeaderRow(
          tableNode: tableNode,
          enable: toggleHeaderValue,
        );
      case SimpleTableMoreAction.distributeColumnsEvenly:
        editorState.distributeColumnWidthToPageWidth(tableNode: tableNode);
      case SimpleTableMoreAction.setToPageWidth:
        editorState.setColumnWidthToPageWidth(tableNode: tableNode);
      case SimpleTableMoreAction.duplicateRow:
        editorState.duplicateRowInTable(
          tableNode,
          cellNode.rowIndex,
        );
      case SimpleTableMoreAction.duplicateColumn:
        editorState.duplicateColumnInTable(
          tableNode,
          cellNode.columnIndex,
        );
      case SimpleTableMoreAction.clearContents:
        switch (type) {
          case SimpleTableMoreActionType.column:
            editorState.clearContentAtColumnIndex(
              tableNode: tableNode,
              columnIndex: cellNode.columnIndex,
            );
          case SimpleTableMoreActionType.row:
            editorState.clearContentAtRowIndex(
              tableNode: tableNode,
              rowIndex: cellNode.rowIndex,
            );
        }
      default:
        assert(false, 'Unsupported action: $action');
        break;
    }

    // close the action menu
    Navigator.of(context).pop();
  }
}

/// Header action button
///
/// - Enable header column
/// - Enable header row
///
/// Notes: These actions are only available for the first column or first row
class SimpleTableHeaderActionButton extends StatefulWidget {
  const SimpleTableHeaderActionButton({
    super.key,
    required this.isEnabled,
    required this.type,
    this.onTap,
  });

  final bool isEnabled;
  final SimpleTableMoreAction type;
  final void Function(bool value)? onTap;

  @override
  State<SimpleTableHeaderActionButton> createState() =>
      _SimpleTableHeaderActionButtonState();
}

class _SimpleTableHeaderActionButtonState
    extends State<SimpleTableHeaderActionButton> {
  bool value = false;

  @override
  void initState() {
    super.initState();

    value = widget.isEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return SimpleTableActionButton(
      type: widget.type,
      enableTopBorder: true,
      enableBottomBorder: true,
      onTap: _toggle,
      rightIconBuilder: (context) {
        return Container(
          width: 36,
          height: 24,
          margin: const EdgeInsets.only(right: 16),
          child: FittedBox(
            fit: BoxFit.fill,
            child: CupertinoSwitch(
              value: value,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (_) {},
            ),
          ),
        );
      },
    );
  }

  void _toggle() {
    setState(() {
      value = !value;
    });

    widget.onTap?.call(value);
  }
}

/// Align text action button
///
/// - Align text to left
/// - Align text to center
/// - Align text to right
///
/// Notes: These actions are only available for the table
class SimpleTableAlignActionButton extends StatefulWidget {
  const SimpleTableAlignActionButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  State<SimpleTableAlignActionButton> createState() =>
      _SimpleTableAlignActionButtonState();
}

class _SimpleTableAlignActionButtonState
    extends State<SimpleTableAlignActionButton> {
  @override
  Widget build(BuildContext context) {
    return SimpleTableActionButton(
      type: SimpleTableMoreAction.align,
      enableTopBorder: true,
      enableBottomBorder: true,
      onTap: widget.onTap,
      rightIconBuilder: (context) {
        return const Padding(
          padding: EdgeInsets.only(right: 16),
          child: FlowySvg(FlowySvgs.m_aa_arrow_right_s),
        );
      },
    );
  }
}

class SimpleTableActionButton extends StatelessWidget {
  const SimpleTableActionButton({
    super.key,
    required this.type,
    this.enableTopBorder = false,
    this.enableBottomBorder = false,
    this.rightIconBuilder,
    this.onTap,
  });

  final SimpleTableMoreAction type;
  final bool enableTopBorder;
  final bool enableBottomBorder;
  final WidgetBuilder? rightIconBuilder;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: SimpleTableConstants.actionSheetNormalActionSectionHeight,
        decoration: ShapeDecoration(
          color: context.simpleTableActionButtonBackgroundColor,
          shape: _buildBorder(),
        ),
        child: Row(
          children: [
            const HSpace(16),
            Padding(
              padding: const EdgeInsets.all(1.0),
              child: FlowySvg(
                type.leftIconSvg,
                size: const Size.square(20),
              ),
            ),
            const HSpace(12),
            FlowyText(
              type.name,
              fontSize: 14,
              figmaLineHeight: 20,
            ),
            const Spacer(),
            rightIconBuilder?.call(context) ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  RoundedRectangleBorder _buildBorder() {
    const radius = Radius.circular(
      SimpleTableConstants.actionSheetButtonRadius,
    );
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: enableTopBorder ? radius : Radius.zero,
        topRight: enableTopBorder ? radius : Radius.zero,
        bottomLeft: enableBottomBorder ? radius : Radius.zero,
        bottomRight: enableBottomBorder ? radius : Radius.zero,
      ),
    );
  }
}

class SimpleTableContentActions extends ISimpleTableBottomSheetActions {
  const SimpleTableContentActions({
    super.key,
    required super.type,
    required super.cellNode,
    required super.editorState,
    required this.onTextColorSelected,
    required this.onCellBackgroundColorSelected,
    this.selectedTextColor,
    this.selectedCellBackgroundColor,
  });

  final VoidCallback onTextColorSelected;
  final VoidCallback onCellBackgroundColorSelected;

  final Color? selectedTextColor;
  final Color? selectedCellBackgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SimpleTableConstants.actionSheetContentSectionHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SimpleTableContentBoldAction(
            isBold: type == SimpleTableMoreActionType.column
                ? cellNode.isInBoldColumn
                : cellNode.isInBoldRow,
            toggleBold: _toggleBold,
          ),
          const HSpace(2),
          SimpleTableContentTextColorAction(
            onTap: onTextColorSelected,
            selectedTextColor: selectedTextColor,
          ),
          const HSpace(2),
          SimpleTableContentCellBackgroundColorAction(
            onTap: onCellBackgroundColorSelected,
            selectedCellBackgroundColor: selectedCellBackgroundColor,
          ),
          const HSpace(16),
          const SimpleTableContentAlignmentAction(),
        ],
      ),
    );
  }

  void _toggleBold(bool isBold) {
    switch (type) {
      case SimpleTableMoreActionType.column:
        editorState.toggleColumnBoldAttribute(
          tableCellNode: cellNode,
          isBold: isBold,
        );
      case SimpleTableMoreActionType.row:
        editorState.toggleRowBoldAttribute(
          tableCellNode: cellNode,
          isBold: isBold,
        );
    }
  }
}

class SimpleTableContentBoldAction extends StatefulWidget {
  const SimpleTableContentBoldAction({
    super.key,
    required this.toggleBold,
    required this.isBold,
  });

  final ValueChanged<bool> toggleBold;
  final bool isBold;

  @override
  State<SimpleTableContentBoldAction> createState() =>
      _SimpleTableContentBoldActionState();
}

class _SimpleTableContentBoldActionState
    extends State<SimpleTableContentBoldAction> {
  bool isBold = false;

  @override
  void initState() {
    super.initState();

    isBold = widget.isBold;
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SimpleTableContentActionDecorator(
        backgroundColor: isBold ? Theme.of(context).colorScheme.primary : null,
        enableLeftBorder: true,
        child: AnimatedGestureDetector(
          onTapUp: () {
            setState(() {
              isBold = !isBold;
            });
            widget.toggleBold.call(isBold);
          },
          child: FlowySvg(
            FlowySvgs.m_aa_bold_s,
            size: const Size.square(24),
            color: isBold ? Theme.of(context).colorScheme.onPrimary : null,
          ),
        ),
      ),
    );
  }
}

class SimpleTableContentTextColorAction extends StatelessWidget {
  const SimpleTableContentTextColorAction({
    super.key,
    required this.onTap,
    this.selectedTextColor,
  });

  final VoidCallback onTap;
  final Color? selectedTextColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SimpleTableContentActionDecorator(
        child: AnimatedGestureDetector(
          onTapUp: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FlowySvg(
                FlowySvgs.m_table_text_color_m,
                color: selectedTextColor,
              ),
              const HSpace(10),
              const FlowySvg(
                FlowySvgs.m_aa_arrow_right_s,
                size: Size.square(12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SimpleTableContentCellBackgroundColorAction extends StatelessWidget {
  const SimpleTableContentCellBackgroundColorAction({
    super.key,
    required this.onTap,
    this.selectedCellBackgroundColor,
  });

  final VoidCallback onTap;
  final Color? selectedCellBackgroundColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SimpleTableContentActionDecorator(
        enableRightBorder: true,
        child: AnimatedGestureDetector(
          onTapUp: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTextBackgroundColorPreview(),
              const HSpace(10),
              FlowySvg(
                FlowySvgs.m_aa_arrow_right_s,
                size: const Size.square(12),
                color: selectedCellBackgroundColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextBackgroundColorPreview() {
    return Container(
      width: 24,
      height: 24,
      decoration: ShapeDecoration(
        color: selectedCellBackgroundColor ?? const Color(0xFFFFE6FD),
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            color: Color(0xFFCFD3D9),
          ),
          borderRadius: BorderRadius.circular(100),
        ),
      ),
    );
  }
}

class SimpleTableContentAlignmentAction extends StatelessWidget {
  const SimpleTableContentAlignmentAction({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SimpleTableContentActionDecorator(
        enableLeftBorder: true,
        enableRightBorder: true,
        child: AnimatedGestureDetector(
          onTapUp: () {},
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FlowySvg(
                FlowySvgs.m_aa_align_left_m,
              ),
              HSpace(10),
              FlowySvg(
                FlowySvgs.m_aa_arrow_right_s,
                size: Size.square(12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SimpleTableContentActionDecorator extends StatelessWidget {
  const SimpleTableContentActionDecorator({
    super.key,
    this.enableLeftBorder = false,
    this.enableRightBorder = false,
    this.backgroundColor,
    required this.child,
  });

  final bool enableLeftBorder;
  final bool enableRightBorder;
  final Color? backgroundColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SimpleTableConstants.actionSheetNormalActionSectionHeight,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: ShapeDecoration(
        color:
            backgroundColor ?? context.simpleTableInsertActionBackgroundColor,
        shape: _buildBorder(),
      ),
      child: child,
    );
  }

  RoundedRectangleBorder _buildBorder() {
    const radius = Radius.circular(
      SimpleTableConstants.actionSheetButtonRadius,
    );
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: enableLeftBorder ? radius : Radius.zero,
        topRight: enableRightBorder ? radius : Radius.zero,
        bottomLeft: enableLeftBorder ? radius : Radius.zero,
        bottomRight: enableRightBorder ? radius : Radius.zero,
      ),
    );
  }
}

class SimpleTableActionButtons extends StatelessWidget {
  const SimpleTableActionButtons({
    super.key,
    required this.tableNode,
    required this.editorState,
    required this.onAlignTap,
  });

  final Node tableNode;
  final EditorState editorState;
  final VoidCallback onAlignTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _buildActions(context),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final actionGroups = [
      [
        SimpleTableMoreAction.setToPageWidth,
        SimpleTableMoreAction.distributeColumnsEvenly,
      ],
      [
        SimpleTableMoreAction.align,
      ],
      [
        SimpleTableMoreAction.duplicateTable,
        SimpleTableMoreAction.copyLinkToBlock,
      ]
    ];
    final List<Widget> widgets = [];

    for (final (actionGroupIndex, actionGroup) in actionGroups.indexed) {
      for (final (index, action) in actionGroup.indexed) {
        widgets.add(
          // enable the corner border if the cell is the first or last in the group
          switch (action) {
            SimpleTableMoreAction.align => SimpleTableAlignActionButton(
                onTap: () => _onActionTap(
                  context,
                  action: action,
                ),
              ),
            _ => SimpleTableActionButton(
                type: action,
                enableTopBorder: index == 0,
                enableBottomBorder: index == actionGroup.length - 1,
                onTap: () => _onActionTap(
                  context,
                  action: action,
                ),
              ),
          },
        );
        // if the action is not the first or last in the group, add a divider
        if (index != actionGroup.length - 1) {
          widgets.add(const FlowyDivider());
        }
      }

      // add padding to separate the action groups
      if (actionGroupIndex != actionGroups.length - 1) {
        widgets.add(const VSpace(16));
      }
    }

    return widgets;
  }

  void _onActionTap(
    BuildContext context, {
    required SimpleTableMoreAction action,
  }) {
    final optionCubit = BlockActionOptionCubit(
      editorState: editorState,
      blockComponentBuilder: {},
    );
    switch (action) {
      case SimpleTableMoreAction.setToPageWidth:
        editorState.setColumnWidthToPageWidth(tableNode: tableNode);
      case SimpleTableMoreAction.distributeColumnsEvenly:
        editorState.distributeColumnWidthToPageWidth(tableNode: tableNode);
      case SimpleTableMoreAction.duplicateTable:
        optionCubit.handleAction(OptionAction.duplicate, tableNode);
      case SimpleTableMoreAction.copyLinkToBlock:
        optionCubit.handleAction(OptionAction.copyLinkToBlock, tableNode);
      case SimpleTableMoreAction.align:
        onAlignTap();
      default:
        assert(false, 'Unsupported action: $action');
        break;
    }

    // close the action menu
    if (action != SimpleTableMoreAction.align) {
      Navigator.of(context).pop();
    }
  }
}

class SimpleTableContentAlignAction extends StatefulWidget {
  const SimpleTableContentAlignAction({
    super.key,
    required this.isSelected,
    required this.align,
    required this.onTap,
  });

  final bool isSelected;
  final VoidCallback onTap;
  final TableAlign align;

  @override
  State<SimpleTableContentAlignAction> createState() =>
      _SimpleTableContentAlignActionState();
}

class _SimpleTableContentAlignActionState
    extends State<SimpleTableContentAlignAction> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SimpleTableContentActionDecorator(
        backgroundColor:
            widget.isSelected ? Theme.of(context).colorScheme.primary : null,
        enableLeftBorder: widget.align == TableAlign.left,
        enableRightBorder: widget.align == TableAlign.right,
        child: AnimatedGestureDetector(
          onTapUp: widget.onTap,
          child: FlowySvg(
            widget.align.leftIconSvg,
            size: const Size.square(24),
            color: widget.isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : null,
          ),
        ),
      ),
    );
  }
}

/// Quick actions for the table
///
/// - Copy
/// - Paste
/// - Cut
/// - Delete
class SimpleTableQuickActions extends StatelessWidget {
  const SimpleTableQuickActions({
    super.key,
    required this.tableNode,
    required this.editorState,
  });

  final Node tableNode;
  final EditorState editorState;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SimpleTableConstants.actionSheetQuickActionSectionHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SimpleTableQuickAction(
            type: SimpleTableMoreAction.cut,
            onTap: () => _onActionTap(
              context,
              SimpleTableMoreAction.cut,
            ),
          ),
          SimpleTableQuickAction(
            type: SimpleTableMoreAction.copy,
            onTap: () => _onActionTap(
              context,
              SimpleTableMoreAction.copy,
            ),
          ),
          FutureBuilder(
            future: getIt<ClipboardService>().getData(),
            builder: (context, snapshot) {
              final hasContent = snapshot.data?.tableJson != null;
              return SimpleTableQuickAction(
                type: SimpleTableMoreAction.paste,
                isEnabled: hasContent,
                onTap: () => _onActionTap(
                  context,
                  SimpleTableMoreAction.paste,
                ),
              );
            },
          ),
          SimpleTableQuickAction(
            type: SimpleTableMoreAction.delete,
            onTap: () => _onActionTap(
              context,
              SimpleTableMoreAction.delete,
            ),
          ),
        ],
      ),
    );
  }

  void _onActionTap(BuildContext context, SimpleTableMoreAction action) {
    switch (action) {
      case SimpleTableMoreAction.cut:
        _onCut(tableNode);
      case SimpleTableMoreAction.copy:
        _onCopy(tableNode);
      case SimpleTableMoreAction.paste:
        _onPaste(tableNode);
      case SimpleTableMoreAction.delete:
        _onDelete(tableNode);
      default:
        assert(false, 'Unsupported action: $action');
    }

    // close the action menu
    Navigator.of(context).pop();
  }

  void _onCut(Node tableNode) {}

  void _onCopy(
    Node tableNode,
  ) {}

  void _onPaste(Node tableNode) {}

  void _onDelete(Node tableNode) {}
}
