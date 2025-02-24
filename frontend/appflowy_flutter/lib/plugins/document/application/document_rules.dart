import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

/// Apply rules to the document
///
/// 1. ensure there is at least one paragraph in the document, otherwise the user will be blocked from typing
/// 2. remove columns block if its children are empty
class DocumentRules {
  DocumentRules({
    required this.editorState,
  });

  final EditorState editorState;

  Future<void> applyRules({
    required EditorTransactionValue value,
  }) async {
    await Future.wait([
      _ensureAtLeastOneParagraphExists(value: value),
      _removeColumnIfItIsEmpty(value: value),
    ]);
  }

  Future<void> _ensureAtLeastOneParagraphExists({
    required EditorTransactionValue value,
  }) async {
    final document = editorState.document;
    if (document.root.children.isEmpty) {
      final transaction = editorState.transaction;
      transaction
        ..insertNode([0], paragraphNode())
        ..afterSelection = Selection.collapsed(
          Position(path: [0]),
        );
      await editorState.apply(transaction);
    }
  }

  Future<void> _removeColumnIfItIsEmpty({
    required EditorTransactionValue value,
  }) async {
    final transaction = value.$2;
    final options = value.$3;

    if (options.inMemoryUpdate) {
      return;
    }

    for (final operation in transaction.operations) {
      final deleteColumnsTransaction = editorState.transaction;
      if (operation is DeleteOperation) {
        final path = operation.path;
        final column = editorState.document.nodeAtPath(path.parent);
        if (column != null && column.type == SimpleColumnBlockKeys.type) {
          // check if the column is empty
          final children = column.children;
          if (children.isEmpty) {
            // delete the column or the columns
            // check if the columns is empty
            final columns = column.parent;
            if (columns != null &&
                columns.type == SimpleColumnsBlockKeys.type) {
              // move the children in columns out of the column
              final children = columns.children
                  .map((e) => e.children)
                  .expand((e) => e)
                  .map((e) => e.deepCopy())
                  .toList();
              deleteColumnsTransaction.insertNodes(columns.path, children);
              deleteColumnsTransaction.deleteNode(columns);
            }
          }
        }
      }
      if (deleteColumnsTransaction.operations.isNotEmpty) {
        await editorState.apply(deleteColumnsTransaction);
      }
    }
  }
}
