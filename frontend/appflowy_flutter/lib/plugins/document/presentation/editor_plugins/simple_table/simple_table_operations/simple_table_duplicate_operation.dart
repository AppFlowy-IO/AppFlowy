import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_operations/simple_table_map_operation.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_operations/simple_table_node_extension.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

extension TableDuplicationOperations on EditorState {
  /// Duplicate a row at the given index.
  ///
  /// Before:
  /// | 0 | 1 | 2 |
  /// | 3 | 4 | 5 | ← This row will be duplicated
  ///
  /// Call this function with index 1 will duplicate the second row of the table.
  ///
  /// After:
  /// | 0 | 1 | 2 |
  /// | 3 | 4 | 5 |
  /// | 3 | 4 | 5 | ← New row
  Future<void> duplicateRowInTable(Node node, int index) async {
    assert(node.type == SimpleTableBlockKeys.type);

    if (node.type != SimpleTableBlockKeys.type) {
      return;
    }

    final columnLength = node.columnLength;
    final rowLength = node.rowLength;

    if (index < 0 || index >= rowLength) {
      Log.warn(
        'duplicate row: index out of range: $index, row length: $rowLength',
      );
      return;
    }

    Log.info(
      'duplicate row in table ${node.id} at index: $index, column length: $columnLength, row length: $rowLength',
    );

    final attributes = node.mapTableAttributes(
      node,
      type: TableMapOperationType.duplicateRow,
      index: index,
    );

    final newRow = node.children[index].deepCopy();
    final transaction = this.transaction;
    final path = index >= columnLength
        ? node.children.last.path.next
        : node.children[index].path;
    transaction.insertNode(path, newRow);
    if (attributes != null) {
      transaction.updateNode(node, attributes);
    }
    await apply(transaction);
  }

  Future<void> duplicateColumnInTable(Node node, int index) async {
    assert(node.type == SimpleTableBlockKeys.type);

    if (node.type != SimpleTableBlockKeys.type) {
      return;
    }

    final columnLength = node.columnLength;
    final rowLength = node.rowLength;

    if (index < 0 || index >= columnLength) {
      Log.warn(
        'duplicate column: index out of range: $index, column length: $columnLength',
      );
      return;
    }

    Log.info(
      'duplicate column in table ${node.id} at index: $index, column length: $columnLength, row length: $rowLength',
    );

    final attributes = node.mapTableAttributes(
      node,
      type: TableMapOperationType.duplicateColumn,
      index: index,
    );

    final transaction = this.transaction;
    for (var i = 0; i < rowLength; i++) {
      final row = node.children[i];
      final path = index >= rowLength
          ? row.children.last.path.next
          : row.children[index].path;
      final newCell = row.children[index].deepCopy();
      transaction.insertNode(
        path,
        newCell,
      );
    }
    if (attributes != null) {
      transaction.updateNode(node, attributes);
    }
    await apply(transaction);
  }
}
