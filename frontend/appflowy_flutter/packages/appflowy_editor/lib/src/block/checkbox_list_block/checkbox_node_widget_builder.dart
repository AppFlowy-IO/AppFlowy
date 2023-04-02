import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/block/checkbox_list_block/checkbox_block.dart';
import 'package:flutter/material.dart';

class CheckboxBlockBuilder extends NodeWidgetBuilder<Node> {
  @override
  Widget build(NodeWidgetContext<Node> context) {
    return CheckboxBlock(
      key: context.node.key,
      node: context.node,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => (node) {
        return true;
      };
}
