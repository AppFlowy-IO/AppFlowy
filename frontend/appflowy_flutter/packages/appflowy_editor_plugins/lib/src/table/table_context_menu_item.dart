import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:appflowy_editor_plugins/src/table/src/table_action.dart';

final tableContextMenuItems = [
  [
    ContextMenuItem(
      name: 'Add Column',
      isApplicable: isSelectionInTable,
      onPressed: (editorState) {
        var node = getTableNode(editorState);
        addColHandler(node, editorState);
      },
    ),
    ContextMenuItem(
      name: 'Add Row',
      isApplicable: isSelectionInTable,
      onPressed: (editorState) {
        var node = getTableNode(editorState);
        addRowHandler(node, editorState);
      },
    ),
    //ContextMenuItem(
    //  name: 'Remove Column',
    //  isApplicable: isSelectionInTable,
    //  onPressed: (editorState) {
    //    removeColHandler(node);
    //  },
    //),
    //ContextMenuItem(
    //  name: 'Remove Row',
    //  isApplicable: isSelectionInTable,
    //  onPressed: (editorState) {
    //    removeRowHandler(node);
    //  },
    //),
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

Node getTableNode(EditorState editorState) {
  var node = editorState.service.selectionService.currentSelectedNodes.first;
  return node.id == kTableCellType ? node.parent! : node.parent!.parent!;
}

addColHandler(Node node, EditorState editorState) {
  final transaction = editorState.transaction;
  addCol(node, transaction);
  editorState.apply(transaction);
}

addRowHandler(Node node, EditorState editorState) {
  final transaction = editorState.transaction;
  addRow(node, transaction);
  editorState.apply(transaction);
}
