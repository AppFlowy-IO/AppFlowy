import 'package:flowy_editor/flowy_editor.dart';
import 'package:flutter/material.dart';

NodeWidgetBuilder<Node> imageNodeWidgetBuilder =
    (node, renderPlugins) => ImageNodeWidget(
          node: node,
          renderPlugins: renderPlugins,
        );

class ImageNodeWidget extends BaseNodeWidget {
  const ImageNodeWidget({
    super.key,
    required super.node,
    required super.renderPlugins,
  });

  @override
  State<ImageNodeWidget> createState() => _ImageNodeWidgetState();
}

class _ImageNodeWidgetState extends State<ImageNodeWidget> {
  Node get node => widget.node;
  String get src => node.attributes['image_src'] as String;

  @override
  Widget build(BuildContext context) {
    final childWidget = renderChildren();
    final image = Image.network(src);
    if (childWidget != null) {
      return Column(
        children: [image, childWidget],
      );
    } else {
      return image;
    }
  }

  // manage children's render
  Widget? renderChildren() {
    if (node.children.isEmpty) {
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: node.children
          .map(
            (e) => widget.renderPlugins.buildWidgetWithNode(
              e,
            ),
          )
          .toList(),
    );
  }
}
