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
  late final borderBuilder = SimpleTableBorderBuilder(
    context: context,
    simpleTableContext: simpleTableContext!,
    node: node,
  );

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
          if (node.columnIndex == 0)
            Positioned(
              top: 0,
              bottom: 0,
              left: -SimpleTableConstants.tableLeftPadding,
              child: _buildRowMoreActionButton(),
            ),
          if (node.rowIndex == 0)
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
      // TODO(Lucas): find a better way to handle the multiple value listenable builder
      // There's flutter pub can do that.
      child: ValueListenableBuilder<bool>(
        valueListenable: isEditingCellNotifier,
        builder: (context, isEditingCell, child) {
          return ValueListenableBuilder(
            valueListenable: simpleTableContext!.selectingColumn,
            builder: (context, selectingColumn, _) {
              return ValueListenableBuilder(
                valueListenable: simpleTableContext!.selectingRow,
                builder: (context, selectingRow, _) {
                  return ValueListenableBuilder(
                    valueListenable: simpleTableContext!.hoveringTableCell,
                    builder: (context, hoveringTableCell, _) {
                      return DecoratedBox(
                        decoration: _buildDecoration(),
                        child: child!,
                      );
                    },
                  );
                },
              );
            },
          );
        },
        child: Container(
          padding: SimpleTableConstants.cellEdgePadding,
          constraints: const BoxConstraints(
            minWidth: SimpleTableConstants.minimumColumnWidth,
          ),
          width: node.columnWidth,
          child: Column(
            children: node.children.map(_buildCellContent).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildCellContent(Node childNode) {
    final alignment = _buildAlignment();

    return Align(
      alignment: alignment,
      child: IntrinsicWidth(
        child: IntrinsicHeight(
          child: editorState.renderer.build(context, childNode),
        ),
      ),
    );
  }

  Widget _buildRowMoreActionButton() {
    final rowIndex = node.rowIndex;

    return SimpleTableMoreActionMenu(
      index: rowIndex,
      type: SimpleTableMoreActionType.row,
    );
  }

  Widget _buildColumnMoreActionButton() {
    final columnIndex = node.columnIndex;

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
    final border = borderBuilder.buildBorder(
      isEditingCell: isEditingCellNotifier.value,
    );

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

  bool _isInHeader() {
    final isHeaderColumnEnabled = node.isHeaderColumnEnabled;
    final isHeaderRowEnabled = node.isHeaderRowEnabled;
    final cellPosition = node.cellPosition;
    final isFirstColumn = cellPosition.$1 == 0;
    final isFirstRow = cellPosition.$2 == 0;

    return isHeaderColumnEnabled && isFirstRow ||
        isHeaderRowEnabled && isFirstColumn;
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
