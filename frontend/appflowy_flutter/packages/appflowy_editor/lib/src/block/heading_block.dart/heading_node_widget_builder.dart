import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/block/heading_block.dart/heading_block.dart';
import 'package:flutter/material.dart';

class HeadingBlockBuilder extends NodeWidgetBuilder<Node> {
  @override
  Widget build(NodeWidgetContext<Node> context) {
    return HeadingBlock(
      key: context.node.key,
      node: context.node,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => (node) {
        return node.children.isEmpty && node.attributes['heading'] is int;
      };
}
