import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/option_action.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/widget/ignore_parent_gesture.dart';
import 'package:flutter/material.dart';

class OptionActionList extends StatelessWidget {
  const OptionActionList({
    Key? key,
    required this.blockComponentContext,
    required this.blockComponentState,
    required this.actions,
    required this.editorState,
  }) : super(key: key);

  final BlockComponentContext blockComponentContext;
  final BlockComponentActionState blockComponentState;
  final List<OptionAction> actions;
  final EditorState editorState;

  @override
  Widget build(BuildContext context) {
    final popoverActions = actions.map((e) {
      if (e == OptionAction.divider) {
        return DividerOptionAction();
      } else if (e == OptionAction.color) {
        return ColorOptionAction(
          editorState: editorState,
        );
      } else {
        return OptionActionWrapper(e);
      }
    }).toList();

    return PopoverActionList<PopoverAction>(
      direction: PopoverDirection.leftWithCenterAligned,
      actions: popoverActions,
      onPopupBuilder: () => blockComponentState.alwaysShowActions = true,
      onClosed: () {
        editorState.selectionType = null;
        editorState.selection = null;
        blockComponentState.alwaysShowActions = false;
      },
      onSelected: (action, controller) {
        if (action is OptionActionWrapper) {
          _onSelectAction(action.inner);
          controller.close();
        }
      },
      buildChild: (controller) => OptionActionButton(
        onTap: () {
          controller.show();

          // update selection
          _updateBlockSelection();
        },
      ),
    );
  }

  void _updateBlockSelection() {
    final startNode = blockComponentContext.node;
    var endNode = startNode;
    while (endNode.children.isNotEmpty) {
      endNode = endNode.children.last;
    }

    final start = Position(path: startNode.path, offset: 0);
    final end = endNode.selectable?.end() ??
        Position(
          path: endNode.path,
          offset: endNode.delta?.length ?? 0,
        );

    editorState.selectionType = SelectionType.block;
    editorState.selection = Selection(
      start: start,
      end: end,
    );
  }

  void _onSelectAction(OptionAction action) {
    final node = blockComponentContext.node;
    final transaction = editorState.transaction;
    switch (action) {
      case OptionAction.delete:
        transaction.deleteNode(node);
        break;
      case OptionAction.duplicate:
        transaction.insertNode(
          node.path.next,
          node.copyWith(),
        );
        break;
      case OptionAction.turnInto:
        break;
      case OptionAction.moveUp:
        transaction.moveNode(node.path.previous, node);
        break;
      case OptionAction.moveDown:
        transaction.moveNode(node.path.next.next, node);
        break;
      case OptionAction.align:
      case OptionAction.color:
      case OptionAction.divider:
        throw UnimplementedError();
    }
    editorState.apply(transaction);
  }
}

class BlockComponentActionButton extends StatelessWidget {
  const BlockComponentActionButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final bool isHovering = false;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onTapDown: (details) {},
        onTapUp: (details) {},
        child: icon,
      ),
    );
  }
}

class OptionActionButton extends StatelessWidget {
  const OptionActionButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: IgnoreParentGestureWidget(
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.deferToChild,
            child: svgWidget(
              'editor/option',
              size: const Size.square(24.0),
              color: Theme.of(context).iconTheme.color,
            ),
          ),
        ),
      ),
    );
  }
}
