import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/block_action_button.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class BlockAddButton extends StatelessWidget {
  const BlockAddButton({
    Key? key,
    required this.blockComponentContext,
    required this.blockComponentState,
    required this.editorState,
    required this.showSlashMenu,
  }) : super(key: key);

  final BlockComponentContext blockComponentContext;
  final BlockComponentActionState blockComponentState;

  final EditorState editorState;
  final VoidCallback showSlashMenu;

  @override
  Widget build(BuildContext context) {
    return BlockActionButton(
      svgName: 'editor/add',
      richMessage: const TextSpan(
        children: [
          TextSpan(
            // todo: l10n.
            text: 'Click to add below',
          ),
        ],
      ),
      onTap: () {
        final transaction = editorState.transaction;
        // if the current block is not a empty paragraph block, then insert a new block below the current block.
        final node = blockComponentContext.node;
        if (node.type != ParagraphBlockKeys.type ||
            (node.delta?.isNotEmpty ?? true)) {
          transaction.insertNode(node.path.next, paragraphNode());
          transaction.afterSelection = Selection.collapse(node.path.next, 0);
        } else {
          transaction.afterSelection = Selection.collapse(node.path, 0);
        }
        // show the slash menu.
        editorState.apply(transaction).then(
              (_) => WidgetsBinding.instance.addPostFrameCallback(
                (_) => showSlashMenu(),
              ),
            );
      },
    );
  }
}
