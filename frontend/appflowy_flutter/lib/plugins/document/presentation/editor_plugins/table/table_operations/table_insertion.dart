import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_cell_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_row_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/table_operations/table_map_operation.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/table_operations/table_node_extension.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

extension TableInsertionOperations on EditorState {
  /// Add a row at the end of the table.
  ///
  /// Before:
  /// Row 1: |   |   |   |
  /// Row 2: |   |   |   |
  ///
  /// Call this function will add a row at the end of the table.
  ///
  /// After:
  /// Row 1: |   |   |   |
  /// Row 2: |   |   |   |
  /// Row 3: |   |   |   | ← New row
  ///
  Future<void> addRowInTable(Node node) async {
    assert(node.type == SimpleTableBlockKeys.type);

    if (node.type != SimpleTableBlockKeys.type) {
      Log.warn('node is not a table node: ${node.type}');
      return;
    }

    await insertRowInTable(node, node.rowLength);
  }

  /// Add a column at the end of the table.
  ///
  /// Before:
  /// Row 1: |   |   |   |
  /// Row 2: |   |   |   |
  ///
  /// Call this function will add a column at the end of the table.
  ///
  /// After:
  ///                      ↓ New column
  /// Row 1: |   |   |   |   |
  /// Row 2: |   |   |   |   |
  Future<void> addColumnInTable(Node node) async {
    assert(node.type == SimpleTableBlockKeys.type);

    if (node.type != SimpleTableBlockKeys.type) {
      Log.warn('node is not a table node: ${node.type}');
      return;
    }

    await insertColumnInTable(node, node.columnLength);
  }

  /// Add a column and a row at the end of the table.
  ///
  /// Before:
  /// Row 1: |   |   |   |
  /// Row 2: |   |   |   |
  ///
  /// Call this function will add a column and a row at the end of the table.
  ///
  /// After:
  ///                      ↓ New column
  /// Row 1: |   |   |   |   |
  /// Row 2: |   |   |   |   |
  /// Row 3: |   |   |   |   | ← New row
  Future<void> addColumnAndRowInTable(Node node) async {
    assert(node.type == SimpleTableBlockKeys.type);

    if (node.type != SimpleTableBlockKeys.type) {
      return;
    }

    await addColumnInTable(node);
    await addRowInTable(node);
  }

  /// Add a column at the given index.
  ///
  /// Before:
  /// Given index: 1
  /// Row 1: | 0 | 1 |
  /// Row 2: |   |   |
  ///
  /// Call this function with index 1 will add a column at the second position of the table.
  ///
  /// After:       ↓ New column
  /// Row 1: | 0 |   | 1 |
  /// Row 2: |   |   |   |
  Future<void> insertColumnInTable(Node node, int index) async {
    assert(node.type == SimpleTableBlockKeys.type);

    if (node.type != SimpleTableBlockKeys.type) {
      Log.warn('node is not a table node: ${node.type}');
      return;
    }

    final columnLength = node.rowLength;
    final rowLength = node.columnLength;

    Log.info(
      'add column in table ${node.id} at index: $index, column length: $columnLength, row length: $rowLength',
    );

    if (index < 0) {
      Log.warn(
        'insert column: index out of range: $index, column length: $columnLength',
      );
      return;
    }

    final transaction = this.transaction;
    for (var i = 0; i < columnLength; i++) {
      final row = node.children[i];
      // if the index is greater than the row length, we add the new column at the end of the row.
      final path = index >= rowLength
          ? row.children.last.path.next
          : row.children[index].path;
      transaction.insertNode(
        path,
        simpleTableCellBlockNode(),
      );
    }
    final attributes = node.mapTableAttributes(
      node,
      type: TableMapOperationType.insertColumn,
      index: index,
    );
    if (attributes != null) {
      transaction.updateNode(node, attributes);
    }
    await apply(transaction);
  }

  /// Add a row at the given index.
  ///
  /// Before:
  /// Given index: 1
  /// Row 1: |   |   |
  /// Row 2: |   |   |
  ///
  /// Call this function with index 1 will add a row at the second position of the table.
  ///
  /// After:
  /// Row 1: |   |   |
  /// Row 2: |   |   |
  /// Row 3: |   |   | ← New row
  Future<void> insertRowInTable(Node node, int index) async {
    assert(node.type == SimpleTableBlockKeys.type);

    if (node.type != SimpleTableBlockKeys.type) {
      return;
    }

    if (index < 0) {
      Log.warn(
        'insert row: index out of range: $index',
      );
      return;
    }

    final columnLength = node.rowLength;
    final rowLength = node.columnLength;

    Log.info(
      'insert row in table ${node.id} at index: $index, column length: $columnLength, row length: $rowLength',
    );

    final newRow = simpleTableRowBlockNode(
      children: [
        for (var i = 0; i < rowLength; i++) simpleTableCellBlockNode(),
      ],
    );

    final transaction = this.transaction;
    final path = index >= columnLength
        ? node.children.last.path.next
        : node.children[index].path;
    transaction.insertNode(path, newRow);
    final attributes = node.mapTableAttributes(
      node,
      type: TableMapOperationType.insertRow,
      index: index,
    );
    if (attributes != null) {
      transaction.updateNode(node, attributes);
    }
    await apply(transaction);
  }
}
