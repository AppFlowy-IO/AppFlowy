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

    assert(node.type == SimpleTableBlockKeys.type);

    if (node.type != SimpleTableBlockKeys.type) {
      return;
    }

    final columnLength = node.columnLength;
    final rowLength = node.rowLength;

    if (fromIndex < 0 ||
        fromIndex >= rowLength ||
        toIndex < 0 ||
        toIndex >= rowLength) {
      Log.warn(
        'reorder column: index out of range: fromIndex: $fromIndex, toIndex: $toIndex, column length: $rowLength',
      );
      return;
    }

    Log.info(
      'reorder column in table ${node.id} at fromIndex: $fromIndex, toIndex: $toIndex, column length: $columnLength, row length: $rowLength',
    );

    final attributes = node.mapTableAttributes(
      node,
      type: TableMapOperationType.reorderColumn,
      index: fromIndex,
      toIndex: toIndex,
    );

    final transaction = this.transaction;
    for (var i = 0; i < columnLength; i++) {
      final row = node.children[i];
      final from = row.children[fromIndex];
      final to = row.children[toIndex];
      Path toPath = to.path;
      if (fromIndex < toIndex) {
        toPath = toPath.next;
      } else {
        toPath = toPath.previous;
      }
      transaction.insertNode(toPath, from.copyWith());
      transaction.deleteNode(from);
    }
    if (attributes != null) {
      transaction.updateNode(node, attributes);
    }
    await apply(transaction);
  }
}
