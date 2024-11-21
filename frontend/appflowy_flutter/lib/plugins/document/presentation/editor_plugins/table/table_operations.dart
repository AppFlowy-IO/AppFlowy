import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_cell_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_row_block_component.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

typedef TableCellPosition = (int, int);

extension TableOperations on EditorState {
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
    await insertRowInTable(node, node.columnLength);
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
    await insertColumnInTable(node, node.rowLength);
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

    final columnLength = node.columnLength;
    if (index < 0 || index >= columnLength) {
      Log.warn(
        'delete column: index out of range: $index, column length: $columnLength',
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
      transaction.insertNode(
        path,
        simpleTableCellBlockNode(),
      );
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
    await apply(transaction);
  }

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
  Future<void> clearContentAtColumnIndex(Node node, int index) async {
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
  Future<void> clearContentAtRowIndex(Node node, int index) async {
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

  /// Toggle the enable header column of the table.
  Future<void> toggleEnableHeaderColumn(Node node, bool enable) async {
    assert(node.type == SimpleTableBlockKeys.type);

    if (node.type != SimpleTableBlockKeys.type) {
      return;
    }

    Log.info('toggle enable header column: $enable in table ${node.id}');

    final transaction = this.transaction;
    transaction.updateNode(node, {
      SimpleTableBlockKeys.enableHeaderColumn: enable,
    });
    await apply(transaction);
  }

  /// Toggle the enable header row of the table.
  Future<void> toggleEnableHeaderRow(Node node, bool enable) async {
    assert(node.type == SimpleTableBlockKeys.type);

    if (node.type != SimpleTableBlockKeys.type) {
      return;
    }

    Log.info('toggle enable header row: $enable in table ${node.id}');

    final transaction = this.transaction;
    transaction.updateNode(node, {
      SimpleTableBlockKeys.enableHeaderRow: enable,
    });
    await apply(transaction);
  }
}

extension TableNodeExtension on Node {
  int get columnLength {
    if (type != SimpleTableBlockKeys.type) {
      return -1;
    }

    return children.length;
  }

  int get rowLength {
    if (type != SimpleTableBlockKeys.type) {
      return -1;
    }

    return children.firstOrNull?.children.length ?? 0;
  }

  TableCellPosition get cellPosition {
    assert(type == SimpleTableCellBlockKeys.type);

    final path = this.path;

    if (path.length < 2) {
      return (-1, -1);
    }

    return (
      path.parent.last,
      path.last,
    );
  }

  bool get isHeaderColumnEnabled {
    Node? tableNode;

    if (type == SimpleTableBlockKeys.type) {
      tableNode = this;
    } else if (type == SimpleTableRowBlockKeys.type) {
      tableNode = parent;
    } else if (type == SimpleTableCellBlockKeys.type) {
      tableNode = parent?.parent;
    }

    if (tableNode == null || tableNode.type != SimpleTableBlockKeys.type) {
      return false;
    }

    return tableNode.attributes[SimpleTableBlockKeys.enableHeaderColumn] ??
        false;
  }

  bool get isHeaderRowEnabled {
    Node? tableNode;

    if (type == SimpleTableBlockKeys.type) {
      tableNode = this;
    } else if (type == SimpleTableRowBlockKeys.type) {
      tableNode = parent;
    } else if (type == SimpleTableCellBlockKeys.type) {
      tableNode = parent?.parent;
    }

    if (tableNode == null || tableNode.type != SimpleTableBlockKeys.type) {
      return false;
    }

    return tableNode.attributes[SimpleTableBlockKeys.enableHeaderRow] ?? false;
  }
}
