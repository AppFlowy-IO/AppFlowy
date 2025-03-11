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
            final columns = column.parent;

            if (columns != null &&
                columns.type == SimpleColumnsBlockKeys.type) {
              final nonEmptyColumnCount = columns.children.fold(
                0,
                (p, c) => c.children.isEmpty ? p : p + 1,
              );

              // Example:
              // columns
              //  - column 1
              //    - paragraph 1-1
              //    - paragraph 1-2
              //  - column 2
              //    - paragraph 2
              //  - column 3
              //    - paragraph 3
              //
              // case 1: delete the paragraph 3 from column 3.
              // because there is only one child in column 3, we should delete the column 3 as well.
              // the result should be:
              // columns
              //  - column 1
              //    - paragraph 1-1
              //    - paragraph 1-2
              //  - column 2
              //    - paragraph 2
              //
              // case 2: delete the paragraph 3 from column 3 and delete the paragraph 2 from column 2.
              // in this case, there will be only one column left, so we should delete the columns block and flatten the children.
              // the result should be:
              // paragraph 1-1
              // paragraph 1-2

              // if there is only one empty column left, delete the columns block and flatten the children
              if (nonEmptyColumnCount <= 1) {
                // move the children in columns out of the column
                final children = columns.children
                    .map((e) => e.children)
                    .expand((e) => e)
                    .map((e) => e.deepCopy())
                    .toList();
                deleteColumnsTransaction.insertNodes(columns.path, children);
                deleteColumnsTransaction.deleteNode(columns);
              } else {
                // otherwise, delete the column
                deleteColumnsTransaction.deleteNode(column);

                final deletedColumnRatio =
                    column.attributes[SimpleColumnBlockKeys.ratio];
                if (deletedColumnRatio != null) {
                  // update the ratio of the columns
                  final columnsNode = column.columnsParent;
                  if (columnsNode != null) {
                    final length = columnsNode.children.length;
                    for (final columnNode in columnsNode.children) {
                      final ratio =
                          columnNode.attributes[SimpleColumnBlockKeys.ratio] ??
                              1.0 / length;
                      if (ratio != null) {
                        deleteColumnsTransaction.updateNode(columnNode, {
                          ...columnNode.attributes,
                          SimpleColumnBlockKeys.ratio:
                              ratio + deletedColumnRatio / (length - 1),
                        });
                      }
                    }
                  }
                }
              }
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
