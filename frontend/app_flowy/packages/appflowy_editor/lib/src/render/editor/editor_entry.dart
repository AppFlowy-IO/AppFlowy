import 'package:flutter/material.dart';

import 'package:appflowy_editor/src/document/node.dart';
import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/service/render_plugin_service.dart';

class EditorEntryWidgetBuilder extends NodeWidgetBuilder<Node> {
  @override
  Widget build(NodeWidgetContext context) {
    return EditorNodeWidget(
      key: context.node.key,
      node: context.node,
      editorState: context.editorState,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => ((node) {
        return node.type == 'editor';
      });
}

class EditorNodeWidget extends StatelessWidget {
  const EditorNodeWidget({
    Key? key,
    required this.node,
    required this.editorState,
  }) : super(key: key);

  final Node node;
  final EditorState editorState;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: node.children
          .map(
            (child) =>
                editorState.service.renderPluginService.buildPluginWidget(
              child is TextNode
                  ? NodeWidgetContext<TextNode>(
                      context: context,
                      node: child,
                      editorState: editorState,
                    )
                  : NodeWidgetContext<Node>(
                      context: context,
                      node: child,
                      editorState: editorState,
                    ),
            ),
          )
          .toList(),
    );
  }
}
