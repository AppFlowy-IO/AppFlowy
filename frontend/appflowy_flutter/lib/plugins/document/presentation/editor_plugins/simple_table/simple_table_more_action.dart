import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/_shared_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_constants.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_operations/simple_table_operations.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum SimpleTableMoreActionType {
  column,
  row;

  List<SimpleTableMoreAction> get actions {
    switch (this) {
      case SimpleTableMoreActionType.row:
        return [
          SimpleTableMoreAction.insertAbove,
          SimpleTableMoreAction.insertBelow,
          SimpleTableMoreAction.duplicate,
          SimpleTableMoreAction.clearContents,
          SimpleTableMoreAction.delete,
          SimpleTableMoreAction.divider,
          SimpleTableMoreAction.align,
          SimpleTableMoreAction.backgroundColor,
        ];
      case SimpleTableMoreActionType.column:
        return [
          SimpleTableMoreAction.insertLeft,
          SimpleTableMoreAction.insertRight,
          SimpleTableMoreAction.duplicate,
          SimpleTableMoreAction.clearContents,
          SimpleTableMoreAction.delete,
          SimpleTableMoreAction.divider,
          SimpleTableMoreAction.align,
          SimpleTableMoreAction.backgroundColor,
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
    return Align(
      alignment: widget.type == SimpleTableMoreActionType.row
          ? Alignment.centerLeft
          : Alignment.topCenter,
      child: ValueListenableBuilder<bool>(
        valueListenable: isShowingMenu,
        builder: (context, isShowingMenu, child) {
          return ValueListenableBuilder(
            valueListenable:
                context.read<SimpleTableContext>().hoveringTableCell,
            builder: (context, hoveringTableNode, child) {
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
              key: ValueKey(widget.type.name + widget.index.toString()),
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
    final tableCellNode =
        context.read<SimpleTableContext>().hoveringTableCell.value;
    return AppFlowyPopover(
      onOpen: () {
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
      },
      onClose: () {
        widget.isShowingMenu.value = false;

        // clear the selecting index
        context.read<SimpleTableContext>().selectingColumn.value = null;
        context.read<SimpleTableContext>().selectingRow.value = null;
      },
      direction: widget.type == SimpleTableMoreActionType.row
          ? PopoverDirection.bottomWithCenterAligned
          : PopoverDirection.bottomWithLeftAligned,
      offset: widget.type == SimpleTableMoreActionType.row
          ? const Offset(24, 14)
          : const Offset(-14, 8),
      popupBuilder: (_) {
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
      },
      child: SimpleTableReorderButton(
        isShowingMenu: widget.isShowingMenu,
        type: widget.type,
      ),
    );
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
      children: _buildActions()
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

  List<SimpleTableMoreAction> _buildActions() {
    final actions = widget.type.actions;

    // if the index is 0, add the divider and enable header action
    if (widget.index == 0) {
      actions.addAll([
        SimpleTableMoreAction.divider,
        if (widget.type == SimpleTableMoreActionType.column)
          SimpleTableMoreAction.enableHeaderColumn,
        if (widget.type == SimpleTableMoreActionType.row)
          SimpleTableMoreAction.enableHeaderRow,
      ]);
    }

    // if the table only contains one row or one column, remove the delete action
    if (widget.tableCellNode.rowLength == 1 &&
        widget.type == SimpleTableMoreActionType.row) {
      actions.remove(SimpleTableMoreAction.delete);
    }

    if (widget.tableCellNode.columnLength == 1 &&
        widget.type == SimpleTableMoreActionType.column) {
      actions.remove(SimpleTableMoreAction.delete);
    }

    return actions;
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
        break;
      case SimpleTableMoreAction.insertLeft:
        _insertColumnLeft();
        break;
      case SimpleTableMoreAction.insertRight:
        _insertColumnRight();
        break;
      case SimpleTableMoreAction.insertAbove:
        _insertRowAbove();
        break;
      case SimpleTableMoreAction.insertBelow:
        _insertRowBelow();
        break;
      case SimpleTableMoreAction.clearContents:
        _clearContent();
        break;
      case SimpleTableMoreAction.duplicate:
        switch (widget.type) {
          case SimpleTableMoreActionType.column:
            _duplicateColumn();
            break;
          case SimpleTableMoreActionType.row:
            _duplicateRow();
            break;
        }
        break;
      default:
        break;
    }

    PopoverContainer.of(context).close();
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
