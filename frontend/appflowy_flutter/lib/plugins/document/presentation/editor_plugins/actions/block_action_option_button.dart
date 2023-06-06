import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/block_action_button.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/option_action.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

class BlockOptionButton extends StatelessWidget {
  const BlockOptionButton({
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
      switch (e) {
        case OptionAction.divider:
          return DividerOptionAction();
        case OptionAction.color:
          return ColorOptionAction(editorState: editorState);
        case OptionAction.align:
          return AlignOptionAction(editorState: editorState);
        default:
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
      buildChild: (controller) => _buildOptionButton(controller),
    );
  }

  Widget _buildOptionButton(PopoverController controller) {
    return BlockActionButton(
      svgName: 'editor/option',
      richMessage: TextSpan(
        children: [
          TextSpan(
            // todo: customize the color to highlight the text.
            text: LocaleKeys.document_plugins_optionAction_click.tr(),
          ),
          TextSpan(
            text: LocaleKeys.document_plugins_optionAction_toOpenMenu.tr(),
          )
        ],
      ),
      onTap: () {
        controller.show();

        // update selection
        _updateBlockSelection();
      },
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
