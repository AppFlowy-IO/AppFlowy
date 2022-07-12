import 'package:flutter/widgets.dart';
import '../document/node.dart';
import '../render/base_node_widget.dart';

typedef NodeWidgetBuilder<T extends Node> = BaseNodeWidget Function(
  T node,
  RenderPlugins plugins,
);

// unused
typedef NodeBuilder<T extends Node> = T Function(Node node);

class RenderPlugins {
  Map<String, NodeWidgetBuilder> nodeWidgetBuilders = {};
  // unused
  // Map<String, NodeBuilder> nodeBuilders = {};

  void register(String name, NodeWidgetBuilder builder) {
    nodeWidgetBuilders[name] = builder;
  }

  void unRegister(String name) {
    nodeWidgetBuilders.removeWhere((key, _) => key == name);
  }

  BaseNodeWidget buildWidgetWithNode(Node node) {
    final nodeWidgetBuilder = _nodeWidgetBuilder(node.type);
    return nodeWidgetBuilder(node, this);
  }

  NodeWidgetBuilder _nodeWidgetBuilder(String name) {
    assert(nodeWidgetBuilders.containsKey(name));
    return nodeWidgetBuilders[name]!;
  }
}
