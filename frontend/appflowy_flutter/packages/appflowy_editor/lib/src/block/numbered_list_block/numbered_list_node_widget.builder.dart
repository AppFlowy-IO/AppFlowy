import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/block/numbered_list_block/numbered_list_block.dart';
import 'package:flutter/material.dart';

class NumberedListBlockBuilder extends NodeWidgetBuilder<Node> {
  @override
  Widget build(NodeWidgetContext<Node> context) {
    return NumberedListBlock(
      key: context.node.key,
      node: context.node,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => (node) {
        return true;
      };
}
