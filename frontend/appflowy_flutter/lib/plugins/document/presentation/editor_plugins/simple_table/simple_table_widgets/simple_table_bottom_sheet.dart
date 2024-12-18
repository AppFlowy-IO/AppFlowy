import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/mobile/presentation/base/animated_gesture.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Note: This widget is only used for mobile.
class SimpleTableBottomSheet extends StatelessWidget {
  const SimpleTableBottomSheet({
    super.key,
    required this.type,
    required this.node,
    required this.editorState,
  });

  final SimpleTableMoreActionType type;
  final Node node;
  final EditorState editorState;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // copy, cut, paste, delete
        SimpleTableQuickActions(
          type: type,
          node: node,
          editorState: editorState,
        ),
        const VSpace(12),
        // insert row, insert column
        SimpleTableInsertActions(
          type: type,
          tableCellNode: node,
          editorState: editorState,
        ),
        const VSpace(16),
        // action buttons
        SimpleTableActionButtons(
          type: type,
          tableCellNode: node,
          editorState: editorState,
        ),
      ],
    );
  }
}

class SimpleTableQuickActions extends StatelessWidget {
  const SimpleTableQuickActions({
    super.key,
    required this.type,
    required this.node,
    required this.editorState,
  });

  final SimpleTableMoreActionType type;
  final Node node;
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
            onTap: () => _onActionTap(context, SimpleTableMoreAction.cut),
          ),
          SimpleTableQuickAction(
            type: SimpleTableMoreAction.copy,
            onTap: () => _onActionTap(context, SimpleTableMoreAction.copy),
          ),
          SimpleTableQuickAction(
            type: SimpleTableMoreAction.paste,
            onTap: () => _onActionTap(context, SimpleTableMoreAction.paste),
          ),
          SimpleTableQuickAction(
            type: SimpleTableMoreAction.delete,
            onTap: () => _onActionTap(context, SimpleTableMoreAction.delete),
          ),
        ],
      ),
    );
  }

  void _onActionTap(BuildContext context, SimpleTableMoreAction action) {
    final tableNode = node.parentTableNode;
    if (tableNode == null) {
      Log.error('unable to find table node when performing action: $action');
      return;
    }

    switch (action) {
      case SimpleTableMoreAction.cut:
      case SimpleTableMoreAction.copy:
        switch (type) {
          case SimpleTableMoreActionType.column:
            editorState.copyColumn(
              tableNode: tableNode,
              columnIndex: node.columnIndex,
            );
          case SimpleTableMoreActionType.row:
          // editorState.copyRow(
          //   tableNode: tableNode,
          //   rowIndex: node.rowIndex,
          // );
        }
      case SimpleTableMoreAction.paste:
      case SimpleTableMoreAction.delete:
        switch (type) {
          case SimpleTableMoreActionType.column:
            editorState.deleteColumnInTable(
              tableNode,
              node.columnIndex,
            );
          case SimpleTableMoreActionType.row:
            editorState.deleteRowInTable(
              tableNode,
              node.rowIndex,
            );
        }
      default:
        assert(false, 'Unsupported action: $type');
    }

    // close the action menu
    Navigator.of(context).pop();
  }
}

class SimpleTableQuickAction extends StatelessWidget {
  const SimpleTableQuickAction({
    super.key,
    required this.type,
    required this.onTap,
  });

  final SimpleTableMoreAction type;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedGestureDetector(
        onTapUp: onTap,
        child: FlowySvg(
          type.leftIconSvg,
          blendMode: null,
          size: const Size.square(24),
        ),
      ),
    );
  }
}

class SimpleTableInsertActions extends StatelessWidget {
  const SimpleTableInsertActions({
    super.key,
    required this.type,
    required this.tableCellNode,
    required this.editorState,
  });

  final SimpleTableMoreActionType type;
  final Node tableCellNode;
  final EditorState editorState;

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
    final tableNode = tableCellNode.parentTableNode;
    if (tableNode == null) {
      Log.error('unable to find table node when performing action: $type');
      return;
    }

    switch (type) {
      case SimpleTableMoreAction.insertAbove:
        // update the highlight status for the selecting row
        simpleTableContext.selectingRow.value = tableCellNode.rowIndex + 1;
        editorState.insertRowInTable(
          tableNode,
          tableCellNode.rowIndex,
        );
      case SimpleTableMoreAction.insertBelow:
        editorState.insertRowInTable(
          tableNode,
          tableCellNode.rowIndex + 1,
        );
      case SimpleTableMoreAction.insertLeft:
        // update the highlight status for the selecting column
        simpleTableContext.selectingColumn.value =
            tableCellNode.columnIndex + 1;
        editorState.insertColumnInTable(
          tableNode,
          tableCellNode.columnIndex,
        );
      case SimpleTableMoreAction.insertRight:
        editorState.insertColumnInTable(
          tableNode,
          tableCellNode.columnIndex + 1,
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

class SimpleTableActionButtons extends StatelessWidget {
  const SimpleTableActionButtons({
    super.key,
    required this.type,
    required this.tableCellNode,
    required this.editorState,
  });

  final SimpleTableMoreActionType type;
  final Node tableCellNode;
  final EditorState editorState;

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
          tableCellNode.rowIndex,
          tableCellNode.columnLength,
          tableCellNode.rowLength,
        ),
      SimpleTableMoreActionType.column => (
          tableCellNode.columnIndex,
          tableCellNode.rowLength,
          tableCellNode.columnLength,
        ),
    };
    final actionGroups = type.buildMobileActions(
      index: index,
      columnLength: columnLength,
      rowLength: rowLength,
    );
    final List<Widget> widgets = [];

    for (final actionGroup in actionGroups) {
      for (final (index, action) in actionGroup.indexed) {
        widgets.add(
          // enable the corner border if the cell is the first or last in the group
          switch (action) {
            SimpleTableMoreAction.enableHeaderColumn =>
              SimpleTableHeaderActionButton(
                type: action,
                isEnabled: tableCellNode.isHeaderColumnEnabled,
                onTap: (value) => _onActionTap(
                  context,
                  action: action,
                  toggleHeaderValue: value,
                ),
              ),
            SimpleTableMoreAction.enableHeaderRow =>
              SimpleTableHeaderActionButton(
                type: action,
                isEnabled: tableCellNode.isHeaderRowEnabled,
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
      widgets.add(const VSpace(16));
    }

    return widgets;
  }

  void _onActionTap(
    BuildContext context, {
    required SimpleTableMoreAction action,
    bool toggleHeaderValue = false,
  }) {
    final tableNode = tableCellNode.parentTableNode;
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
          tableCellNode.rowIndex,
        );
      case SimpleTableMoreAction.duplicateColumn:
        editorState.duplicateColumnInTable(
          tableNode,
          tableCellNode.columnIndex,
        );
      case SimpleTableMoreAction.clearContents:
        switch (type) {
          case SimpleTableMoreActionType.column:
            editorState.clearContentAtColumnIndex(
              tableNode: tableNode,
              columnIndex: tableCellNode.columnIndex,
            );
          case SimpleTableMoreActionType.row:
            editorState.clearContentAtRowIndex(
              tableNode: tableNode,
              rowIndex: tableCellNode.rowIndex,
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
