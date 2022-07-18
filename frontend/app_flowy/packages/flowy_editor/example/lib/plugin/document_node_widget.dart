import 'package:flowy_editor/flowy_editor.dart';
import 'package:flutter/material.dart';

class EditorNodeWidgetBuilder extends NodeWidgetBuilder {
  EditorNodeWidgetBuilder.create({
    required super.editorState,
    required super.node,
  }) : super.create();

  @override
  Widget build(BuildContext buildContext) {
    return SingleChildScrollView(
      child: _EditorNodeWidget(
        node: node,
        editorState: editorState,
      ),
    );
  }
}

class _EditorNodeWidget extends StatelessWidget {
  final Node node;
  final EditorState editorState;

  const _EditorNodeWidget({
    Key? key,
    required this.node,
    required this.editorState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: node.children
            .map(
              (e) => editorState.renderPlugins.buildWidget(
                context: NodeWidgetContext(
                  buildContext: context,
                  node: e,
                  editorState: editorState,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
