import 'package:flutter/material.dart';
import '../document/node.dart';
import 'node_widget_builder.dart';

typedef NodeWidgetBuilderF<T extends Node, A extends NodeWidgetBuilder> = A
    Function({
  required T node,
  required RenderPlugins renderPlugins,
});

// unused
// typedef NodeBuilder<T extends Node> = T Function(Node node);

class RenderPlugins {
  Map<String, NodeWidgetBuilderF> nodeWidgetBuilders = {};
  // unused
  // Map<String, NodeBuilder> nodeBuilders = {};

  void register(String name, NodeWidgetBuilderF builder) {
    nodeWidgetBuilders[name] = builder;
  }

  void unRegister(String name) {
    nodeWidgetBuilders.removeWhere((key, _) => key == name);
  }

  Widget buildWidgetWithNode(Node node) {
    final nodeWidgetBuilder = _nodeWidgetBuilder(node.type);
    return nodeWidgetBuilder(node: node, renderPlugins: this)();
  }

  NodeWidgetBuilderF _nodeWidgetBuilder(String name) {
    assert(nodeWidgetBuilders.containsKey(name));
    return nodeWidgetBuilders[name]!;
  }
}
