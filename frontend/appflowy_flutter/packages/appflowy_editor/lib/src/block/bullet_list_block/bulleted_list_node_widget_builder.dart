import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/block/bullet_list_block/bulleted_list_block.dart';
import 'package:flutter/material.dart';

class BulletedListBlockBuilder extends NodeWidgetBuilder<Node> {
  @override
  Widget build(NodeWidgetContext<Node> context) {
    return BulletedListBlock(
      key: context.node.key,
      node: context.node,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => (node) {
        return true;
      };
}
