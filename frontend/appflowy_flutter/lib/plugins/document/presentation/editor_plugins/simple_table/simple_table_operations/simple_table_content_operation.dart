import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_cell_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_operations/simple_table_node_extension.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/services.dart';

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
  Future<void> clearContentAtRowIndex({
    required Node tableNode,
    required int rowIndex,
  }) async {
    assert(tableNode.type == SimpleTableBlockKeys.type);

    if (tableNode.type != SimpleTableBlockKeys.type) {
      return;
    }

    if (rowIndex < 0 || rowIndex >= tableNode.rowLength) {
      Log.warn('clear content in row: index out of range: $rowIndex');
      return;
    }

    Log.info('clear content in row: $rowIndex in table ${tableNode.id}');

    final transaction = this.transaction;

    final row = tableNode.children[rowIndex];
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
  Future<void> clearContentAtColumnIndex({
    required Node tableNode,
    required int columnIndex,
  }) async {
    assert(tableNode.type == SimpleTableBlockKeys.type);

    if (tableNode.type != SimpleTableBlockKeys.type) {
      return;
    }

    if (columnIndex < 0 || columnIndex >= tableNode.columnLength) {
      Log.warn('clear content in column: index out of range: $columnIndex');
      return;
    }

    Log.info('clear content in column: $columnIndex in table ${tableNode.id}');

    final transaction = this.transaction;
    for (var i = 0; i < tableNode.rowLength; i++) {
      final row = tableNode.children[i];
      final cell = columnIndex >= row.children.length
          ? row.children.last
          : row.children[columnIndex];
      transaction.insertNode(cell.path.next, simpleTableCellBlockNode());
      transaction.deleteNode(cell);
    }
    await apply(transaction);
  }

  /// Copy the selected column to the clipboard.
  ///
  /// Only support plain text.
  Future<void> copyColumn({
    required Node tableNode,
    required int columnIndex,
  }) async {
    assert(tableNode.type == SimpleTableBlockKeys.type);

    if (tableNode.type != SimpleTableBlockKeys.type) {
      return;
    }

    if (columnIndex < 0 || columnIndex >= tableNode.columnLength) {
      Log.warn('copy column: index out of range: $columnIndex');
      return;
    }

    final List<String> content = [];

    for (var i = 0; i < tableNode.rowLength; i++) {
      final row = tableNode.children[i];
      final cell = columnIndex >= row.children.length
          ? row.children.last
          : row.children[columnIndex];
      final plainText = getTextInSelection(
        Selection(
          start: Position(path: cell.path),
          end: Position(path: cell.path.next),
        ),
      );
      content.add(plainText.join('\n'));
    }

    await Clipboard.setData(ClipboardData(text: content.join('\n')));
  }
}
