import 'package:flutter/material.dart';

import '../document/node.dart';
import '../render/render_plugins.dart';

class NodeWidgetBuilder<T extends Node> {
  final T node;
  final RenderPlugins renderPlugins;

  NodeWidgetBuilder.create({required this.node, required this.renderPlugins});

  Widget call() => build();
  Widget build() => throw UnimplementedError();
  Widget? buildChildren() {
    if (node.children.isEmpty) {
      return null;
    }

    // default layout
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: node.children
          .map(
            (e) => renderPlugins.buildWidgetWithNode(e),
          )
          .toList(),
    );
  }
}
