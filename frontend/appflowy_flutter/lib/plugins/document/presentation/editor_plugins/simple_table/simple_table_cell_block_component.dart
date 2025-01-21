import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';

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
    this.alwaysDistributeColumnWidths = false,
  });

  final bool alwaysDistributeColumnWidths;

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return SimpleTableCellBlockWidget(
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
  BlockComponentValidate get validate => (node) => true;
}

class SimpleTableCellBlockWidget extends BlockComponentStatefulWidget {
  const SimpleTableCellBlockWidget({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.configuration = const BlockComponentConfiguration(),
    required this.alwaysDistributeColumnWidths,
  });

  final bool alwaysDistributeColumnWidths;

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

  /// Notify if the cell is editing.
  ValueNotifier<bool> isEditingCellNotifier = ValueNotifier(false);

  /// Notify if the cell is hit by the reordering offset.
  ///
  /// This value is only available on mobile.
  ValueNotifier<bool> isReorderingHitCellNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

    simpleTableContext?.isSelectingTable.addListener(_onSelectingTableChanged);
    simpleTableContext?.reorderingOffset
        .addListener(_onReorderingOffsetChanged);
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
    simpleTableContext?.reorderingOffset.removeListener(
      _onReorderingOffsetChanged,
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

    Widget child = Stack(
      clipBehavior: Clip.none,
      children: [
        _buildCell(),
        if (editorState.editable) ...[
          if (node.columnIndex == 0)
            Positioned(
              // if the cell is in the first row, add padding to the top of the cell
              // to make the row action button clickable.
              top: node.rowIndex == 0
                  ? SimpleTableConstants.tableHitTestTopPadding
                  : 0,
              bottom: 0,
              left: -SimpleTableConstants.tableLeftPadding,
              child: _buildRowMoreActionButton(),
            ),
          if (node.rowIndex == 0)
            Positioned(
              left: node.columnIndex == 0
                  ? SimpleTableConstants.tableHitTestLeftPadding
                  : 0,
              right: 0,
              child: _buildColumnMoreActionButton(),
            ),
          if (node.columnIndex == 0 && node.rowIndex == 0)
            Positioned(
              left: 2,
              top: 2,
              child: _buildTableActionMenu(),
            ),
          Positioned(
            right: 0,
            top: node.rowIndex == 0
                ? SimpleTableConstants.tableHitTestTopPadding
                : 0,
            bottom: 0,
            child: SimpleTableColumnResizeHandle(
              node: node,
            ),
          ),
        ],
      ],
    );

    if (UniversalPlatform.isDesktop) {
      child = MouseRegion(
        hitTestBehavior: HitTestBehavior.opaque,
        onEnter: (event) => simpleTableContext!.hoveringTableCell.value = node,
        child: child,
      );
    }

    return child;
  }

  Widget _buildCell() {
    if (simpleTableContext == null) {
      return const SizedBox.shrink();
    }

    return UniversalPlatform.isDesktop
        ? _buildDesktopCell()
        : _buildMobileCell();
  }

