import 'package:flutter/material.dart';
import '../document/node.dart';
import '../render/render_plugins.dart';

class BaseNodeWidget<T extends Node> extends StatefulWidget {
  final T node;
  final RenderPlugins renderPlugins;

  const BaseNodeWidget({
    Key? key,
    required this.node,
    required this.renderPlugins,
  }) : super(key: key);

  @override
  State<BaseNodeWidget> createState() => _BaseNodeWidgetState();
}

class _BaseNodeWidgetState extends State<BaseNodeWidget> {
  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }
}
