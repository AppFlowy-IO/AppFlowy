import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_operations/simple_table_map_operation.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_operations/simple_table_node_extension.dart';
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
    Node tableNode,
    int rowIndex, {
    bool inMemoryUpdate = false,
  }) async {
    assert(tableNode.type == SimpleTableBlockKeys.type);

    if (tableNode.type != SimpleTableBlockKeys.type) {
      return;
    }

    final rowLength = tableNode.rowLength;
    if (rowIndex < 0 || rowIndex >= rowLength) {
      Log.warn(
        'delete row: index out of range: $rowIndex, row length: $rowLength',
      );
      return;
    }

    Log.info('delete row: $rowIndex in table ${tableNode.id}');

    final attributes = tableNode.mapTableAttributes(
      tableNode,
      type: TableMapOperationType.deleteRow,
      index: rowIndex,
    );

    final row = tableNode.children[rowIndex];
    final transaction = this.transaction;
    transaction.deleteNode(row);
    if (attributes != null) {
      transaction.updateNode(tableNode, attributes);
    }
    await apply(
      transaction,
      options: ApplyOptions(
        inMemoryUpdate: inMemoryUpdate,
      ),
    );
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
  Future<void> deleteColumnInTable(
    Node tableNode,
    int columnIndex, {
    bool inMemoryUpdate = false,
  }) async {
    assert(tableNode.type == SimpleTableBlockKeys.type);

    if (tableNode.type != SimpleTableBlockKeys.type) {
      return;
    }

    final rowLength = tableNode.rowLength;
    final columnLength = tableNode.columnLength;
    if (columnIndex < 0 || columnIndex >= columnLength) {
      Log.warn(
        'delete column: index out of range: $columnIndex, column length: $columnLength',
      );
      return;
    }

    Log.info('delete column: $columnIndex in table ${tableNode.id}');

    final attributes = tableNode.mapTableAttributes(
      tableNode,
      type: TableMapOperationType.deleteColumn,
      index: columnIndex,
    );

    final transaction = this.transaction;
    for (var i = 0; i < rowLength; i++) {
      final row = tableNode.children[i];
      transaction.deleteNode(row.children[columnIndex]);
    }
    if (attributes != null) {
      transaction.updateNode(tableNode, attributes);
    }
    await apply(
      transaction,
      options: ApplyOptions(
        inMemoryUpdate: inMemoryUpdate,
      ),
    );
  }
}
