import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/option_action.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra/image.dart';
import 'package:flutter/material.dart';

class OptionActionList extends StatelessWidget {
  const OptionActionList({
    Key? key,
    required this.blockComponentContext,
    required this.blockComponentState,
    required this.editorState,
  }) : super(key: key);

  final BlockComponentContext blockComponentContext;
  final BlockComponentState blockComponentState;
  final EditorState editorState;

  @override
  Widget build(BuildContext context) {
    final actions = [
      OptionAction.delete,
      OptionAction.duplicate,
      OptionAction.turnInto,
      OptionAction.divider,
      OptionAction.moveUp,
      OptionAction.moveDown,
      OptionAction.divider,
      OptionAction.color,
    ]
        .map(
          (e) => e == OptionAction.divider
              ? DividerOptionAction()
              : OptionActionWrapper(e),
        )
        .toList();

    return PopoverActionList<PopoverAction>(
      direction: PopoverDirection.leftWithCenterAligned,
      offset: const Offset(0, 0),
      actions: actions,
      onPopupBuilder: () => blockComponentState.alwaysShowActions = true,
      onClosed: () {
        editorState.selectionType = null;
        editorState.selection = null;
        blockComponentState.alwaysShowActions = false;
      },
      onSelected: (action, controller) {
        if (action is OptionActionWrapper) {
          _onSelectAction(action.inner);
        }

        controller.close();
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
    switch (action) {
      case OptionAction.delete:
        final node = blockComponentContext.node;
        final transaction = editorState.transaction..deleteNode(node);
        editorState.apply(transaction);
        break;
      case OptionAction.duplicate:
        break;
      case OptionAction.turnInto:
        break;
      case OptionAction.moveUp:
        break;
      case OptionAction.moveDown:
        break;
      case OptionAction.color:
        break;
      case OptionAction.divider:
        throw UnimplementedError();
    }
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
      child: GestureDetector(
        onTap: onTap,
        child: svgWidget(
          'editor/option',
          size: const Size.square(24.0),
          color: Theme.of(context).iconTheme.color,
        ),
      ),
    );
  }
}
