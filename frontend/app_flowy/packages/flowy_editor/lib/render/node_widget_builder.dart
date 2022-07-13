import 'package:flutter/material.dart';

import '../document/node.dart';
import '../render/render_plugins.dart';

class NodeWidgetBuilder<T extends Node> {
  final T node;
  final RenderPlugins renderPlugins;

  NodeWidgetBuilder.create({required this.node, required this.renderPlugins});

  Widget call(BuildContext buildContext) => build(buildContext);

  /// Render the current [Node]
  /// and the layout style of [Node.Children].
  Widget build(BuildContext buildContext) => throw UnimplementedError();
}
