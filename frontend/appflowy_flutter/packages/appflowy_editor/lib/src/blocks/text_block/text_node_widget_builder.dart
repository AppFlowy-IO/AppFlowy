import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/blocks/text_block/shortcuts/backspace.dart';
import 'package:flutter/material.dart';

class TextBlockBuilder extends NodeWidgetBuilder<TextNode> {
  @override
  Widget build(NodeWidgetContext<TextNode> context) {
    return TextBlock(
      key: context.node.key,
      textNode: context.node,
      shortcuts: [
        ShortcutEvent(
          key: 'text_block.backspace',
          command: 'backspace',
          blockShortcutHandler: backspaceHandler,
          handler: (editorState, event) => KeyEventResult.ignored,
        )
      ],
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => (node) {
        return true;
      };
}
