import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/blocks/text_block/shortcuts/text_block_shortcuts.dart';
import 'package:flutter/material.dart';

class TextBlockBuilder extends NodeWidgetBuilder<TextNode> {
  @override
  Widget build(NodeWidgetContext<TextNode> context) {
    return TextBlock(
      key: context.node.key,
      textNode: context.node,
      shortcuts: textBlockShortcuts,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => (node) {
        return true;
      };
}
