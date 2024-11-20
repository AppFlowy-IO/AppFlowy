import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_cell_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_row_block_component.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

typedef TableCellPosition = (int, int);

extension TableOperations on EditorState {
  Future<void> addRowInTable(Node node) async {
    await insertRowInTable(node, node.columnLength);
  }

  Future<void> addColumnInTable(Node node) async {
    await insertColumnInTable(node, node.rowLength);
  }

  Future<void> addColumnAndRowInTable(Node node) async {
    assert(node.type == SimpleTableBlockKeys.type);

    if (node.type != SimpleTableBlockKeys.type) {
      return;
    }

    await addColumnInTable(node);
    await addRowInTable(node);
  }

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
}
