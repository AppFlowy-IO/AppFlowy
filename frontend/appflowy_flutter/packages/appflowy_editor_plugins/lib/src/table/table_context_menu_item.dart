import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:appflowy_editor_plugins/src/table/src/table_action.dart';

final tableContextMenuItems = [
  [
    ContextMenuItem(
      name: 'Add Column',
      isApplicable: isSelectionInTable,
      onPressed: (editorState) {
        var tableNode = getTableCellNode(editorState).parent!;
        final transaction = editorState.transaction;
        addCol(tableNode, transaction);
        editorState.apply(transaction);
      },
    ),
    ContextMenuItem(
      name: 'Add Row',
      isApplicable: isSelectionInTable,
      onPressed: (editorState) {
        var tableNode = getTableCellNode(editorState).parent!;
        final transaction = editorState.transaction;
        addRow(tableNode, transaction);
        editorState.apply(transaction);
      },
    ),
    ContextMenuItem(
      name: 'Remove Column',
      isApplicable: (EditorState editorState) {
        if (!isSelectionInTable(editorState)) {
          return false;
        }
        var tableNode = getTableCellNode(editorState).parent!;
        return tableNode.attributes['colsLen'] > 1;
      },
      onPressed: (editorState) {
        var node = getTableCellNode(editorState);
        final transaction = editorState.transaction;
        removeCol(
            node.parent!, node.attributes['position']['col'], transaction);
        editorState.apply(transaction);
      },
    ),
    ContextMenuItem(
      name: 'Remove Row',
      isApplicable: (EditorState editorState) {
        if (!isSelectionInTable(editorState)) {
          return false;
        }
        var tableNode = getTableCellNode(editorState).parent!;
        return tableNode.attributes['rowsLen'] > 1;
      },
      onPressed: (editorState) {
        var node = getTableCellNode(editorState);
        final transaction = editorState.transaction;
        removeRow(
            node.parent!, node.attributes['position']['row'], transaction);
        editorState.apply(transaction);
      },
    ),
  ],
];

bool isSelectionInTable(EditorState editorState) {
  var selection = editorState.service.selectionService.currentSelection.value;
  if (selection == null || !selection.isSingle) {
    return false;
  }

  var node = editorState.service.selectionService.currentSelectedNodes.first;

  return node.id == kTableCellType || node.parent?.type == kTableCellType;
}

Node getTableCellNode(EditorState editorState) {
  var node = editorState.service.selectionService.currentSelectedNodes.first;
  return node.id == kTableCellType ? node : node.parent!;
}
