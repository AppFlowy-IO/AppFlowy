import 'package:appflowy/plugins/document/presentation/editor_plugins/table/shared_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_constants.dart';
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
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _buildCells(),
      ),
    );
  }

  List<Widget> _buildCells() {
    final List<Widget> cells = [];

    if (SimpleTableConstants.borderType == SimpleTableBorderRenderType.table) {
      cells.add(const SimpleTableRowDivider());
    }

    for (final child in node.children) {
      cells.add(editorState.renderer.build(context, child));

      if (SimpleTableConstants.borderType ==
          SimpleTableBorderRenderType.table) {
        cells.add(const SimpleTableRowDivider());
      }
    }
    return cells;
  }
}
