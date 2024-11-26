import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_cell_block_component.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

extension TableCommandExtension on EditorState {
  /// Return a tuple, the first element is a boolean indicating whether the current selection is in a table cell,
  /// the second element is the node that is the parent of the table cell if the current selection is in a table cell,
  /// otherwise it is null.
  /// The third element is the node that is the current selection.
  (bool isInTableCell, Selection? selection, Node? tableCellNode, Node? node)
      isCurrentSelectionInTableCell() {
    final selection = this.selection;
    if (selection == null || !selection.isCollapsed) {
      return (false, null, null, null);
    }

    final node = document.nodeAtPath(selection.end.path);
    final tableCellParent = node?.findParent(
      (node) => node.type == SimpleTableCellBlockKeys.type,
    );
    final isInTableCell = tableCellParent != null;
    return (isInTableCell, selection, tableCellParent, node);
  }
}