  Widget _buildDesktopCell() {
    return Padding(
      // add padding to the top of the cell if it is the first row, otherwise the
      //  column action button is not clickable.
      // issue: https://github.com/flutter/flutter/issues/75747
      padding: EdgeInsets.only(
        top: node.rowIndex == 0
            ? SimpleTableConstants.tableHitTestTopPadding
            : 0,
        left: node.columnIndex == 0
            ? SimpleTableConstants.tableHitTestLeftPadding
            : 0,
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
          width: widget.alwaysDistributeColumnWidths ? null : node.columnWidth,
          child: node.children.isEmpty
              ? Column(
                  children: [
                    // expand the cell to make the empty cell content clickable
                    Expanded(
                      child: _buildEmptyCellContent(),
                    ),
                  ],
                )
              : Column(
                  children: [
                    ...node.children.map(_buildCellContent),
                    _buildEmptyCellContent(height: 12),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildMobileCell() {
    return Padding(
      padding: EdgeInsets.only(
        top: node.rowIndex == 0
            ? SimpleTableConstants.tableHitTestTopPadding
            : 0,
        left: node.columnIndex == 0
            ? SimpleTableConstants.tableHitTestLeftPadding
            : 0,
      ),
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
                    valueListenable: isReorderingHitCellNotifier,
                    builder: (context, isReorderingHitCellNotifier, _) {
                      final previousCell = node.getPreviousCellInSameRow();
                      return Stack(
                        children: [
                          DecoratedBox(
                            decoration: _buildDecoration(),
                            child: child!,
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: SimpleTableColumnResizeHandle(
                              node: node,
                            ),
                          ),
                          if (node.columnIndex != 0 && previousCell != null)
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              // pass the previous node to the resize handle
                              // to make the resize handle work correctly
                              child: SimpleTableColumnResizeHandle(
                                node: previousCell,
                                isPreviousCell: true,
                              ),
                            ),
                        ],
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
          child: node.children.isEmpty
              ? _buildEmptyCellContent()
              : Column(
                  children: node.children.map(_buildCellContent).toList(),
                ),
        ),
      ),
    );
  }

  Widget _buildCellContent(Node childNode) {
    final alignment = _buildAlignment();

    Widget child = IntrinsicWidth(
      child: editorState.renderer.build(context, childNode),
    );

    final notSupportAlignmentBlocks = [
      DividerBlockKeys.type,
      CalloutBlockKeys.type,
      MathEquationBlockKeys.type,
      CodeBlockKeys.type,
      SubPageBlockKeys.type,
      FileBlockKeys.type,
      CustomImageBlockKeys.type,
    ];
    if (notSupportAlignmentBlocks.contains(childNode.type)) {
      child = SizedBox(
        width: double.infinity,
        child: child,
      );
    } else {
      child = Align(
        alignment: alignment,
        child: child,
      );
    }

    return child;
  }

  Widget _buildEmptyCellContent({
    double? height,
  }) {
    // if the table cell is empty, we should allow the user to tap on it to create a new paragraph.
    final lastChild = node.children.lastOrNull;
    if (lastChild != null && lastChild.delta?.isEmpty != null) {
      return const SizedBox.shrink();
    }

    Widget child = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final transaction = editorState.transaction;
        final length = node.children.length;
        final path = node.path.child(length);
        transaction
          ..insertNode(
            path,
            paragraphNode(),
          )
          ..afterSelection = Selection.collapsed(Position(path: path));
        editorState.apply(transaction);
      },
    );

    if (height != null) {
      child = SizedBox(
        height: height,
        child: child,
      );
    }

    return child;
  }

  Widget _buildRowMoreActionButton() {
    final rowIndex = node.rowIndex;

    return SimpleTableMoreActionMenu(
      tableCellNode: node,
      index: rowIndex,
      type: SimpleTableMoreActionType.row,
    );
  }

  Widget _buildColumnMoreActionButton() {
    final columnIndex = node.columnIndex;

    return SimpleTableMoreActionMenu(
      tableCellNode: node,
      index: columnIndex,
      type: SimpleTableMoreActionType.column,
    );
  }

  Widget _buildTableActionMenu() {
    final tableNode = node.parentTableNode;

    // the table action menu is only available on mobile platform.
    if (tableNode == null || UniversalPlatform.isDesktop) {
      return const SizedBox.shrink();
    }

    return SimpleTableActionMenu(
      tableNode: tableNode,
      editorState: editorState,
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
    // Priority: highlight color > column color > row color > header color > default color
    final isSelectingTable =
        simpleTableContext?.isSelectingTable.value ?? false;
    if (isSelectingTable) {
      return Theme.of(context).colorScheme.primary.withValues(alpha: 0.1);
    }

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

    return Colors.transparent;
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
      simpleTableContext?.isEditingCell.value = node;
    } else {
      isEditingCellNotifier.value = false;
    }

    // if the selection is null or the selection is collapsed, set the isEditingCell to null.
    if (selection == null) {
      simpleTableContext?.isEditingCell.value = null;
    } else if (selection.isCollapsed) {
      // if the selection is collapsed, check if the selection is in the cell.
      final selectedNode =
          editorState.getNodesInSelection(selection).firstOrNull;
      if (selectedNode != null) {
        final tableNode = selectedNode.parentTableNode;
        if (tableNode == null || tableNode.id != node.parentTableNode?.id) {
          simpleTableContext?.isEditingCell.value = null;
        }
      } else {
        simpleTableContext?.isEditingCell.value = null;
      }
    }
  }

  /// Calculate if the cell is hit by the reordering offset.
  /// If the cell is hit, set the isReorderingCell to true.
  void _onReorderingOffsetChanged() {
    final simpleTableContext = this.simpleTableContext;
    if (UniversalPlatform.isDesktop || simpleTableContext == null) {
      return;
    }

    final isReordering = simpleTableContext.isReordering;
    if (!isReordering) {
      return;
    }

    final isReorderingColumn = simpleTableContext.isReorderingColumn.value.$1;
    final isReorderingRow = simpleTableContext.isReorderingRow.value.$1;
    if (!isReorderingColumn && !isReorderingRow) {
      return;
    }

    final reorderingOffset = simpleTableContext.reorderingOffset.value;

    final renderBox = node.renderBox;
    if (renderBox == null) {
      return;
    }

    final cellRect = renderBox.localToGlobal(Offset.zero) & renderBox.size;

    bool isHitCurrentCell = false;
    if (isReorderingColumn) {
      isHitCurrentCell = cellRect.left < reorderingOffset.dx &&
          cellRect.right > reorderingOffset.dx;
    } else if (isReorderingRow) {
      isHitCurrentCell = cellRect.top < reorderingOffset.dy &&
          cellRect.bottom > reorderingOffset.dy;
    }

    isReorderingHitCellNotifier.value = isHitCurrentCell;
    if (isHitCurrentCell) {
      if (isReorderingColumn) {
        if (simpleTableContext.isReorderingHitIndex.value != node.columnIndex) {
          HapticFeedback.lightImpact();

          simpleTableContext.isReorderingHitIndex.value = node.columnIndex;
        }
      } else if (isReorderingRow) {
        if (simpleTableContext.isReorderingHitIndex.value != node.rowIndex) {
          HapticFeedback.lightImpact();

          simpleTableContext.isReorderingHitIndex.value = node.rowIndex;
        }
      }
    }
  }
}
