import 'package:appflowy/plugins/document/presentation/editor_plugins/table/shared_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_cell_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_constants.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_row_block_component.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

typedef SimpleTableColumnWidthMap = Map<String, double>;
typedef SimpleTableRowAlignMap = Map<String, String>;
typedef SimpleTableColumnAlignMap = Map<String, String>;
typedef SimpleTableColorMap = Map<String, String>;

// enable the debug border, the table will highlight with different background.
bool _enableTableDebugBorder = false;

class SimpleTableBlockKeys {
  const SimpleTableBlockKeys._();

  static const String type = 'simple_table';

  // enable header row
  // it's a bool value, default is false
  static const String enableHeaderRow = 'enable_header_row';

  // enable column header
  // it's a bool value, default is false
  static const String enableHeaderColumn = 'enable_header_column';

  // column colors
  // it's a `SimpleTableColorMap` value, {column_index: color, ...}
  // the number of colors should be the same as the number of columns
  static const String columnColors = 'column_colors';

  // row colors
  // it's a `SimpleTableColorMap` value, {row_index: color, ...}
  // the number of colors should be the same as the number of rows
  static const String rowColors = 'row_colors';

  // column alignments
  // it's a `SimpleTableColumnAlignMap` value, {column_index: align, ...}
  // the value should be one of the following: 'left', 'center', 'right'
  static const String columnAligns = 'column_aligns';

  // row alignments
  // it's a `SimpleTableRowAlignMap` value, {row_index: align, ...}
  // the value should be one of the following: 'top', 'center', 'bottom'
  static const String rowAligns = 'row_aligns';

  // column widths
  // it's a `SimpleTableColumnWidthMap` value, {column_index: width, ...}
  static const String columnWidths = 'column_widths';
}

Node simpleTableBlockNode({
  bool enableHeaderRow = false,
  bool enableHeaderColumn = false,
  SimpleTableColorMap? columnColors,
  SimpleTableColorMap? rowColors,
  SimpleTableColumnAlignMap? columnAligns,
  SimpleTableRowAlignMap? rowAligns,
  SimpleTableColumnWidthMap? columnWidths,
  required List<Node> children,
}) {
  assert(children.every((e) => e.type == SimpleTableRowBlockKeys.type));

  return Node(
    type: SimpleTableBlockKeys.type,
    attributes: {
      SimpleTableBlockKeys.enableHeaderRow: enableHeaderRow,
      SimpleTableBlockKeys.enableHeaderColumn: enableHeaderColumn,
      SimpleTableBlockKeys.columnColors: columnColors,
      SimpleTableBlockKeys.rowColors: rowColors,
      SimpleTableBlockKeys.columnAligns: columnAligns,
      SimpleTableBlockKeys.rowAligns: rowAligns,
      SimpleTableBlockKeys.columnWidths: columnWidths,
    },
    children: children,
  );
}

