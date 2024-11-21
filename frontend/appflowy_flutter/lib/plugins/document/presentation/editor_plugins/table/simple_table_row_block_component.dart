import 'package:appflowy/plugins/document/presentation/editor_plugins/table/shared_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_constants.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/table_operations.dart';
import 'package:appflowy_backend/log.dart';
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

    for (var i = 0; i < node.children.length; i++) {
      // border
      if (i == 0 &&
          SimpleTableConstants.borderType ==
              SimpleTableBorderRenderType.table) {
        cells.add(const SimpleTableRowDivider());
      }

      cells.add(editorState.renderer.build(context, node.children[i]));

      cells.add(
        _SimpleTableRowResizeHandle(
          node: node.children[i],
        ),
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

class _SimpleTableRowResizeHandle extends StatelessWidget {
  const _SimpleTableRowResizeHandle({
    required this.node,
  });

  final Node node;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        onHorizontalDragStart: (details) {
          Log.info('resize handle dragged start');
        },
        onHorizontalDragEnd: (details) {
          Log.info('resize handle dragged end');
        },
        onHorizontalDragUpdate: (details) {
          final dx = details.delta.dx;
          Log.info(
            'resize handle dragged update, dx: $dx',
          );

          final cellPosition = node.cellPosition;
          final rowIndex = cellPosition.$2;
          final parentTableNode = node.parentTableNode;
          if (parentTableNode != null) {
            final previousWidth =
                parentTableNode.attributes[SimpleTableBlockKeys.columnWidths]
                        [rowIndex.toString()] as double? ??
                    SimpleTableConstants.defaultColumnWidth;
            final newAttributes = {
              ...parentTableNode.attributes,
              SimpleTableBlockKeys.columnWidths: {
                ...parentTableNode
                    .attributes[SimpleTableBlockKeys.columnWidths],
                rowIndex.toString(): previousWidth + dx,
              },
            };

            parentTableNode.updateAttributes(newAttributes);
          }
        },
        child: Container(
          height: double.infinity,
          width: 2,
          color: Colors.red,
        ),
      ),
    );
  }
}
