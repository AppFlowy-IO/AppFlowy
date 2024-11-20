import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SimpleTableRowBlockKeys {
  const SimpleTableRowBlockKeys._();

  static const String type = 'simple_table_row';
}

Node simpleTableRowBlockNode({
  List<Node> children = const [],
}) {
  return Node(
    type: SimpleTableRowBlockKeys.type,
    children: children,
  );
}

class SimpleTableRowBlockComponentBuilder extends BlockComponentBuilder {
  SimpleTableRowBlockComponentBuilder({
    super.configuration,
  });

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return SimpleTableRowBlockWidget(
      key: node.key,
      node: node,
      configuration: configuration,
      showActions: showActions(node),
      actionBuilder: (context, state) => actionBuilder(
        blockComponentContext,
        state,
      ),
    );
  }

  @override
  BlockComponentValidate get validate => (node) => node.children.isNotEmpty;
}

class SimpleTableRowBlockWidget extends BlockComponentStatefulWidget {
  const SimpleTableRowBlockWidget({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.configuration = const BlockComponentConfiguration(),
  });

  @override
  State<SimpleTableRowBlockWidget> createState() =>
      _SimpleTableRowBlockWidgetState();
}

class _SimpleTableRowBlockWidgetState extends State<SimpleTableRowBlockWidget>
    with
        BlockComponentConfigurable,
        BlockComponentTextDirectionMixin,
        BlockComponentBackgroundColorMixin {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  @override
  late EditorState editorState = context.read<EditorState>();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: node.children
          .map((e) => editorState.renderer.build(context, e))
          .toList(),
    );
  }
}
