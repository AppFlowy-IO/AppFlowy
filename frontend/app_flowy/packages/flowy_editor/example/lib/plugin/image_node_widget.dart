import 'package:flowy_editor/flowy_editor.dart';
import 'package:flutter/material.dart';

class ImageNodeBuilder extends NodeWidgetBuilder {
  ImageNodeBuilder.create({
    required super.node,
    required super.editorState,
  }) : super.create();

  @override
  Widget build(BuildContext buildContext) {
    return _ImageNodeWidget(
      node: node,
      editorState: editorState,
    );
  }
}

class _ImageNodeWidget extends StatelessWidget {
  final Node node;
  final EditorState editorState;

  const _ImageNodeWidget({
    Key? key,
    required this.node,
    required this.editorState,
  }) : super(key: key);

  String get src => node.attributes['image_src'] as String;

  @override
  Widget build(BuildContext context) {
    return _build(context);
  }

  Widget _build(BuildContext context) {
    return Column(
      children: [
        Image.network(src),
        if (node.children.isNotEmpty)
          Column(
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
      ],
    );
  }
}
