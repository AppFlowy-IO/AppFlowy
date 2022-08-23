import 'package:appflowy_editor/src/document/node.dart';
import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/infra/log.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

typedef NodeValidator<T extends Node> = bool Function(T node);

abstract class NodeWidgetBuilder<T extends Node> {
  NodeValidator get nodeValidator;

  Widget build(NodeWidgetContext<T> context);
}

typedef NodeWidgetBuilders = Map<String, NodeWidgetBuilder>;

abstract class AppFlowyRenderPluginService {
  /// Register render plugin with specified [name].
  ///
  /// [name] should be [Node].type
  ///   or `[Node].type + '/' + [Node].attributes['subtype']`.
  ///
  /// e.g. 'text', 'text/checkbox', or 'text/heading'
  ///
  /// [name] could be empty.
  void register(String name, NodeWidgetBuilder builder);
  void registerAll(Map<String, NodeWidgetBuilder> builders);

  /// UnRegister plugin with specified [name].
  void unRegister(String name);

  Widget buildPluginWidget(NodeWidgetContext context);
}

class NodeWidgetContext<T extends Node> {
  final BuildContext context;
  final T node;
  final EditorState editorState;

  NodeWidgetContext({
    required this.context,
    required this.node,
    required this.editorState,
  });

  NodeWidgetContext copyWith({
    BuildContext? context,
    T? node,
    EditorState? editorState,
  }) {
    return NodeWidgetContext(
      context: context ?? this.context,
      node: node ?? this.node,
      editorState: editorState ?? this.editorState,
    );
  }
}

class AppFlowyRenderPlugin extends AppFlowyRenderPluginService {
  AppFlowyRenderPlugin({
    required this.editorState,
    required NodeWidgetBuilders builders,
  }) {
    registerAll(builders);
  }

  final NodeWidgetBuilders _builders = {};
  final EditorState editorState;

  @override
  Widget buildPluginWidget(NodeWidgetContext context) {
    final node = context.node;
    final name =
        node.subtype == null ? node.type : '${node.type}/${node.subtype!}';
    final builder = _builders[name];
    if (builder != null && builder.nodeValidator(node)) {
      final key = GlobalKey(debugLabel: name);
      node.key = key;
      return _autoUpdateNodeWidget(builder, context);
    } else {
      assert(false,
          'Could not query the builder with this $name, or nodeValidator return false.');
      // TODO: return a placeholder widget with tips.
      return Container();
    }
  }

  @override
  void register(String name, NodeWidgetBuilder builder) {
    Log.editor.info('registers plugin($name)...');
    _validatePlugin(name);
    _builders[name] = builder;
  }

  @override
  void registerAll(Map<String, NodeWidgetBuilder> builders) {
    builders.forEach(register);
  }

  @override
  void unRegister(String name) {
    _validatePlugin(name);
    _builders.remove(name);
  }

  Widget _autoUpdateNodeWidget(
      NodeWidgetBuilder builder, NodeWidgetContext context) {
    Widget notifier;
    if (context.node is TextNode) {
      notifier = ChangeNotifierProvider.value(
          value: context.node as TextNode,
          builder: (_, child) {
            return Consumer<TextNode>(
              builder: ((_, value, child) {
                Log.ui.debug('TextNode is rebuilding...');
                return builder.build(context);
              }),
            );
          });
    } else {
      notifier = ChangeNotifierProvider.value(
          value: context.node,
          builder: (_, child) {
            return Consumer<Node>(
              builder: ((_, value, child) {
                Log.ui.debug('Node is rebuilding...');
                return builder.build(context);
              }),
            );
          });
    }
    return CompositedTransformTarget(
      link: context.node.layerLink,
      child: notifier,
    );
  }

  void _validatePlugin(String name) {
    final paths = name.split('/');
    if (paths.length > 2) {
      throw Exception('Plugin name must contain at most one or zero slash');
    }
    if (_builders.containsKey(name)) {
      throw Exception('Plugin name($name) already exists.');
    }
  }
}
