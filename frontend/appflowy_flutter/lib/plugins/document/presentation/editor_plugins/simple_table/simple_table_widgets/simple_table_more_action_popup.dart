import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SimpleTableMoreActionPopup extends StatefulWidget {
  const SimpleTableMoreActionPopup({
    super.key,
    required this.index,
    required this.isShowingMenu,
    required this.type,
  });

  final int index;
  final ValueNotifier<bool> isShowingMenu;
  final SimpleTableMoreActionType type;

  @override
  State<SimpleTableMoreActionPopup> createState() =>
      _SimpleTableMoreActionPopupState();
}

class _SimpleTableMoreActionPopupState
    extends State<SimpleTableMoreActionPopup> {
  late final editorState = context.read<EditorState>();

  SelectionGestureInterceptor? gestureInterceptor;

  RenderBox? get renderBox => context.findRenderObject() as RenderBox?;

  @override
  void initState() {
    super.initState();

    final tableCellNode =
        context.read<SimpleTableContext>().hoveringTableCell.value;
    gestureInterceptor = SelectionGestureInterceptor(
      key: 'simple_table_more_action_popup_interceptor_${tableCellNode?.id}',
      canTap: (details) => !_isTapInBounds(details.globalPosition),
    );
    editorState.service.selectionService.registerGestureInterceptor(
      gestureInterceptor!,
    );
  }

  @override
  void dispose() {
    if (gestureInterceptor != null) {
      editorState.service.selectionService.unregisterGestureInterceptor(
        gestureInterceptor!.key,
      );
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final simpleTableContext = context.read<SimpleTableContext>();
    final tableCellNode = simpleTableContext.hoveringTableCell.value;
    final tableNode = tableCellNode?.parentTableNode;

    if (tableNode == null) {
      return const SizedBox.shrink();
    }

    return AppFlowyPopover(
      onOpen: () => _onOpen(tableCellNode: tableCellNode),
      onClose: () => _onClose(),
      direction: widget.type == SimpleTableMoreActionType.row
          ? PopoverDirection.bottomWithCenterAligned
          : PopoverDirection.bottomWithLeftAligned,
      offset: widget.type == SimpleTableMoreActionType.row
          ? const Offset(24, 14)
          : const Offset(-14, 8),
      clickHandler: PopoverClickHandler.gestureDetector,
      popupBuilder: (_) => _buildPopup(tableCellNode: tableCellNode),
      child: SimpleTableDraggableReorderButton(
        editorState: editorState,
        simpleTableContext: simpleTableContext,
        node: tableNode,
        index: widget.index,
        isShowingMenu: widget.isShowingMenu,
        type: widget.type,
      ),
    );
  }

  Widget _buildPopup({Node? tableCellNode}) {
    if (tableCellNode == null) {
      return const SizedBox.shrink();
    }
    return MultiProvider(
      providers: [
        Provider.value(
          value: context.read<SimpleTableContext>(),
        ),
        Provider.value(
          value: context.read<EditorState>(),
        ),
      ],
      child: SimpleTableMoreActionList(
        type: widget.type,
        index: widget.index,
        tableCellNode: tableCellNode,
      ),
    );
  }

  void _onOpen({Node? tableCellNode}) {
    widget.isShowingMenu.value = true;

    switch (widget.type) {
      case SimpleTableMoreActionType.column:
        context.read<SimpleTableContext>().selectingColumn.value =
            tableCellNode?.columnIndex;
      case SimpleTableMoreActionType.row:
        context.read<SimpleTableContext>().selectingRow.value =
            tableCellNode?.rowIndex;
    }

    // Workaround to clear the selection after the menu is opened.
    Future.delayed(Durations.short3, () {
      if (!editorState.isDisposed) {
        editorState.selection = null;
      }
    });
  }

  void _onClose() {
    widget.isShowingMenu.value = false;

    // clear the selecting index
    context.read<SimpleTableContext>().selectingColumn.value = null;
    context.read<SimpleTableContext>().selectingRow.value = null;
  }

  bool _isTapInBounds(Offset offset) {
    if (renderBox == null) {
      return false;
    }

    final localPosition = renderBox!.globalToLocal(offset);
    final result = renderBox!.paintBounds.contains(localPosition);
    if (result) {
      editorState.selection = null;
    }
    return result;
  }
}

class SimpleTableMoreActionList extends StatefulWidget {
  const SimpleTableMoreActionList({
    super.key,
    required this.type,
    required this.index,
    required this.tableCellNode,
    this.mutex,
  });

  final SimpleTableMoreActionType type;
  final int index;
  final Node tableCellNode;
  final PopoverMutex? mutex;

  @override
  State<SimpleTableMoreActionList> createState() =>
      _SimpleTableMoreActionListState();
}

class _SimpleTableMoreActionListState extends State<SimpleTableMoreActionList> {
  // ensure the background color menu and align menu exclusive
  final mutex = PopoverMutex();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: widget.type
          .buildDesktopActions(
            index: widget.index,
            columnLength: widget.tableCellNode.columnLength,
            rowLength: widget.tableCellNode.rowLength,
          )
          .map(
            (action) => SimpleTableMoreActionItem(
              type: widget.type,
              action: action,
              tableCellNode: widget.tableCellNode,
              popoverMutex: mutex,
            ),
          )
          .toList(),
    );
  }
}