/// Create a simple table block node with the given column and row count.
///
/// The table will have cells filled with paragraph nodes.
///
/// For example, if you want to create a table with 2 columns and 3 rows, you can use:
/// ```dart
/// final table = createSimpleTableBlockNode(columnCount: 2, rowCount: 3);
/// ```
///
/// | cell 1 | cell 2 |
/// | cell 3 | cell 4 |
/// | cell 5 | cell 6 |
Node createSimpleTableBlockNode({
  required int columnCount,
  required int rowCount,
  String? defaultContent,
}) {
  final rows = List.generate(rowCount, (_) {
    final cells = List.generate(
      columnCount,
      (_) => simpleTableCellBlockNode(
        children: [paragraphNode(text: defaultContent)],
      ),
    );
    return simpleTableRowBlockNode(children: cells);
  });

  return simpleTableBlockNode(children: rows);
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
  BlockComponentValidate get validate => (node) => node.children.isNotEmpty;
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
        SelectableMixin,
        BlockComponentConfigurable,
        BlockComponentTextDirectionMixin,
        BlockComponentBackgroundColorMixin {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  @override
  late EditorState editorState = context.read<EditorState>();

  final tableKey = GlobalKey();

  final simpleTableContext = SimpleTableContext();
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    editorState.selectionNotifier.addListener(_onSelectionChanged);
  }

  @override
  void dispose() {
    simpleTableContext.dispose();
    editorState.selectionNotifier.removeListener(_onSelectionChanged);
    scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Transform.translate(
      offset: const Offset(
        -SimpleTableConstants.tableLeftPadding,
        0,
      ),
      child: _buildTable(),
    );

    child = Container(
      alignment: Alignment.topLeft,
      padding: padding,
      child: child,
    );

    if (widget.showActions && widget.actionBuilder != null) {
      child = BlockComponentActionWrapper(
        node: node,
        actionBuilder: widget.actionBuilder!,
        child: child,
      );
    }

    return child;
  }

  Widget _buildTable() {
    // IntrinsicWidth and IntrinsicHeight are used to make the table size fit the content.
    return Provider.value(
      value: simpleTableContext,
      child: MouseRegion(
        onEnter: (event) => simpleTableContext.isHoveringOnTable.value = true,
        onExit: (event) {
          simpleTableContext.isHoveringOnTable.value = false;
          simpleTableContext.hoveringTableCell.value = null;
        },
        child: Stack(
          children: [
            Scrollbar(
              controller: scrollController,
              child: SingleChildScrollView(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: SimpleTableConstants.tablePadding,
                  child: IntrinsicWidth(
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildRows(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SimpleTableAddColumnHoverButton(
              editorState: editorState,
              node: node,
            ),
            SimpleTableAddRowHoverButton(
              editorState: editorState,
              tableNode: node,
            ),
            SimpleTableAddColumnAndRowHoverButton(
              editorState: editorState,
              node: node,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRows() {
    final List<Widget> rows = [];

    if (SimpleTableConstants.borderType == SimpleTableBorderRenderType.table) {
      rows.add(const SimpleTableColumnDivider());
    }

    for (final child in node.children) {
      rows.add(editorState.renderer.build(context, child));

      if (SimpleTableConstants.borderType ==
          SimpleTableBorderRenderType.table) {
        rows.add(const SimpleTableColumnDivider());
      }
    }

    return rows;
  }

  void _onSelectionChanged() {
    final selection = editorState.selectionNotifier.value;
    final selectionType = editorState.selectionType;
    if (selectionType == SelectionType.block &&
        widget.node.path.inSelection(selection)) {
      simpleTableContext.isSelectingTable.value = true;
    } else {
      simpleTableContext.isSelectingTable.value = false;
    }
  }

  RenderBox get _renderBox => context.findRenderObject() as RenderBox;

  @override
  Position start() => Position(path: widget.node.path);

  @override
  Position end() => Position(path: widget.node.path, offset: 1);

  @override
  Position getPositionInOffset(Offset start) => end();

  @override
  List<Rect> getRectsInSelection(
    Selection selection, {
    bool shiftWithBaseOffset = false,
  }) {
    final parentBox = context.findRenderObject();
    final tableBox = tableKey.currentContext?.findRenderObject();
    if (parentBox is RenderBox && tableBox is RenderBox) {
      return [
        (shiftWithBaseOffset
                ? tableBox.localToGlobal(Offset.zero, ancestor: parentBox)
                : Offset.zero) &
            tableBox.size,
      ];
    }
    return [Offset.zero & _renderBox.size];
  }

  @override
  Selection getSelectionInRange(Offset start, Offset end) => Selection.single(
        path: widget.node.path,
        startOffset: 0,
        endOffset: 1,
      );

  @override
  bool get shouldCursorBlink => false;

  @override
  CursorStyle get cursorStyle => CursorStyle.cover;

  @override
  Offset localToGlobal(
    Offset offset, {
    bool shiftWithBaseOffset = false,
  }) =>
      _renderBox.localToGlobal(offset);

  @override
  Rect getBlockRect({
    bool shiftWithBaseOffset = false,
  }) {
    return getRectsInSelection(Selection.invalid()).first;
  }

  @override
  Rect? getCursorRectInPosition(
    Position position, {
    bool shiftWithBaseOffset = false,
  }) {
    final size = _renderBox.size;
    return Rect.fromLTWH(-size.width / 2.0, 0, size.width, size.height);
  }
}
