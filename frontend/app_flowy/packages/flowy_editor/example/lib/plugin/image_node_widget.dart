import 'package:flowy_editor/flowy_editor.dart';
import 'package:flutter/material.dart';

class ImageNodeBuilder extends NodeWidgetBuilder {
  ImageNodeBuilder.create({required super.node, required super.renderPlugins})
      : super.create();

  String get src => node.attributes['image_src'] as String;

  @override
  Widget build() {
    final childrenWidget = buildChildren();
    final image = Image.network(src);
    if (childrenWidget != null) {
      return Column(
        children: [
          image,
          childrenWidget,
        ],
      );
    } else {
      return image;
    }
  }
}
