import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

const _equality = DeepCollectionEquality();

/// Diff two documents and return the operations can be applied to the old document
/// to make it the same as the new document.
List<Operation> diffDocument(Document oldDocument, Document newDocument) {
  return diffNode(oldDocument.root, newDocument.root);
}

/// Diff two nodes and return the operations can be applied to the old node
/// to make it the same as the new node.
List<Operation> diffNode(Node oldNode, Node newNode) {
  List<Operation> operations = [];

  if (!_equality.equals(oldNode.attributes, newNode.attributes)) {
    operations.add(
      UpdateOperation(oldNode.path, newNode.attributes, oldNode.attributes),
    );
  }

  final oldChildrenById = {
    for (final child in oldNode.children) child.id: child,
  };
  final newChildrenById = {
    for (final child in newNode.children) child.id: child,
  };

  // Identify insertions and updates
  for (final newChild in newNode.children) {
    final oldChild = oldChildrenById[newChild.id];
    if (oldChild == null) {
      // Insert operation
      operations.add(InsertOperation(newChild.path, [newChild]));
    } else {
      // Recursive diff for updates
      operations.addAll(diffNode(oldChild, newChild));
    }
  }

  // Identify deletions
  oldChildrenById.keys
      .where((id) => !newChildrenById.containsKey(id))
      .forEach((id) {
    final oldChild = oldChildrenById[id]!;
    operations.add(DeleteOperation(oldChild.path, [oldChild]));
  });

  // Combine the operation in operations

  debugPrint(
    'diff operations[before]: ${operations.map((op) => op.toJson()).toList()}',
  );

  operations.sort((a, b) => a.path <= b.path ? -1 : 1);

  // merge the insert operations
  final insertOperations = operations.whereType<InsertOperation>().toList();
  for (var i = insertOperations.length - 1; i > 0; i--) {
    final op = insertOperations[i];
    final previousOp = insertOperations[i - 1];

    if (op.path.equals(previousOp.path.next)) {
      // merge the two operations
      insertOperations.removeAt(i);
      insertOperations[i - 1] = InsertOperation(
        previousOp.path,
        [...previousOp.nodes, ...op.nodes],
      );
    }
  }

  debugPrint(
    'diff operations[insert]: ${insertOperations.map((op) => op.toJson()).toList()}',
  );

  operations.removeWhere((op) => op is InsertOperation);

  debugPrint(
    'diff operations[after]: ${operations.map((op) => op.toJson()).toList()}',
  );

  operations = [...insertOperations, ...operations];

  debugPrint(
    'diff operations[after]: ${operations.map((op) => op.toJson()).toList()}',
  );

  return operations;
}
