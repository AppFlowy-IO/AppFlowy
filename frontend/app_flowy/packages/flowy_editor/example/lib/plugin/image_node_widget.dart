import 'package:flowy_editor/flowy_editor.dart';
import 'package:flutter/material.dart';

class ImageNodeBuilder extends NodeWidgetBuilder {
  ImageNodeBuilder.create({required super.node, required super.renderPlugins})
      : super.create();

  String get src => node.attributes['image_src'] as String;

  @override
  Widget build(BuildContext buildContext) {
    final image = Image.network(src);
    Widget? children;
    if (node.children.isNotEmpty) {
      children = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: node.children
            .map(
              (e) => renderPlugins.buildWidget(
                NodeWidgetContext(buildContext: buildContext, node: e),
              ),
            )
            .toList(),
      );
    }
    if (children != null) {
      return Column(
        children: [
          image,
          children,
        ],
      );
    } else {
      return image;
    }
  }
}
