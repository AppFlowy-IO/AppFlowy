import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_cell_block_component.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SimpleTableBlockKeys {
  const SimpleTableBlockKeys._();

  static const String type = 'simple_table';

  // enable header row
  // it's a bool value, default is false
  static const String enableHeaderRow = 'enable_header_row';

  // enable column header
  // it's a bool value, default is false
  static const String enableColumnHeader = 'enable_column_header';

  // column colors
  // it's a list of color strings
  // the number of colors should be the same as the number of columns
  static const String columnColors = 'column_colors';

  // row colors
  // it's a list of color strings
  // the number of colors should be the same as the number of rows
  static const String rowColors = 'row_colors';

  // column alignments
  // it's a list of align strings
  // the value should be one of the following: 'left', 'center', 'right'
  // the number of aligns should be the same as the number of columns
  static const String columnAligns = 'column_aligns';

  // row alignments
  // it's a list of align strings
  // the value should be one of the following: 'top', 'center', 'bottom'
  // the number of aligns should be the same as the number of rows
  static const String rowAligns = 'row_aligns';

  // column widths
  // it's a list of double values
  // the number of widths should be the same as the number of columns
  static const String columnWidths = 'column_widths';
}

Node simpleTableBlockNode({
  bool enableHeaderRow = false,
  bool enableColumnHeader = false,
  List<String> columnColors = const [],
  List<String> rowColors = const [],
  List<String> columnAligns = const [],
  List<String> rowAligns = const [],
  List<double> columnWidths = const [],
  List<Node> children = const [],
}) {
  assert(columnColors.length == columnWidths.length);
  assert(rowColors.length == rowAligns.length);
  assert(columnAligns.length == columnWidths.length);
  assert(rowAligns.length == rowColors.length);

  assert(children.every((e) => e.type == SimpleTableCellBlockKeys.type));

  return Node(
    type: SimpleTableBlockKeys.type,
    attributes: {
      SimpleTableBlockKeys.enableHeaderRow: enableHeaderRow,
      SimpleTableBlockKeys.enableColumnHeader: enableColumnHeader,
      SimpleTableBlockKeys.columnColors: columnColors,
      SimpleTableBlockKeys.rowColors: rowColors,
      SimpleTableBlockKeys.columnAligns: columnAligns,
      SimpleTableBlockKeys.rowAligns: rowAligns,
      SimpleTableBlockKeys.columnWidths: columnWidths,
    },
    children: children,
  );
}

class SimpleTableBlockComponentBuilder extends BlockComponentBuilder {
  SimpleTableBlockComponentBuilder({
    super.configuration,
  });

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return SimpleTableBlockWidget(
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
  BlockComponentValidate get validate => (node) => node.children.isEmpty;
}

class SimpleTableBlockWidget extends BlockComponentStatefulWidget {
  const SimpleTableBlockWidget({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.configuration = const BlockComponentConfiguration(),
  });

  @override
  State<SimpleTableBlockWidget> createState() => _SimpleTableBlockWidgetState();
}

class _SimpleTableBlockWidgetState extends State<SimpleTableBlockWidget>
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
    return const SizedBox.shrink();
  }
}
