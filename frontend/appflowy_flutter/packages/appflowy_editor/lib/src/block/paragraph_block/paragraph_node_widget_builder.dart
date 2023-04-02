import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/block/paragraph_block/paragraph_block.dart';
import 'package:flutter/material.dart';

class ParagraphBlockBuilder extends NodeWidgetBuilder<Node> {
  @override
  Widget build(NodeWidgetContext<Node> context) {
    final node = context.node;
    return ParagraphBlock(
      key: context.node.key,
      node: node,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => (node) {
        return true;
      };
}
