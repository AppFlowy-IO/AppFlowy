import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:appflowy_editor_plugins/src/table/src/table_action.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/decoration.dart';

// TODO(zoli): better to have sub context menu
final tableContextMenuItems = [
  [
    ContextMenuItem(
      name: 'Add Column',
      isApplicable: _isSelectionInTable,
      onPressed: (editorState) {
        var tableNode = _getTableCellNode(editorState).parent!;
        final transaction = editorState.transaction;
        addCol(tableNode, transaction);
        editorState.apply(transaction);
      },
    ),
    ContextMenuItem(
      name: 'Add Row',
      isApplicable: _isSelectionInTable,
      onPressed: (editorState) {
        var tableNode = _getTableCellNode(editorState).parent!;
        final transaction = editorState.transaction;
        addRow(tableNode, transaction);
        editorState.apply(transaction);
      },
    ),
    ContextMenuItem(
      name: 'Remove Column',
      isApplicable: (EditorState editorState) {
        if (!_isSelectionInTable(editorState)) {
          return false;
        }
        var tableNode = _getTableCellNode(editorState).parent!;
        return tableNode.attributes['colsLen'] > 1;
      },
      onPressed: (editorState) {
        var node = _getTableCellNode(editorState);
        final transaction = editorState.transaction;
        removeCol(
            node.parent!, node.attributes['position']['col'], transaction);
        editorState.apply(transaction);
      },
    ),
    ContextMenuItem(
      name: 'Remove Row',
      isApplicable: (EditorState editorState) {
        if (!_isSelectionInTable(editorState)) {
          return false;
        }
        var tableNode = _getTableCellNode(editorState).parent!;
        return tableNode.attributes['rowsLen'] > 1;
      },
      onPressed: (editorState) {
        var node = _getTableCellNode(editorState);
        final transaction = editorState.transaction;
        removeRow(
            node.parent!, node.attributes['position']['row'], transaction);
        editorState.apply(transaction);
      },
    ),
    ContextMenuItem(
      name: 'Duplicate Column',
      isApplicable: _isSelectionInTable,
      onPressed: (editorState) {
        var node = _getTableCellNode(editorState);
        final transaction = editorState.transaction;
        duplicateCol(
            node.parent!, node.attributes['position']['col'], transaction);
        editorState.apply(transaction);
      },
    ),
    ContextMenuItem(
      name: 'Duplicate Row',
      isApplicable: _isSelectionInTable,
      onPressed: (editorState) {
        var node = _getTableCellNode(editorState);
        final transaction = editorState.transaction;
        duplicateRow(
            node.parent!, node.attributes['position']['row'], transaction);
        editorState.apply(transaction);
      },
    ),
    ContextMenuItem(
      name: 'Column Background Color',
      isApplicable: _isSelectionInTable,
      onPressed: (editorState) {
        var node = _getTableCellNode(editorState);
        _showColorMenu(node, editorState, node.attributes['position']['col'],
            setColBgColor);
      },
    ),
    ContextMenuItem(
      name: 'Row Background Color',
      isApplicable: _isSelectionInTable,
      onPressed: (editorState) {
        var node = _getTableCellNode(editorState);
        _showColorMenu(node, editorState, node.attributes['position']['row'],
            setRowBgColor);
      },
    ),
  ],
];

bool _isSelectionInTable(EditorState editorState) {
  var selection = editorState.service.selectionService.currentSelection.value;
  if (selection == null || !selection.isSingle) {
    return false;
  }

  var node = editorState.service.selectionService.currentSelectedNodes.first;

  return node.id == kTableCellType || node.parent?.type == kTableCellType;
}

Node _getTableCellNode(EditorState editorState) {
  var node = editorState.service.selectionService.currentSelectedNodes.first;
  return node.id == kTableCellType ? node : node.parent!;
}

OverlayEntry? _colorMenuOverlay;
EditorState? _editorState;

void _showColorMenu(
  Node node,
  EditorState editorState,
  int rowcol,
  void Function(Node, int, Transaction, String?) action,
) {
  late Rect matchRect = node.rect;

  _dismissColorMenu();
  _editorState = editorState;

  _colorMenuOverlay = OverlayEntry(builder: (context) {
    return Positioned(
      top: matchRect.bottom - 15,
      left: matchRect.left + 15,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 180, maxHeight: 600),
          decoration: FlowyDecoration.decoration(
            Theme.of(context).cardColor,
            Theme.of(context).colorScheme.shadow.withOpacity(0.15),
          ),
          child: FlowyColorPicker(
            colors: FlowyTint.values
                .map((t) => ColorOption(
                      color: t.color(context),
                      name: t.tintName(AppFlowyEditorLocalizations.current),
                    ))
                .toList(),
            selected: node.attributes['backgroundColor'] != null
                ? FlowyTint.fromJson(node.attributes['backgroundColor'])
                    .color(context)
                : null,
            onTap: (color, index) {
              final transaction = editorState.transaction;
              String? color = FlowyTint.values[index].name;
              color =
                  color == node.attributes['backgroundColor'] ? null : color;
              action(node.parent!, rowcol, transaction, color);
              editorState.apply(transaction);
              _dismissColorMenu();
            },
          ),
        ),
      ),
    );
  });
  Overlay.of(node.key.currentContext!).insert(_colorMenuOverlay!);

  editorState.service.scrollService?.disable();
  editorState.service.keyboardService?.disable();
  editorState.service.selectionService.currentSelection
      .addListener(_dismissColorMenu);
}

void _dismissColorMenu() {
  // workaround: SelectionService has been released after hot reload.
  final isSelectionDisposed =
      _editorState?.service.selectionServiceKey.currentState == null;
  if (isSelectionDisposed) {
    return;
  }
  if (_editorState?.service.selectionService.currentSelection.value == null) {
    return;
  }
  _colorMenuOverlay?.remove();
  _colorMenuOverlay = null;

  _editorState?.service.scrollService?.enable();
  _editorState?.service.keyboardService?.enable();
  _editorState?.service.selectionService.currentSelection
      .removeListener(_dismissColorMenu);
  _editorState = null;
}
