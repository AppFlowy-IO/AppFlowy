import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_cell_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/table/simple_table_row_block_component.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

extension TableOperations on EditorState {
  Future<void> addRowInTable(Node node) async {
    assert(node.type == SimpleTableBlockKeys.type);

    if (node.type != SimpleTableBlockKeys.type) {
      return;
    }

    final columnLength = node.columnLength;
    final rowLength = node.rowLength;

    Log.info('add row in table ${node.id}');
    Log.info('current column length: $columnLength, row length: $rowLength');

    final newRow = simpleTableRowBlockNode(
      children: [
        for (var i = 0; i < rowLength; i++) simpleTableCellBlockNode(),
      ],
    );

    final transaction = this.transaction;
    final lastColumn = node.children.last;
    transaction.insertNode(lastColumn.path.next, newRow);
    await apply(transaction);
  }

  Future<void> addColumnInTable(Node node) async {
    assert(node.type == SimpleTableBlockKeys.type);

    if (node.type != SimpleTableBlockKeys.type) {
      return;
    }

    final columnLength = node.columnLength;
    final rowLength = node.rowLength;

    Log.info('add column in table ${node.id}');
    Log.info('current column length: $columnLength, row length: $rowLength');

    final transaction = this.transaction;
    for (var i = 0; i < columnLength; i++) {
      final row = node.children[i];
      transaction.insertNode(
        row.children.last.path.next,
        simpleTableCellBlockNode(),
      );
    }
    await apply(transaction);
  }

  Future<void> addColumnAndRowInTable(Node node) async {
    assert(node.type == SimpleTableBlockKeys.type);

    await addColumnInTable(node);
    await addRowInTable(node);
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
}