class SimpleTableMoreActionItem extends StatefulWidget {
  const SimpleTableMoreActionItem({
    super.key,
    required this.type,
    required this.action,
    required this.tableCellNode,
    required this.popoverMutex,
  });

  final SimpleTableMoreActionType type;
  final SimpleTableMoreAction action;
  final Node tableCellNode;
  final PopoverMutex popoverMutex;

  @override
  State<SimpleTableMoreActionItem> createState() =>
      _SimpleTableMoreActionItemState();
}

class _SimpleTableMoreActionItemState extends State<SimpleTableMoreActionItem> {
  final isEnableHeader = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

    _initEnableHeader();
  }

  @override
  void dispose() {
    isEnableHeader.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.action == SimpleTableMoreAction.divider) {
      return _buildDivider(context);
    } else if (widget.action == SimpleTableMoreAction.align) {
      return _buildAlignMenu(context);
    } else if (widget.action == SimpleTableMoreAction.backgroundColor) {
      return _buildBackgroundColorMenu(context);
    } else if (widget.action == SimpleTableMoreAction.enableHeaderColumn) {
      return _buildEnableHeaderButton(context);
    } else if (widget.action == SimpleTableMoreAction.enableHeaderRow) {
      return _buildEnableHeaderButton(context);
    }

    return _buildActionButton(context);
  }

  Widget _buildDivider(BuildContext context) {
    return const FlowyDivider(
      padding: EdgeInsets.symmetric(
        vertical: 4.0,
      ),
    );
  }

  Widget _buildAlignMenu(BuildContext context) {
    return SimpleTableAlignMenu(
      type: widget.type,
      tableCellNode: widget.tableCellNode,
      mutex: widget.popoverMutex,
    );
  }

  Widget _buildBackgroundColorMenu(BuildContext context) {
    return SimpleTableBackgroundColorMenu(
      type: widget.type,
      tableCellNode: widget.tableCellNode,
      mutex: widget.popoverMutex,
    );
  }

  Widget _buildEnableHeaderButton(BuildContext context) {
    return SimpleTableBasicButton(
      text: widget.action.name,
      leftIconSvg: widget.action.leftIconSvg,
      rightIcon: ValueListenableBuilder(
        valueListenable: isEnableHeader,
        builder: (context, isEnableHeader, child) {
          return Toggle(
            value: isEnableHeader,
            onChanged: (value) => _toggleEnableHeader(),
            padding: EdgeInsets.zero,
          );
        },
      ),
      onTap: _toggleEnableHeader,
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return Container(
      height: SimpleTableConstants.moreActionHeight,
      padding: SimpleTableConstants.moreActionPadding,
      child: FlowyIconTextButton(
        margin: SimpleTableConstants.moreActionHorizontalMargin,
        leftIconBuilder: (onHover) => FlowySvg(
          widget.action.leftIconSvg,
          color: widget.action == SimpleTableMoreAction.delete && onHover
              ? Theme.of(context).colorScheme.error
              : null,
        ),
        iconPadding: 10.0,
        textBuilder: (onHover) => FlowyText.regular(
          widget.action.name,
          fontSize: 14.0,
          figmaLineHeight: 18.0,
          color: widget.action == SimpleTableMoreAction.delete && onHover
              ? Theme.of(context).colorScheme.error
              : null,
        ),
        onTap: _onAction,
      ),
    );
  }

  void _onAction() {
    switch (widget.action) {
      case SimpleTableMoreAction.delete:
        switch (widget.type) {
          case SimpleTableMoreActionType.column:
            _deleteColumn();
            break;
          case SimpleTableMoreActionType.row:
            _deleteRow();
            break;
        }
      case SimpleTableMoreAction.insertLeft:
        _insertColumnLeft();
      case SimpleTableMoreAction.insertRight:
        _insertColumnRight();
      case SimpleTableMoreAction.insertAbove:
        _insertRowAbove();
      case SimpleTableMoreAction.insertBelow:
        _insertRowBelow();
      case SimpleTableMoreAction.clearContents:
        _clearContent();
      case SimpleTableMoreAction.duplicate:
        switch (widget.type) {
          case SimpleTableMoreActionType.column:
            _duplicateColumn();
            break;
          case SimpleTableMoreActionType.row:
            _duplicateRow();
            break;
        }
      case SimpleTableMoreAction.setToPageWidth:
        _setToPageWidth();
      case SimpleTableMoreAction.distributeColumnsEvenly:
        _distributeColumnsEvenly();
      default:
        break;
    }

    PopoverContainer.of(context).close();
  }

  void _setToPageWidth() {
    final value = _getTableAndTableCellAndCellPosition();
    if (value == null) {
      return;
    }
    final (table, _, _) = value;
    final editorState = context.read<EditorState>();
    editorState.setColumnWidthToPageWidth(tableNode: table);
  }

  void _distributeColumnsEvenly() {
    final value = _getTableAndTableCellAndCellPosition();
    if (value == null) {
      return;
    }
    final (table, _, _) = value;
    final editorState = context.read<EditorState>();
    editorState.distributeColumnWidthToPageWidth(tableNode: table);
  }

  void _duplicateRow() {
    final value = _getTableAndTableCellAndCellPosition();
    if (value == null) {
      return;
    }
    final (table, node, _) = value;
    final editorState = context.read<EditorState>();
    editorState.duplicateRowInTable(table, node.rowIndex);
  }

  void _duplicateColumn() {
    final value = _getTableAndTableCellAndCellPosition();
    if (value == null) {
      return;
    }
    final (table, node, _) = value;
    final editorState = context.read<EditorState>();
    editorState.duplicateColumnInTable(table, node.columnIndex);
  }

  void _toggleEnableHeader() {
    final value = _getTableAndTableCellAndCellPosition();
    if (value == null) {
      return;
    }

    isEnableHeader.value = !isEnableHeader.value;

    final (table, _, _) = value;
    final editorState = context.read<EditorState>();
    switch (widget.type) {
      case SimpleTableMoreActionType.column:
        editorState.toggleEnableHeaderColumn(
          tableNode: table,
          enable: isEnableHeader.value,
        );
      case SimpleTableMoreActionType.row:
        editorState.toggleEnableHeaderRow(
          tableNode: table,
          enable: isEnableHeader.value,
        );
    }

    PopoverContainer.of(context).close();
  }

  void _clearContent() {
    final value = _getTableAndTableCellAndCellPosition();
    if (value == null) {
      return;
    }
    final (table, node, _) = value;
    final editorState = context.read<EditorState>();
    if (widget.type == SimpleTableMoreActionType.column) {
      editorState.clearContentAtColumnIndex(
        tableNode: table,
        columnIndex: node.columnIndex,
      );
    } else if (widget.type == SimpleTableMoreActionType.row) {
      editorState.clearContentAtRowIndex(
        tableNode: table,
        rowIndex: node.rowIndex,
      );
    }
  }

  void _insertColumnLeft() {
    final value = _getTableAndTableCellAndCellPosition();
    if (value == null) {
      return;
    }
    final (table, node, _) = value;
    final columnIndex = node.columnIndex;
    final editorState = context.read<EditorState>();
    editorState.insertColumnInTable(table, columnIndex);

    final cell = table.getTableCellNode(
      rowIndex: 0,
      columnIndex: columnIndex,
    );
    if (cell == null) {
      return;
    }

    // update selection
    editorState.selection = Selection.collapsed(
      Position(
        path: cell.path.child(0),
      ),
    );
  }

  void _insertColumnRight() {
    final value = _getTableAndTableCellAndCellPosition();
    if (value == null) {
      return;
    }
    final (table, node, _) = value;
    final columnIndex = node.columnIndex;
    final editorState = context.read<EditorState>();
    editorState.insertColumnInTable(table, columnIndex + 1);

    final cell = table.getTableCellNode(
      rowIndex: 0,
      columnIndex: columnIndex + 1,
    );
    if (cell == null) {
      return;
    }

    // update selection
    editorState.selection = Selection.collapsed(
      Position(
        path: cell.path.child(0),
      ),
    );
  }

  void _insertRowAbove() {
    final value = _getTableAndTableCellAndCellPosition();
    if (value == null) {
      return;
    }
    final (table, node, _) = value;
    final rowIndex = node.rowIndex;
    final editorState = context.read<EditorState>();
    editorState.insertRowInTable(table, rowIndex);

    final cell = table.getTableCellNode(rowIndex: rowIndex, columnIndex: 0);
    if (cell == null) {
      return;
    }

    // update selection
    editorState.selection = Selection.collapsed(
      Position(
        path: cell.path.child(0),
      ),
    );
  }

  void _insertRowBelow() {
    final value = _getTableAndTableCellAndCellPosition();
    if (value == null) {
      return;
    }
    final (table, node, _) = value;
    final rowIndex = node.rowIndex;
    final editorState = context.read<EditorState>();
    editorState.insertRowInTable(table, rowIndex + 1);

    final cell = table.getTableCellNode(rowIndex: rowIndex + 1, columnIndex: 0);
    if (cell == null) {
      return;
    }

    // update selection
    editorState.selection = Selection.collapsed(
      Position(
        path: cell.path.child(0),
      ),
    );
  }

  void _deleteRow() {
    final value = _getTableAndTableCellAndCellPosition();
    if (value == null) {
      return;
    }
    final (table, node, _) = value;
    final rowIndex = node.rowIndex;
    final editorState = context.read<EditorState>();
    editorState.deleteRowInTable(table, rowIndex);
  }

  void _deleteColumn() {
    final value = _getTableAndTableCellAndCellPosition();
    if (value == null) {
      return;
    }
    final (table, node, _) = value;
    final columnIndex = node.columnIndex;
    final editorState = context.read<EditorState>();
    editorState.deleteColumnInTable(table, columnIndex);
  }

  (Node, Node, TableCellPosition)? _getTableAndTableCellAndCellPosition() {
    final cell = widget.tableCellNode;
    final table = cell.parent?.parent;
    if (table == null || table.type != SimpleTableBlockKeys.type) {
      return null;
    }
    return (table, cell, cell.cellPosition);
  }

  void _initEnableHeader() {
    final value = _getTableAndTableCellAndCellPosition();
    if (value != null) {
      final (table, _, _) = value;
      if (widget.type == SimpleTableMoreActionType.column) {
        isEnableHeader.value = table
                .attributes[SimpleTableBlockKeys.enableHeaderColumn] as bool? ??
            false;
      } else if (widget.type == SimpleTableMoreActionType.row) {
        isEnableHeader.value =
            table.attributes[SimpleTableBlockKeys.enableHeaderRow] as bool? ??
                false;
      }
    }
  }
}
