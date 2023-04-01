import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:appflowy_editor_plugins/src/table/src/table_action.dart';

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
