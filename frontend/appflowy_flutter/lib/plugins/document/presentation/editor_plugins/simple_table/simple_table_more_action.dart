import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum SimpleTableMoreActionType {
  column,
  row;

  List<SimpleTableMoreAction> buildActions({
    required int index,
    required int columnLength,
    required int rowLength,
  }) {
    // there're two special cases:
    // 1. if the table only contains one row or one column, remove the delete action
    // 2. if the index is 0, add the enable header action
    switch (this) {
      case SimpleTableMoreActionType.row:
        return [
          SimpleTableMoreAction.insertAbove,
          SimpleTableMoreAction.insertBelow,
          SimpleTableMoreAction.divider,
          if (index == 0) SimpleTableMoreAction.enableHeaderRow,
          SimpleTableMoreAction.backgroundColor,
          SimpleTableMoreAction.align,
          SimpleTableMoreAction.divider,
          SimpleTableMoreAction.setToPageWidth,
          SimpleTableMoreAction.distributeColumnsEvenly,
          SimpleTableMoreAction.divider,
          SimpleTableMoreAction.duplicate,
          SimpleTableMoreAction.clearContents,
          if (rowLength > 1) SimpleTableMoreAction.delete,
        ];
      case SimpleTableMoreActionType.column:
        return [
          SimpleTableMoreAction.insertLeft,
          SimpleTableMoreAction.insertRight,
          SimpleTableMoreAction.divider,
          if (index == 0) SimpleTableMoreAction.enableHeaderColumn,
          SimpleTableMoreAction.backgroundColor,
          SimpleTableMoreAction.align,
          SimpleTableMoreAction.divider,
          SimpleTableMoreAction.setToPageWidth,
          SimpleTableMoreAction.distributeColumnsEvenly,
          SimpleTableMoreAction.divider,
          SimpleTableMoreAction.duplicate,
          SimpleTableMoreAction.clearContents,
          if (columnLength > 1) SimpleTableMoreAction.delete,
        ];
    }
  }

  FlowySvgData get reorderIconSvg {
    switch (this) {
      case SimpleTableMoreActionType.column:
        return FlowySvgs.table_reorder_column_s;
      case SimpleTableMoreActionType.row:
        return FlowySvgs.table_reorder_row_s;
    }
  }

  @override
  String toString() {
    return switch (this) {
      SimpleTableMoreActionType.column => 'column',
      SimpleTableMoreActionType.row => 'row',
    };
  }
}

enum SimpleTableMoreAction {
  insertLeft,
  insertRight,
  insertAbove,
  insertBelow,
  duplicate,
  clearContents,
  delete,
  align,
  backgroundColor,
  enableHeaderColumn,
  enableHeaderRow,
  setToPageWidth,
  distributeColumnsEvenly,
  divider;

  String get name {
    return switch (this) {
      SimpleTableMoreAction.align =>
        LocaleKeys.document_plugins_simpleTable_moreActions_align.tr(),
      SimpleTableMoreAction.backgroundColor =>
        LocaleKeys.document_plugins_simpleTable_moreActions_color.tr(),
      SimpleTableMoreAction.enableHeaderColumn =>
        LocaleKeys.document_plugins_simpleTable_moreActions_headerColumn.tr(),
      SimpleTableMoreAction.enableHeaderRow =>
        LocaleKeys.document_plugins_simpleTable_moreActions_headerRow.tr(),
      SimpleTableMoreAction.insertLeft =>
        LocaleKeys.document_plugins_simpleTable_moreActions_insertLeft.tr(),
      SimpleTableMoreAction.insertRight =>
        LocaleKeys.document_plugins_simpleTable_moreActions_insertRight.tr(),
      SimpleTableMoreAction.insertBelow =>
        LocaleKeys.document_plugins_simpleTable_moreActions_insertBelow.tr(),
      SimpleTableMoreAction.insertAbove =>
        LocaleKeys.document_plugins_simpleTable_moreActions_insertAbove.tr(),
      SimpleTableMoreAction.clearContents =>
        LocaleKeys.document_plugins_simpleTable_moreActions_clearContents.tr(),
      SimpleTableMoreAction.delete =>
        LocaleKeys.document_plugins_simpleTable_moreActions_delete.tr(),
      SimpleTableMoreAction.duplicate =>
        LocaleKeys.document_plugins_simpleTable_moreActions_duplicate.tr(),
      SimpleTableMoreAction.setToPageWidth =>
        LocaleKeys.document_plugins_simpleTable_moreActions_setToPageWidth.tr(),
      SimpleTableMoreAction.distributeColumnsEvenly => LocaleKeys
          .document_plugins_simpleTable_moreActions_distributeColumnsWidth
          .tr(),
      SimpleTableMoreAction.divider => throw UnimplementedError(),
    };
  }

