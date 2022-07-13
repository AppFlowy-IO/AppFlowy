import 'package:flutter/material.dart';
import '../document/node.dart';
import './node_widget_builder.dart';
import 'package:flowy_editor/editor_state.dart';

class NodeWidgetContext {
  final BuildContext buildContext;
  final Node node;
  final EditorState editorState;

  NodeWidgetContext({
    required this.buildContext,
    required this.node,
    required this.editorState,
  });
}

typedef NodeWidgetBuilderF<T extends Node, A extends NodeWidgetBuilder> = A
    Function({
  required T node,
  required EditorState editorState,
});

// unused
// typedef NodeBuilder<T extends Node> = T Function(Node node);

class RenderPlugins {
  final Map<String, NodeWidgetBuilderF> _nodeWidgetBuilders = {};
  // unused
  // Map<String, NodeBuilder> nodeBuilders = {};

  /// Register plugin to render specified [name].
  ///
  /// [name] should be [Node].type
  ///   or [Node].type + '/' + [Node].attributes['subtype'].
  ///
  /// e.g. 'text', 'text/with-checkbox', or 'text/with-heading'
  ///
  /// [name] could be empty.
  void register(String name, NodeWidgetBuilderF builder) {
    _validatePluginName(name);

    _nodeWidgetBuilders[name] = builder;
  }

  /// UnRegister plugin with specified [name].
  void unRegister(String name) {
    _validatePluginName(name);

    _nodeWidgetBuilders.removeWhere((key, _) => key == name);
  }

  Widget buildWidget({
    required NodeWidgetContext context,
    bool withSubtype = true,
  }) {
    /// Find node widget builder
    /// 1. If node's attributes contains subtype, return.
    /// 2. If node's attributes do no contains substype, return.
    final node = context.node;
    var name = node.type;
    if (withSubtype && node.subtype != null) {
      name += '/${node.subtype}';
    }
    final nodeWidgetBuilder = _nodeWidgetBuilder(name);
    return nodeWidgetBuilder(
      node: context.node,
      editorState: context.editorState,
    )(context.buildContext);
  }

  NodeWidgetBuilderF _nodeWidgetBuilder(String name) {
    assert(_nodeWidgetBuilders.containsKey(name),
        'Could not query the builder with this $name');
    return _nodeWidgetBuilders[name]!;
  }

  void _validatePluginName(String name) {
    final paths = name.split('/');
    if (paths.length > 2) {
      throw Exception('[Name] must contains zero or one slash("/")');
    }
  }
}
