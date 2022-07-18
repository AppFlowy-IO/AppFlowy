import 'package:flowy_editor/editor_state.dart';
import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/render/render_plugins.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

typedef NodeValidator<T extends Node> = bool Function(T node);

class NodeWidgetBuilder<T extends Node> {
  final EditorState editorState;
  final T node;

  bool rebuildOnNodeChanged;
  NodeValidator<T>? nodeValidator;

  RenderPlugins get renderPlugins => editorState.renderPlugins;

  NodeWidgetBuilder.create({
    required this.editorState,
    required this.node,
    this.rebuildOnNodeChanged = true,
  });

  /// Render the current [Node]
  /// and the layout style of [Node.Children].
  Widget build(BuildContext buildContext) => throw UnimplementedError();

  Widget call(BuildContext buildContext) {
    /// TODO: Validate the node
    /// if failed, stop call build function,
    ///   return Empty widget, and throw Error.
    if (nodeValidator != null && nodeValidator!(node) != true) {
      throw Exception(
          'Node validate failure, node = { type: ${node.type}, attributes: ${node.attributes} }');
    }

    if (rebuildOnNodeChanged) {
      return _buildNodeChangeNotifier(buildContext);
    } else {
      return build(buildContext);
    }
  }

  Widget _buildNodeChangeNotifier(BuildContext buildContext) {
    return ChangeNotifierProvider.value(
      value: node,
      builder: (_, __) => Consumer<T>(
        builder: ((context, value, child) {
          debugPrint('Node changed, and rebuilding...');
          return build(context);
        }),
      ),
    );
  }
}
