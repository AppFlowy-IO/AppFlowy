import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/shared_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_constants.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/table_operations.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/table_operations/table_insertion.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/table_operations/table_node_extension.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum SimpleTableMoreActionType {
  column,
  row;

  List<SimpleTableMoreAction> get actions {
    switch (this) {
      case SimpleTableMoreActionType.column:
        return [
          SimpleTableMoreAction.addAbove,
          SimpleTableMoreAction.addBelow,
          SimpleTableMoreAction.duplicate,
          SimpleTableMoreAction.clearContent,
          SimpleTableMoreAction.delete,
          SimpleTableMoreAction.divider,
          SimpleTableMoreAction.align,
          SimpleTableMoreAction.backgroundColor,
        ];
      case SimpleTableMoreActionType.row:
        return [
          SimpleTableMoreAction.addLeft,
          SimpleTableMoreAction.addRight,
          SimpleTableMoreAction.duplicate,
          SimpleTableMoreAction.clearContent,
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
        return FlowySvgs.table_reorder_row_s;
      case SimpleTableMoreActionType.row:
        return FlowySvgs.table_reorder_column_s;
    }
  }
}

enum SimpleTableMoreAction {
  addLeft,
  addRight,
  addAbove,
  addBelow,
  duplicate,
  clearContent,
  delete,
  align,
  backgroundColor,
  enableHeaderColumn,
  enableHeaderRow,
  divider;

  String get name {
    return switch (this) {
      SimpleTableMoreAction.align => 'Align',
      SimpleTableMoreAction.backgroundColor => 'Color',
      SimpleTableMoreAction.enableHeaderColumn => 'Header Column',
      SimpleTableMoreAction.enableHeaderRow => 'Header Row',
      SimpleTableMoreAction.addLeft => 'Insert left',
      SimpleTableMoreAction.addRight => 'Insert right',
      SimpleTableMoreAction.addBelow => 'Insert below',
      SimpleTableMoreAction.addAbove => 'Insert above',
      SimpleTableMoreAction.clearContent => 'Clear content',
      SimpleTableMoreAction.delete => 'Delete',
      SimpleTableMoreAction.duplicate => 'Duplicate',
      SimpleTableMoreAction.divider => throw UnimplementedError(),
    };
  }

  FlowySvgData get leftIconSvg {
    return switch (this) {
      SimpleTableMoreAction.addLeft => FlowySvgs.table_insert_left_s,
      SimpleTableMoreAction.addRight => FlowySvgs.table_insert_right_s,
      SimpleTableMoreAction.addAbove => FlowySvgs.table_insert_above_s,
      SimpleTableMoreAction.addBelow => FlowySvgs.table_insert_below_s,
      SimpleTableMoreAction.duplicate => FlowySvgs.duplicate_s,
      SimpleTableMoreAction.clearContent => FlowySvgs.table_clear_content_s,
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
          ? Alignment.topCenter
          : Alignment.centerLeft,
      child: ValueListenableBuilder<bool>(
        valueListenable: isShowingMenu,
        builder: (context, isShowingMenu, child) {
          return ValueListenableBuilder(
            valueListenable:
                context.read<SimpleTableContext>().hoveringTableCell,
            builder: (context, hoveringTableNode, child) {
              final hoveringIndex =
                  widget.type == SimpleTableMoreActionType.column
                      ? hoveringTableNode?.rowIndex
                      : hoveringTableNode?.columnIndex;

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
      },
      onClose: () {
        widget.isShowingMenu.value = false;

        // clear the selecting index
        context.read<SimpleTableContext>().selectingColumn.value = null;
        context.read<SimpleTableContext>().selectingRow.value = null;
      },
      direction: widget.type == SimpleTableMoreActionType.row
          ? PopoverDirection.bottomWithLeftAligned
          : PopoverDirection.bottomWithCenterAligned,
      offset: widget.type == SimpleTableMoreActionType.row
          ? const Offset(-14, 8)
          : const Offset(24, 14),
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
}

class SimpleTableMoreActionList extends StatelessWidget {
  const SimpleTableMoreActionList({
    super.key,
    required this.type,
    required this.index,
    required this.tableCellNode,
  });

  final SimpleTableMoreActionType type;
  final int index;
  final Node tableCellNode;

  @override
  Widget build(BuildContext context) {
    final actions = type.actions;

    if (index == 0) {
      actions.addAll([
        SimpleTableMoreAction.divider,
        if (type == SimpleTableMoreActionType.column)
          SimpleTableMoreAction.enableHeaderRow,
        if (type == SimpleTableMoreActionType.row)
          SimpleTableMoreAction.enableHeaderColumn,
      ]);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: actions
          .map(
            (action) => SimpleTableMoreActionItem(
              type: type,
              action: action,
              tableCellNode: tableCellNode,
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
  });

  final SimpleTableMoreActionType type;
  final SimpleTableMoreAction action;
  final Node tableCellNode;

  @override
  State<SimpleTableMoreActionItem> createState() =>
      _SimpleTableMoreActionItemState();
}

class _SimpleTableMoreActionItemState extends State<SimpleTableMoreActionItem> {
  ValueNotifier<bool> isEnableHeader = ValueNotifier(false);

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
    );
  }

  Widget _buildBackgroundColorMenu(BuildContext context) {
    return SimpleTableBackgroundColorMenu(
      type: widget.type,
      tableCellNode: widget.tableCellNode,
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
      case SimpleTableMoreAction.addLeft:
        _insertColumnLeft();
        break;
      case SimpleTableMoreAction.addRight:
        _insertColumnRight();
        break;
      case SimpleTableMoreAction.addAbove:
        _insertRowAbove();
        break;
      case SimpleTableMoreAction.addBelow:
        _insertRowBelow();
        break;
      case SimpleTableMoreAction.clearContent:
        _clearContent();
        break;
      case SimpleTableMoreAction.duplicate:
        switch (widget.type) {
          case SimpleTableMoreActionType.column:
            _duplicateRow();
            break;
          case SimpleTableMoreActionType.row:
            _duplicateColumn();
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
    final (table, _, cellPosition) = value;
    final columnIndex = cellPosition.$1;
    final editorState = context.read<EditorState>();
    editorState.duplicateRowInTable(table, columnIndex);
  }

  void _duplicateColumn() {
    final value = _getTableAndTableCellAndCellPosition();
    if (value == null) {
      return;
    }
    final (table, _, cellPosition) = value;
    final rowIndex = cellPosition.$2;
    final editorState = context.read<EditorState>();
    editorState.duplicateColumnInTable(table, rowIndex);
  }

  void _toggleEnableHeader() {
    final value = _getTableAndTableCellAndCellPosition();
    if (value == null) {
      return;
    }

    isEnableHeader.value = !isEnableHeader.value;

    final (table, _, _) = value;
    final editorState = context.read<EditorState>();
    if (widget.type == SimpleTableMoreActionType.row) {
      editorState.toggleEnableHeaderColumn(
        table,
        isEnableHeader.value,
      );
    } else if (widget.type == SimpleTableMoreActionType.column) {
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
    final (table, _, cellPosition) = value;
    final editorState = context.read<EditorState>();
    if (widget.type == SimpleTableMoreActionType.column) {
      editorState.clearContentAtColumnIndex(table, cellPosition.$1);
    } else if (widget.type == SimpleTableMoreActionType.row) {
      editorState.clearContentAtRowIndex(table, cellPosition.$2);
    }
  }

  void _insertColumnLeft() {
    final value = _getTableAndTableCellAndCellPosition();
    if (value == null) {
      return;
    }
    final (table, _, cellPosition) = value;
    final rowIndex = cellPosition.$2;
    final editorState = context.read<EditorState>();
    editorState.insertColumnInTable(table, rowIndex);
  }

  void _insertColumnRight() {
    final value = _getTableAndTableCellAndCellPosition();
    if (value == null) {
      return;
    }
    final (table, _, cellPosition) = value;
    final rowIndex = cellPosition.$2;
    final editorState = context.read<EditorState>();
    editorState.insertColumnInTable(table, rowIndex + 1);
  }

  void _insertRowAbove() {
    final value = _getTableAndTableCellAndCellPosition();
    if (value == null) {
      return;
    }
    final (table, _, cellPosition) = value;
    final columnIndex = cellPosition.$1;
    final editorState = context.read<EditorState>();
    editorState.insertRowInTable(table, columnIndex);
  }

  void _insertRowBelow() {
    final value = _getTableAndTableCellAndCellPosition();
    if (value == null) {
      return;
    }
    final (table, _, cellPosition) = value;
    final columnIndex = cellPosition.$1;
    final editorState = context.read<EditorState>();
    editorState.insertRowInTable(table, columnIndex + 1);
  }

  void _deleteRow() {
    final value = _getTableAndTableCellAndCellPosition();
    if (value == null) {
      return;
    }
    final (table, _, cellPosition) = value;
    final rowIndex = cellPosition.$2;
    final editorState = context.read<EditorState>();
    editorState.deleteColumnInTable(table, rowIndex);
  }

  void _deleteColumn() {
    final value = _getTableAndTableCellAndCellPosition();
    if (value == null) {
      return;
    }
    final (table, _, cellPosition) = value;
    final columnIndex = cellPosition.$1;
    final editorState = context.read<EditorState>();
    editorState.deleteRowInTable(table, columnIndex);
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
        isEnableHeader.value =
            table.attributes[SimpleTableBlockKeys.enableHeaderRow] as bool? ??
                false;
      } else if (widget.type == SimpleTableMoreActionType.row) {
        isEnableHeader.value = table
                .attributes[SimpleTableBlockKeys.enableHeaderColumn] as bool? ??
            false;
      }
    }
  }
}
