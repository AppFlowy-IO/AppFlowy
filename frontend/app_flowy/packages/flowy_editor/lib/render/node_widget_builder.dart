import 'package:flowy_editor/editor_state.dart';
import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/render/render_plugins.dart';
import 'package:flutter/material.dart';

class NodeWidgetBuilder<T extends Node> {
  final EditorState editorState;
  final T node;

  RenderPlugins get renderPlugins => editorState.renderPlugins;

  NodeWidgetBuilder.create({
    required this.editorState,
    required this.node,
  });

  /// Render the current [Node]
  /// and the layout style of [Node.Children].
  Widget build(BuildContext buildContext) => throw UnimplementedError();

  Widget call(BuildContext buildContext) => build(buildContext);
}
