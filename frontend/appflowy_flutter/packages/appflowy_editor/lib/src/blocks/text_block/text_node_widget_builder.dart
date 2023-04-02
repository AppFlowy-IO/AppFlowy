import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/blocks/text_block/shortcuts/text_block_shortcuts.dart';
import 'package:flutter/material.dart';

class TextBlockBuilder extends NodeWidgetBuilder<Node> {
  @override
  Widget build(NodeWidgetContext<Node> context) {
    final node = context.node;
    final delta = Delta.fromJson(List.from(node.attributes['texts']));
    return TextBlock(
      key: context.node.key,
      path: node.path,
      delta: delta,
      shortcuts: textBlockShortcuts,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => (node) {
        return true;
      };
}
