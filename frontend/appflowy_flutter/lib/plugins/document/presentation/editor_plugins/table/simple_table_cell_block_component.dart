import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_constants.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SimpleTableCellBlockKeys {
  const SimpleTableCellBlockKeys._();

  static const String type = 'simple_table_cell';
}

Node simpleTableCellBlockNode({
  List<Node>? children,
}) {
  // Default children is a paragraph node.
  children ??= [
    paragraphNode(),
  ];

  return Node(
    type: SimpleTableCellBlockKeys.type,
    children: children,
  );
}

class SimpleTableCellBlockComponentBuilder extends BlockComponentBuilder {
  SimpleTableCellBlockComponentBuilder({
    super.configuration,
  });

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return SimpleTableCellBlockWidget(
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
  BlockComponentValidate get validate => (node) => true;
}

class SimpleTableCellBlockWidget extends BlockComponentStatefulWidget {
  const SimpleTableCellBlockWidget({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.configuration = const BlockComponentConfiguration(),
  });

  @override
  State<SimpleTableCellBlockWidget> createState() =>
      _SimpleTableCellBlockWidgetState();
}

class _SimpleTableCellBlockWidgetState extends State<SimpleTableCellBlockWidget>
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
    return DecoratedBox(
      decoration:
          SimpleTableConstants.borderType == SimpleTableBorderRenderType.cell
              ? BoxDecoration(
                  border: Border.all(
                    color: SimpleTableConstants.borderColor,
                    strokeAlign: BorderSide.strokeAlignCenter,
                  ),
                )
              : const BoxDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: node.children
            .map(
              (e) => Container(
                padding: SimpleTableConstants.cellEdgePadding,
                constraints: const BoxConstraints(
                  minWidth: SimpleTableConstants.minimumColumnWidth,
                ),
                width: getColumnWidth(),
                child: IntrinsicWidth(
                  child: IntrinsicHeight(
                    child: editorState.renderer.build(context, e),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  double getColumnWidth() {
    final table = node.parent?.parent;
    if (table == null || table.type != SimpleTableBlockKeys.type) {
      return SimpleTableConstants.defaultColumnWidth;
    }

    try {
      final columnWidths = table.attributes[SimpleTableBlockKeys.columnWidths]
          as SimpleTableColumnWidths?;
      final index = node.parent?.path.last;
      return columnWidths?[index.toString()] ??
          SimpleTableConstants.defaultColumnWidth;
    } catch (e) {
      return SimpleTableConstants.defaultColumnWidth;
    }
  }
}
