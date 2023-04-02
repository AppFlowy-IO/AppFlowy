import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/block/quote_block/quote_block.dart';
import 'package:flutter/material.dart';

class QuoteBlockBuilder extends NodeWidgetBuilder<Node> {
  @override
  Widget build(NodeWidgetContext<Node> context) {
    return QuoteBlock(
      key: context.node.key,
      node: context.node,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => (node) {
        return node.children.isEmpty && node.attributes['texts'] is List;
      };
}
