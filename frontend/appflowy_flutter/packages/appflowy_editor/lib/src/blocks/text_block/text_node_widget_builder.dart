import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class TextBlockBuilder extends NodeWidgetBuilder<TextNode> {
  @override
  Widget build(NodeWidgetContext<TextNode> context) {
    return TextBlock(
      key: context.node.key,
      textNode: context.node,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => (node) {
        return true;
      };
}
