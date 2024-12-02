import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/_shared_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
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
      SimpleTableCellBlockWidgetState();
}

@visibleForTesting
class SimpleTableCellBlockWidgetState extends State<SimpleTableCellBlockWidget>
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

  late SimpleTableContext? simpleTableContext =
      context.read<SimpleTableContext?>();

  ValueNotifier<bool> isEditingCellNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

    simpleTableContext?.isSelectingTable.addListener(_onSelectingTableChanged);
    node.parentTableNode?.addListener(_onSelectingTableChanged);
    editorState.selectionNotifier.addListener(_onSelectionChanged);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _onSelectionChanged();
    });
  }

  @override
  void dispose() {
    simpleTableContext?.isSelectingTable.removeListener(
      _onSelectingTableChanged,
    );
    node.parentTableNode?.removeListener(_onSelectingTableChanged);
    editorState.selectionNotifier.removeListener(_onSelectionChanged);
    isEditingCellNotifier.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (simpleTableContext == null) {
      return const SizedBox.shrink();
    }

    return MouseRegion(
      hitTestBehavior: HitTestBehavior.opaque,
      onEnter: (event) => simpleTableContext!.hoveringTableCell.value = node,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildCell(),
          Positioned(
            top: 0,
            bottom: 0,
            left: -SimpleTableConstants.tableLeftPadding,
            child: _buildRowMoreActionButton(),
          ),
          Positioned(
            left: 0,
            right: 0,
            child: _buildColumnMoreActionButton(),
          ),
          Positioned(
            right: 0,
            top: node.rowIndex == 0 ? SimpleTableConstants.tableTopPadding : 0,
            bottom: 0,
            child: SimpleTableColumnResizeHandle(
              node: node,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCell() {
    if (simpleTableContext == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      // add padding to the top of the cell if it is the first row, otherwise the
      //  column action button is not clickable.
      // issue: https://github.com/flutter/flutter/issues/75747
      padding: EdgeInsets.only(
        top: node.rowIndex == 0 ? SimpleTableConstants.tableTopPadding : 0,
      ),
      child: ValueListenableBuilder<bool>(
        valueListenable: isEditingCellNotifier,
        builder: (context, isEditingCell, child) {
          return ValueListenableBuilder(
            valueListenable: simpleTableContext!.selectingColumn,
            builder: (context, selectingColumn, child) {
              return ValueListenableBuilder(
                valueListenable: simpleTableContext!.selectingRow,
                builder: (context, selectingRow, _) {
                  return DecoratedBox(
                    decoration: _buildDecoration(),
                    child: child!,
                  );
                },
              );
            },
            child: Column(
              children: node.children.map(_buildCellContent).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCellContent(Node childNode) {
    final alignment = _buildAlignment();
    return Container(
      padding: SimpleTableConstants.cellEdgePadding,
      constraints: const BoxConstraints(
        minWidth: SimpleTableConstants.minimumColumnWidth,
      ),
      width: node.columnWidth,
      alignment: alignment,
      child: IntrinsicWidth(
        child: IntrinsicHeight(
          child: editorState.renderer.build(context, childNode),
        ),
      ),
    );
  }

  Widget _buildRowMoreActionButton() {
    final columnIndex = node.columnIndex;
    final rowIndex = node.rowIndex;

    if (columnIndex != 0) {
      return const SizedBox.shrink();
    }

    return SimpleTableMoreActionMenu(
      index: rowIndex,
      type: SimpleTableMoreActionType.row,
    );
  }

  Widget _buildColumnMoreActionButton() {
    final columnIndex = node.columnIndex;
    final rowIndex = node.rowIndex;

    if (rowIndex != 0) {
      return const SizedBox.shrink();
    }

    return SimpleTableMoreActionMenu(
      index: columnIndex,
      type: SimpleTableMoreActionType.column,
    );
  }

  Alignment _buildAlignment() {
    Alignment alignment = Alignment.topLeft;
    if (node.columnAlign != TableAlign.left) {
      alignment = node.columnAlign.alignment;
    } else if (node.rowAlign != TableAlign.left) {
      alignment = node.rowAlign.alignment;
    }
    return alignment;
  }

  Decoration _buildDecoration() {
    final backgroundColor = _buildBackgroundColor();
    final border = _buildBorder();

    return BoxDecoration(
      border: border,
      color: backgroundColor,
    );
  }

  Color? _buildBackgroundColor() {
    // Priority: column color > row color > header color > default color

    final columnColor = node.buildColumnColor(context);
    if (columnColor != null && columnColor != Colors.transparent) {
      return columnColor;
    }

    final rowColor = node.buildRowColor(context);
    if (rowColor != null && rowColor != Colors.transparent) {
      return rowColor;
    }

    // Check if the cell is in the header.
    // If the cell is in the header, set the background color to the default header color.
    // Otherwise, set the background color to null.
    if (_isInHeader()) {
      return context.simpleTableDefaultHeaderColor;
    }

    return Theme.of(context).colorScheme.surface;
  }

  Border? _buildBorder() {
    if (SimpleTableConstants.borderType != SimpleTableBorderRenderType.cell) {
      return null;
    }

    final tableContext = context.watch<SimpleTableContext>();
    final isCellInSelectedColumn =
        node.columnIndex == tableContext.selectingColumn.value;
    final isCellInSelectedRow =
        node.rowIndex == tableContext.selectingRow.value;
    if (tableContext.isSelectingTable.value) {
      return _buildSelectingTableBorder();
    } else if (isCellInSelectedColumn) {
      return _buildColumnBorder();
    } else if (isCellInSelectedRow) {
      return _buildRowBorder();
    } else if (isEditingCellNotifier.value) {
      return _buildEditingBorder();
    } else {
      return _buildCellBorder();
    }
  }

  bool _isInHeader() {
    final isHeaderColumnEnabled = node.isHeaderColumnEnabled;
    final isHeaderRowEnabled = node.isHeaderRowEnabled;
    final cellPosition = node.cellPosition;
    final isFirstColumn = cellPosition.$1 == 0;
    final isFirstRow = cellPosition.$2 == 0;

    return isHeaderColumnEnabled && isFirstRow ||
        isHeaderRowEnabled && isFirstColumn;
  }

  /// the column border means the `VERTICAL` border of the cell
  ///
  ///      ____
  /// | 1 | 2 |
  /// | 3 | 4 |
  ///     |___|
  ///
  /// the border wrapping the cell 2 and cell 4 is the column border
  Border _buildColumnBorder() {
    return Border(
      left: _buildHighlightBorderSide(),
      right: _buildHighlightBorderSide(),
      top: node.rowIndex == 0
          ? _buildHighlightBorderSide()
          : _buildDefaultBorderSide(),
      bottom: node.rowIndex + 1 == node.parentTableNode?.rowLength
          ? _buildHighlightBorderSide()
          : _buildDefaultBorderSide(),
    );
  }

  /// the row border means the `HORIZONTAL` border of the cell
  ///
  ///  ________
  /// | 1 | 2 |
  /// |_______|
  /// | 3 | 4 |
  ///
  /// the border wrapping the cell 1 and cell 2 is the row border
  Border _buildRowBorder() {
    return Border(
      top: _buildHighlightBorderSide(),
      bottom: _buildHighlightBorderSide(),
      left: node.columnIndex == 0
          ? _buildHighlightBorderSide()
          : _buildDefaultBorderSide(),
      right: node.columnIndex + 1 == node.parentTableNode?.columnLength
          ? _buildHighlightBorderSide()
          : _buildDefaultBorderSide(),
    );
  }

  Border _buildCellBorder() {
    return Border(
      top: node.rowIndex == 0
          ? _buildDefaultBorderSide()
          : _buildLightBorderSide(),
      bottom: node.rowIndex + 1 == node.parentTableNode?.rowLength
          ? _buildDefaultBorderSide()
          : _buildLightBorderSide(),
      left: node.columnIndex == 0
          ? _buildDefaultBorderSide()
          : _buildLightBorderSide(),
      right: node.columnIndex + 1 == node.parentTableNode?.columnLength
          ? _buildDefaultBorderSide()
          : _buildLightBorderSide(),
    );
  }

  Border _buildEditingBorder() {
    return Border.all(
      color: Theme.of(context).colorScheme.primary,
      width: 2,
    );
  }

  Border _buildSelectingTableBorder() {
    final rowIndex = node.rowIndex;
    final columnIndex = node.columnIndex;

    return Border(
      top:
          rowIndex == 0 ? _buildHighlightBorderSide() : _buildLightBorderSide(),
      bottom: rowIndex + 1 == node.parentTableNode?.rowLength
          ? _buildHighlightBorderSide()
          : _buildLightBorderSide(),
      left: columnIndex == 0
          ? _buildHighlightBorderSide()
          : _buildLightBorderSide(),
      right: columnIndex + 1 == node.parentTableNode?.columnLength
          ? _buildHighlightBorderSide()
          : _buildLightBorderSide(),
    );
  }

  BorderSide _buildHighlightBorderSide() {
    return BorderSide(
      color: Theme.of(context).colorScheme.primary,
      width: 2,
    );
  }

  BorderSide _buildLightBorderSide() {
    return BorderSide(
      color: context.simpleTableBorderColor,
      width: 0.5,
    );
  }

  BorderSide _buildDefaultBorderSide() {
    return BorderSide(
      color: context.simpleTableBorderColor,
    );
  }

  void _onSelectingTableChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onSelectionChanged() {
    final selection = editorState.selection;

    // check if the selection is in the cell
    if (selection != null &&
        node.path.isAncestorOf(selection.start.path) &&
        node.path.isAncestorOf(selection.end.path)) {
      isEditingCellNotifier.value = true;
    } else {
      isEditingCellNotifier.value = false;
    }
  }
}
