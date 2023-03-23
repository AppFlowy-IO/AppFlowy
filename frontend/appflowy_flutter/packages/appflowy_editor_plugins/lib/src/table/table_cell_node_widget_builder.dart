import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/src/table/src/cell_node_widget.dart';
import 'package:flutter/material.dart';

class TableCellNodeWidgetBuilder extends NodeWidgetBuilder<Node> {
  @override
  Widget build(NodeWidgetContext<Node> context) {
    return CellNodeWidget(
      key: context.node.key,
      node: context.node,
      editorState: context.editorState,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => (node) =>
      node.attributes.isNotEmpty &&
      node.attributes.containsKey('position') &&
      node.attributes['position'].containsKey('row') &&
      node.attributes['position'].containsKey('col');
}