  FlowySvgData get leftIconSvg {
    return switch (this) {
      SimpleTableMoreAction.insertLeft => FlowySvgs.table_insert_left_s,
      SimpleTableMoreAction.insertRight => FlowySvgs.table_insert_right_s,
      SimpleTableMoreAction.insertAbove => FlowySvgs.table_insert_above_s,
      SimpleTableMoreAction.insertBelow => FlowySvgs.table_insert_below_s,
      SimpleTableMoreAction.duplicate => FlowySvgs.duplicate_s,
      SimpleTableMoreAction.clearContents => FlowySvgs.table_clear_content_s,
      SimpleTableMoreAction.delete => FlowySvgs.trash_s,
      SimpleTableMoreAction.setToPageWidth =>
        FlowySvgs.table_set_to_page_width_s,
      SimpleTableMoreAction.distributeColumnsEvenly =>
        FlowySvgs.table_distribute_columns_evenly_s,
      SimpleTableMoreAction.enableHeaderColumn =>
        FlowySvgs.table_header_column_s,
      SimpleTableMoreAction.enableHeaderRow => FlowySvgs.table_header_row_s,
      SimpleTableMoreAction.divider =>
        throw UnsupportedError('divider icon is not supported'),
      SimpleTableMoreAction.align =>
        throw UnsupportedError('align icon is not supported'),
      SimpleTableMoreAction.backgroundColor =>
        throw UnsupportedError('background color icon is not supported'),
    };
  }
}

class SimpleTableMoreActionMenu extends StatefulWidget {
  const SimpleTableMoreActionMenu({
    super.key,
    required this.index,
    required this.type,
  });

  final int index;
  final SimpleTableMoreActionType type;

  @override
  State<SimpleTableMoreActionMenu> createState() =>
      _SimpleTableMoreActionMenuState();
}

class _SimpleTableMoreActionMenuState extends State<SimpleTableMoreActionMenu> {
  ValueNotifier<bool> isShowingMenu = ValueNotifier(false);

  @override
  void dispose() {
    isShowingMenu.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final simpleTableContext = context.read<SimpleTableContext>();
    return Align(
      alignment: widget.type == SimpleTableMoreActionType.row
          ? Alignment.centerLeft
          : Alignment.topCenter,
      child: ValueListenableBuilder<bool>(
        valueListenable: isShowingMenu,
        builder: (context, isShowingMenu, child) {
          return ValueListenableBuilder(
            valueListenable: simpleTableContext.hoveringTableCell,
            builder: (context, hoveringTableNode, child) {
              final reorderingIndex = switch (widget.type) {
                SimpleTableMoreActionType.column =>
                  simpleTableContext.isReorderingColumn.value.$2,
                SimpleTableMoreActionType.row =>
                  simpleTableContext.isReorderingRow.value.$2,
              };
              final isReordering = simpleTableContext.isReordering;
              if (isReordering) {
                // when reordering, hide the menu for another column or row that is not the current dragging one.
                if (reorderingIndex != widget.index) {
                  return const SizedBox.shrink();
                } else {
                  return child!;
                }
              }

              final hoveringIndex =
                  widget.type == SimpleTableMoreActionType.column
                      ? hoveringTableNode?.columnIndex
                      : hoveringTableNode?.rowIndex;

              if (hoveringIndex != widget.index && !isShowingMenu) {
                return const SizedBox.shrink();
              }

              return child!;
            },
            child: SimpleTableMoreActionPopup(
              index: widget.index,
              isShowingMenu: this.isShowingMenu,
              type: widget.type,
            ),
          );
        },
      ),
    );
  }
}

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
          .buildActions(
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
          table,
          isEnableHeader.value,
        );
      case SimpleTableMoreActionType.row:
        editorState.toggleEnableHeaderRow(
          table,
          isEnableHeader.value,
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
      editorState.clearContentAtColumnIndex(table, node.columnIndex);
    } else if (widget.type == SimpleTableMoreActionType.row) {
      editorState.clearContentAtRowIndex(table, node.rowIndex);
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
