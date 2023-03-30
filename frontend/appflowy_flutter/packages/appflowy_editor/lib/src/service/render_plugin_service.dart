import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/render/selection/v2/selection_wrapper.dart';
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

  /// Returns a [NodeWidgetBuilder], if one has been registered for [name]
  NodeWidgetBuilder? getBuilder(String name);

  Widget buildPluginWidget(NodeWidgetContext context);

  List<Widget> buildPluginWidgets(
    BuildContext context,
    List<Node> nodes,
    EditorState editorState,
  ) {
    return nodes
        .map(
          (child) => buildPluginWidget(
            child is TextNode
                ? NodeWidgetContext<TextNode>(
                    context: context,
                    node: child,
                    editorState: editorState,
                  )
                : NodeWidgetContext<Node>(
                    context: context,
                    node: child,
                    editorState: editorState,
                  ),
          ),
        )
        .toList(growable: false);
  }
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
  final Positioned Function(BuildContext context, List<ActionMenuItem> items)?
      customActionMenuBuilder;

  AppFlowyRenderPlugin({
    required this.editorState,
    required NodeWidgetBuilders builders,
    this.customActionMenuBuilder,
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
      return _autoUpdateNodeWidget(builder, context);
    } else {
      // Returns a SizeBox with 0 height if no builder found.
      assert(
        false,
        'No builder found for node(${node.id}, attributes(${node.attributes})})',
      );
      return SizedBox(
        key: node.key,
        height: 0,
      );
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

  @override
  NodeWidgetBuilder? getBuilder(String name) {
    return _builders[name];
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
                return _buildWithActions(builder, context);
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
                return _buildWithActions(builder, context);
              }),
            );
          });
    }
    return CompositedTransformTarget(
      link: context.node.layerLink,
      child: notifier,
    );
  }

  Widget _buildWithActions(
      NodeWidgetBuilder builder, NodeWidgetContext context) {
    final visibleNodes =
        Provider.of<EditorState>(context.context, listen: false)
            .service
            .selectionServiceV2
            .visibleNodes;
    final child = SelectionWrapper(
      onCreate: () => visibleNodes.add(context.node),
      onDispose: () => visibleNodes.remove(context.node),
      child: builder.build(context),
    );
    if (builder is ActionProvider) {
      return ChangeNotifierProvider(
        create: (_) => ActionMenuState(context.node.path),
        child: ActionMenuOverlay(
          items: builder.actions(context),
          customActionMenuBuilder: customActionMenuBuilder,
          child: child,
        ),
      );
    } else {
      return child;
    }
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
