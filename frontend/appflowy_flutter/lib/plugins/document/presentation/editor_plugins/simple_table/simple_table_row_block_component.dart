import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
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
    this.alwaysDistributeColumnWidths = false,
  });

  final bool alwaysDistributeColumnWidths;

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return SimpleTableRowBlockWidget(
      key: node.key,
      node: node,
      configuration: configuration,
      alwaysDistributeColumnWidths: alwaysDistributeColumnWidths,
      showActions: showActions(node),
      actionBuilder: (context, state) => actionBuilder(
        blockComponentContext,
        state,
      ),
    );
  }

  @override
  BlockComponentValidate get validate => (_) => true;
}

class SimpleTableRowBlockWidget extends BlockComponentStatefulWidget {
  const SimpleTableRowBlockWidget({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.configuration = const BlockComponentConfiguration(),
    required this.alwaysDistributeColumnWidths,
  });

  final bool alwaysDistributeColumnWidths;

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
    if (node.children.isEmpty) {
      return const SizedBox.shrink();
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _buildCells(),
      ),
    );
  }

  List<Widget> _buildCells() {
    final List<Widget> cells = [];

    for (var i = 0; i < node.children.length; i++) {
      // border
      if (i == 0 &&
          SimpleTableConstants.borderType ==
              SimpleTableBorderRenderType.table) {
        cells.add(const SimpleTableRowDivider());
      }

      final child = editorState.renderer.build(context, node.children[i]);
      cells.add(
        widget.alwaysDistributeColumnWidths ? Flexible(child: child) : child,
      );

      // border
      if (SimpleTableConstants.borderType ==
          SimpleTableBorderRenderType.table) {
        cells.add(const SimpleTableRowDivider());
      }
    }

    return cells;
  }
}
