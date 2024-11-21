import 'package:appflowy/plugins/document/presentation/editor_plugins/table/shared_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_constants.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_more_action.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/table_operations.dart';
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
          DecoratedBox(
            decoration: _buildDecoration(),
            child: Column(
              children: node.children.map(_buildCell).toList(),
            ),
          ),
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

  Widget _buildCell(Node node) {
    return Container(
      padding: SimpleTableConstants.cellEdgePadding,
      constraints: const BoxConstraints(
        minWidth: SimpleTableConstants.minimumColumnWidth,
      ),
      width: node.columnWidth,
      child: IntrinsicWidth(
        child: IntrinsicHeight(
          child: editorState.renderer.build(context, node),
        ),
      ),
    );
  }

  Widget _buildRowMoreActionButton() {
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
    final cellPosition = node.cellPosition;
    final columnIndex = cellPosition.$1;
    final rowIndex = cellPosition.$2;

    if (rowIndex != 0) {
      return const SizedBox.shrink();
    }

    return SimpleTableMoreActionMenu(
      index: columnIndex,
      type: SimpleTableMoreActionType.column,
    );
  }

  Decoration _buildDecoration() {
    final backgroundColor = _getBackgroundColor();
    return SimpleTableConstants.borderType == SimpleTableBorderRenderType.cell
        ? BoxDecoration(
            border: Border.all(
              color: context.simpleTableBorderColor,
              strokeAlign: BorderSide.strokeAlignCenter,
            ),
            color: backgroundColor,
          )
        : BoxDecoration(
            color: backgroundColor,
          );
  }

  Color? _getBackgroundColor() {
    // Check if the cell is in the header.
    // If the cell is in the header, set the background color to the default header color.
    // Otherwise, set the background color to null.
    if (_isInHeader()) {
      return context.simpleTableDefaultHeaderColor;
    }

    return Theme.of(context).colorScheme.surface;
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
