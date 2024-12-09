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
    Node node,
    int index, {
    bool inMemoryUpdate = false,
  }) async {
    assert(node.type == SimpleTableBlockKeys.type);

    if (node.type != SimpleTableBlockKeys.type) {
      return;
    }

    final rowLength = node.rowLength;
    if (index < 0 || index >= rowLength) {
      Log.warn(
        'delete row: index out of range: $index, row length: $rowLength',
      );
      return;
    }

    Log.info('delete row: $index in table ${node.id}');

    final attributes = node.mapTableAttributes(
      node,
      type: TableMapOperationType.deleteRow,
      index: index,
    );

    final row = node.children[index];
    final transaction = this.transaction;
    transaction.deleteNode(row);
    if (attributes != null) {
      transaction.updateNode(node, attributes);
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
  Future<void> deleteColumnInTable(Node node, int index) async {
    assert(node.type == SimpleTableBlockKeys.type);

    if (node.type != SimpleTableBlockKeys.type) {
      return;
    }

    final rowLength = node.rowLength;
    final columnLength = node.columnLength;
    if (index < 0 || index >= columnLength) {
      Log.warn(
        'delete column: index out of range: $index, column length: $columnLength',
      );
      return;
    }

    Log.info('delete column: $index in table ${node.id}');

    final attributes = node.mapTableAttributes(
      node,
      type: TableMapOperationType.deleteColumn,
      index: index,
    );

    final transaction = this.transaction;
    for (var i = 0; i < rowLength; i++) {
      final row = node.children[i];
      transaction.deleteNode(row.children[index]);
    }
    if (attributes != null) {
      transaction.updateNode(node, attributes);
    }
    await apply(transaction);
  }
}
