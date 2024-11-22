import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/table_operations/table_node_extension.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

extension TableDeletionOperations on EditorState {
  /// Delete a row at the given index.
  ///
  /// Before:
  /// Given index: 0
  /// Row 1: |   |   |   | ← This row will be deleted
  /// Row 2: |   |   |   |
  ///
  /// Call this function with index 0 will delete the first row of the table.
  ///
  /// After:
  /// Row 1: |   |   |   |
  Future<void> deleteRowInTable(
    Node node,
    int index,
  ) async {
    assert(node.type == SimpleTableBlockKeys.type);

    if (node.type != SimpleTableBlockKeys.type) {
      return;
    }

    final rowLength = node.columnLength;
    if (index < 0 || index >= rowLength) {
      Log.warn(
        'delete row: index out of range: $index, row length: $rowLength',
      );
      return;
    }

    Log.info('delete row: $index in table ${node.id}');

    final row = node.children[index];
    final transaction = this.transaction;
    transaction.deleteNode(row);
    await apply(transaction);
  }

  /// Delete a column at the given index.
  ///
  /// Before:
  /// Given index: 2
  ///                  ↓ This column will be deleted
  /// Row 1: | 0 | 1 | 2 |
  /// Row 2: |   |   |   |
  ///
  /// Call this function with index 2 will delete the third column of the table.
  ///
  /// After:
  /// Row 1: | 0 | 1 |
  /// Row 2: |   |   |
  Future<void> deleteColumnInTable(Node node, int index) async {
    assert(node.type == SimpleTableBlockKeys.type);

    if (node.type != SimpleTableBlockKeys.type) {
      return;
    }

    final rowLength = node.rowLength;
    final columnLength = node.columnLength;
    if (index < 0 || index >= rowLength) {
      Log.warn(
        'delete column: index out of range: $index, row length: $rowLength',
      );
      return;
    }

    Log.info('delete column: $index in table ${node.id}');

    final transaction = this.transaction;
    for (var i = 0; i < columnLength; i++) {
      final row = node.children[i];
      transaction.deleteNode(row.children[index]);
    }
    await apply(transaction);
  }

  Future<void> duplicateRowInTable(Node node, int index) async {
    assert(node.type == SimpleTableBlockKeys.type);

    if (node.type != SimpleTableBlockKeys.type) {
      return;
    }

    final columnLength = node.columnLength;
    final rowLength = node.rowLength;

    Log.info('add row in table ${node.id} at index: $index');
    Log.info('current column length: $columnLength, row length: $rowLength');

    if (index < 0) {
      Log.warn(
        'insert column: index out of range: $index, column length: $columnLength',
      );
      return;
    }

    final newRow = node.children[index].copyWith();
    final transaction = this.transaction;
    final path = index >= columnLength
        ? node.children.last.path.next
        : node.children[index].path;
    transaction.insertNode(path, newRow);
    final columnColors = node.attributes[SimpleTableBlockKeys.columnColors] ??
        SimpleTableColorMap();
    try {
      final columnColor = columnColors[index.toString()];
      if (columnColor != null) {
        columnColors[(index + 1).toString()] = columnColor;
      }
    } catch (e) {
      Log.warn('update column colors: $e');
    }
    final attributes = {
      ...node.attributes,
      SimpleTableBlockKeys.columnColors: columnColors,
    };
    transaction.updateNode(node, attributes);
    await apply(transaction);
  }

  Future<void> duplicateColumnInTable(Node node, int index) async {
    assert(node.type == SimpleTableBlockKeys.type);

    if (node.type != SimpleTableBlockKeys.type) {
      return;
    }

    final columnLength = node.columnLength;
    final rowLength = node.rowLength;

    Log.info('add column in table ${node.id} at index: $index');
    Log.info(
      'current column length: $columnLength, row length: $rowLength',
    );

    final transaction = this.transaction;
    for (var i = 0; i < columnLength; i++) {
      final row = node.children[i];
      final path = index >= rowLength
          ? row.children.last.path.next
          : row.children[index].path;
      final newCell = row.children[index].copyWith();
      transaction.insertNode(
        path,
        newCell,
      );
    }
    await apply(transaction);
  }
}
