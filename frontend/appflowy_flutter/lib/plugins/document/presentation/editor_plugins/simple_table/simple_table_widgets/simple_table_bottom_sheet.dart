import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/mobile/presentation/base/animated_gesture.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
        const SimpleTableQuickActions(),
        const VSpace(12),
        // insert row, insert column
        SimpleTableInsertActions(type: type),
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

/// A quick action for the table.
///
/// Copy, Cut, Paste, Delete
enum SimpleTableQuickActionType {
  copy,
  cut,
  paste,
  delete;

  FlowySvgData get icon => switch (this) {
        copy => FlowySvgs.m_table_quick_action_copy_s,
        cut => FlowySvgs.m_table_quick_action_cut_s,
        paste => FlowySvgs.m_table_quick_action_paste_s,
        delete => FlowySvgs.m_table_quick_action_delete_s,
      };

  // todo: i18n
  String get name => switch (this) {
        copy => 'Copy',
        cut => 'Cut',
        paste => 'Paste',
        delete => 'Delete',
      };
}

class SimpleTableQuickActions extends StatelessWidget {
  const SimpleTableQuickActions({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: SimpleTableConstants.actionSheetQuickActionSectionHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SimpleTableQuickAction(type: SimpleTableQuickActionType.cut),
          SimpleTableQuickAction(type: SimpleTableQuickActionType.copy),
          SimpleTableQuickAction(type: SimpleTableQuickActionType.paste),
          SimpleTableQuickAction(type: SimpleTableQuickActionType.delete),
        ],
      ),
    );
  }
}

class SimpleTableQuickAction extends StatelessWidget {
  const SimpleTableQuickAction({
    super.key,
    required this.type,
  });

  final SimpleTableQuickActionType type;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedGestureDetector(
        child: FlowySvg(
          type.icon,
          blendMode: null,
        ),
        onTapUp: () {},
      ),
    );
  }
}

class SimpleTableInsertActions extends StatelessWidget {
  const SimpleTableInsertActions({
    super.key,
    required this.type,
  });

  final SimpleTableMoreActionType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: SimpleTableConstants.actionSheetInsertSectionHeight,
      child: switch (type) {
        SimpleTableMoreActionType.row => const Row(
            children: [
              SimpleTableInsertAction(
                type: SimpleTableMoreAction.insertAbove,
                enableLeftBorder: true,
              ),
              HSpace(2),
              SimpleTableInsertAction(
                type: SimpleTableMoreAction.insertBelow,
                enableRightBorder: true,
              ),
            ],
          ),
        SimpleTableMoreActionType.column => const Row(
            children: [
              SimpleTableInsertAction(
                type: SimpleTableMoreAction.insertLeft,
                enableLeftBorder: true,
              ),
              HSpace(2),
              SimpleTableInsertAction(
                type: SimpleTableMoreAction.insertRight,
                enableRightBorder: true,
              ),
            ],
          ),
      },
    );
  }
}

class SimpleTableInsertAction extends StatelessWidget {
  const SimpleTableInsertAction({
    super.key,
    required this.type,
    this.enableLeftBorder = false,
    this.enableRightBorder = false,
  });

  final SimpleTableMoreAction type;
  final bool enableLeftBorder;
  final bool enableRightBorder;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: context.simpleTableInsertActionBackgroundColor,
          shape: _buildBorder(),
        ),
        child: AnimatedGestureDetector(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FlowySvg(type.leftIconSvg, size: const Size.square(24)),
              FlowyText(
                type.name,
                fontSize: 12,
                figmaLineHeight: 16,
              ),
            ],
          ),
          onTapUp: () {},
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
        children: _buildActions(),
      ),
    );
  }

  List<Widget> _buildActions() {
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
            SimpleTableMoreAction.enableHeaderColumn ||
            SimpleTableMoreAction.enableHeaderRow =>
              SimpleTableHeaderActionButton(
                type: action,
                onTap: (value) => _onActionTap(
                  action,
                  toggleHeaderValue: value,
                ),
              ),
            _ => SimpleTableActionButton(
                type: action,
                enableTopBorder: index == 0,
                enableBottomBorder: index == actionGroup.length - 1,
                onTap: () => _onActionTap(action),
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
    SimpleTableMoreAction action, {
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
      default:
        assert(false, 'Unsupported action: $action');
        break;
    }
  }
}

class SimpleTableHeaderActionButton extends StatefulWidget {
  const SimpleTableHeaderActionButton({
    super.key,
    required this.type,
    this.onTap,
  });

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
