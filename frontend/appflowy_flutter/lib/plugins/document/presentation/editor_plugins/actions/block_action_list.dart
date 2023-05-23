import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/block_action_add_button.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/block_action_option_button.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/option_action.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

class BlockActionList extends StatelessWidget {
  const BlockActionList({
    super.key,
    required this.blockComponentContext,
    required this.blockComponentState,
    required this.editorState,
    required this.actions,
    required this.showSlashMenu,
  });

  final BlockComponentContext blockComponentContext;
  final BlockComponentActionState blockComponentState;
  final List<OptionAction> actions;
  final VoidCallback showSlashMenu;
  final EditorState editorState;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        BlockAddButton(
          blockComponentContext: blockComponentContext,
          blockComponentState: blockComponentState,
          editorState: editorState,
          showSlashMenu: showSlashMenu,
        ),
        const SizedBox(width: 8.0),
        BlockOptionButton(
          blockComponentContext: blockComponentContext,
          blockComponentState: blockComponentState,
          actions: actions,
          editorState: editorState,
        ),
        const SizedBox(width: 6.0),
      ],
    );
  }
}
