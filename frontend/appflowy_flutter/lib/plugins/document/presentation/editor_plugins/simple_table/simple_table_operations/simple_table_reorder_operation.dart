import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

extension SimpleTableReorderOperation on EditorState {
  /// Reorder the column of the table.
  ///
  /// If the from index is equal to the to index, do nothing.
  /// The node's type can be [SimpleTableCellBlockKeys.type] or [SimpleTableRowBlockKeys.type] or [SimpleTableBlockKeys.type].
  Future<void> reorderColumn(
    Node node, {
    required int fromIndex,
    required int toIndex,
  }) async {
    if (fromIndex == toIndex) {
      return;
    }

    final tableNode = node.parentTableNode;

    if (tableNode == null) {
      assert(tableNode == null);
      return;
    }

    final columnLength = tableNode.columnLength;
    final rowLength = tableNode.rowLength;

    if (fromIndex < 0 ||
        fromIndex >= columnLength ||
        toIndex < 0 ||
        toIndex >= columnLength) {
      Log.warn(
        'reorder column: index out of range: fromIndex: $fromIndex, toIndex: $toIndex, column length: $columnLength',
      );
      return;
    }

    Log.info(
      'reorder column in table ${node.id} at fromIndex: $fromIndex, toIndex: $toIndex, column length: $columnLength, row length: $rowLength',
    );

    final attributes = tableNode.mapTableAttributes(
      tableNode,
      type: TableMapOperationType.reorderColumn,
      index: fromIndex,
      toIndex: toIndex,
    );

    final transaction = this.transaction;
    for (var i = 0; i < rowLength; i++) {
      final row = tableNode.children[i];
      final from = row.children[fromIndex];
      final to = row.children[toIndex];
      final path = fromIndex < toIndex ? to.path.next : to.path;
      transaction.insertNode(path, from.deepCopy());
      transaction.deleteNode(from);
    }
    if (attributes != null) {
      transaction.updateNode(tableNode, attributes);
    }
    await apply(transaction);
  }

  /// Reorder the row of the table.
  ///
  /// If the from index is equal to the to index, do nothing.
  /// The node's type can be [SimpleTableCellBlockKeys.type] or [SimpleTableRowBlockKeys.type] or [SimpleTableBlockKeys.type].
  Future<void> reorderRow(
    Node node, {
    required int fromIndex,
    required int toIndex,
  }) async {
    if (fromIndex == toIndex) {
      return;
    }

    final tableNode = node.parentTableNode;

    if (tableNode == null) {
      assert(tableNode == null);
      return;
    }

    final columnLength = tableNode.columnLength;
    final rowLength = tableNode.rowLength;

    if (fromIndex < 0 ||
        fromIndex >= rowLength ||
        toIndex < 0 ||
        toIndex >= rowLength) {
      Log.warn(
        'reorder row: index out of range: fromIndex: $fromIndex, toIndex: $toIndex, row length: $rowLength',
      );
      return;
    }

    Log.info(
      'reorder row in table ${node.id} at fromIndex: $fromIndex, toIndex: $toIndex, column length: $columnLength, row length: $rowLength',
    );

    final attributes = tableNode.mapTableAttributes(
      tableNode,
      type: TableMapOperationType.reorderRow,
      index: fromIndex,
      toIndex: toIndex,
    );

    final transaction = this.transaction;
    final from = tableNode.children[fromIndex];
    final to = tableNode.children[toIndex];
    final path = fromIndex < toIndex ? to.path.next : to.path;
    transaction.insertNode(path, from.deepCopy());
    transaction.deleteNode(from);
    if (attributes != null) {
      transaction.updateNode(tableNode, attributes);
    }
    await apply(transaction);
  }
}
