import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_cell_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/table_operations/table_node_extension.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

extension TableContentOperation on EditorState {
  /// Clear the content of the column at the given index.
  ///
  /// Before:
  /// Given column index: 0
  /// Row 1: | 0 | 1 | ← The content of these cells will be cleared
  /// Row 2: | 2 | 3 |
  ///
  /// Call this function with column index 0 will clear the first column of the table.
  ///
  /// After:
  /// Row 1: |   |   |
  /// Row 2: | 2 | 3 |
  Future<void> clearContentAtRowIndex(Node node, int index) async {
    assert(node.type == SimpleTableBlockKeys.type);

    if (node.type != SimpleTableBlockKeys.type) {
      return;
    }

    if (index < 0 || index >= node.columnLength) {
      Log.warn('clear content in column: index out of range: $index');
      return;
    }

    Log.info('clear content in column: $index in table ${node.id}');

    final transaction = this.transaction;

    final row = node.children[index];
    for (var i = 0; i < row.children.length; i++) {
      final cell = row.children[i];
      transaction.insertNode(cell.path.next, simpleTableCellBlockNode());
      transaction.deleteNode(cell);
    }
    await apply(transaction);
  }

  /// Clear the content of the row at the given index.
  ///
  /// Before:
  /// Given row index: 1
  ///              ↓ The content of these cells will be cleared
  /// Row 1: | 0 | 1 |
  /// Row 2: | 2 | 3 |
  ///
  /// Call this function with row index 1 will clear the second row of the table.
  ///
  /// After:
  /// Row 1: | 0 |   |
  /// Row 2: | 2 |   |
  Future<void> clearContentAtColumnIndex(Node node, int index) async {
    assert(node.type == SimpleTableBlockKeys.type);

    if (node.type != SimpleTableBlockKeys.type) {
      return;
    }

    if (index < 0 || index >= node.rowLength) {
      Log.warn('clear content in row: index out of range: $index');
      return;
    }

    Log.info('clear content in row: $index in table ${node.id}');

    final transaction = this.transaction;
    for (var i = 0; i < node.columnLength; i++) {
      final row = node.children[i];
      final cell = index >= row.children.length
          ? row.children.last
          : row.children[index];
      transaction.insertNode(cell.path.next, simpleTableCellBlockNode());
      transaction.deleteNode(cell);
    }
    await apply(transaction);
  }
}
