import 'package:appflowy/plugins/document/presentation/editor_plugins/table/shared_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_constants.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_more_action.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/table_operations/table_node_extension.dart';
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
    return MouseRegion(
      hitTestBehavior: HitTestBehavior.opaque,
      onEnter: (event) =>
          context.read<SimpleTableContext>().hoveringTableCell.value = node,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildCell(),
          Positioned(
            top: -SimpleTableConstants.tableTopPadding,
            left: 0,
            right: 0,
            child: _buildRowMoreActionButton(),
          ),
          Positioned(
            left: -SimpleTableConstants.tableLeftPadding,
            top: 0,
            bottom: 0,
            child: _buildColumnMoreActionButton(),
          ),
          Positioned(
            right: 0,
            top: 0,
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
    return ValueListenableBuilder(
      valueListenable: context.read<SimpleTableContext>().selectingColumn,
      builder: (context, selectingColumn, child) {
        return ValueListenableBuilder(
          valueListenable: context.read<SimpleTableContext>().selectingRow,
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
    return const SizedBox.shrink();
    final cellPosition = node.cellPosition;
    final columnIndex = cellPosition.$1;
    final rowIndex = cellPosition.$2;

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

    if (columnIndex != 0) {
      return const SizedBox.shrink();
    }

    return SimpleTableMoreActionMenu(
      index: rowIndex,
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
    final rowColor = node.buildRowColor(context);
    if (rowColor != null && rowColor != Colors.transparent) {
      return rowColor;
    }

    final columnColor = node.buildColumnColor(context);
    if (columnColor != null && columnColor != Colors.transparent) {
      return columnColor;
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

    final columnIndex = node.columnIndex;
    final rowIndex = node.rowIndex;
    final isSelectingColumn =
        columnIndex == context.read<SimpleTableContext>().selectingColumn.value;
    final isSelectingRow =
        rowIndex == context.read<SimpleTableContext>().selectingRow.value;
    if (isSelectingColumn) {
      return Border(
        top: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
        bottom: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2.5,
        ),
        left: rowIndex == 0
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : BorderSide(
                color: context.simpleTableBorderColor,
              ),
        right: rowIndex + 1 == node.parentTableNode?.rowLength
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : BorderSide.none,
      );
    } else if (isSelectingRow) {
      return Border(
        left: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
        right: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2.5,
        ),
        top: columnIndex == 0
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : BorderSide(
                color: context.simpleTableBorderColor,
              ),
        bottom: columnIndex + 1 == node.parentTableNode?.columnLength
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : BorderSide.none,
      );
    } else {
      return Border.all(
        color: context.simpleTableBorderColor,
        strokeAlign: BorderSide.strokeAlignCenter,
      );
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
}
