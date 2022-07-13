import 'package:flutter/material.dart';
import '../document/node.dart';
import 'node_widget_builder.dart';

class NodeWidgetContext {
  BuildContext buildContext;
  Node node;
  NodeWidgetContext({required this.buildContext, required this.node});
}

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

  /// register plugin to render specified [name].
  /// [name] should be correspond to the [type] in [Node].
  /// [name] could be empty.
  void register(String name, NodeWidgetBuilderF builder) {
    nodeWidgetBuilders[name] = builder;
  }

  /// unRegister plugin with specified [name].
  void unRegister(String name) {
    nodeWidgetBuilders.removeWhere((key, _) => key == name);
  }

  Widget buildWidget(NodeWidgetContext context) {
    final nodeWidgetBuilder = _nodeWidgetBuilder(context.node.type);
    return nodeWidgetBuilder(node: context.node, renderPlugins: this)(
        context.buildContext);
  }

  NodeWidgetBuilderF _nodeWidgetBuilder(String name) {
    assert(nodeWidgetBuilders.containsKey(name),
        'Could not query the builder with this $name');
    return nodeWidgetBuilders[name]!;
  }
}
