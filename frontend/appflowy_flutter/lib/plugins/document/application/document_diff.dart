import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

class EditorDiff {
  EditorDiff({
    this.enableDebugLog = false,
  });

  final bool enableDebugLog;

  static const _equality = DeepCollectionEquality();

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
    operations = mergeInsertOperations(operations);
    operations = mergeDeleteOperations(operations);

    return operations;
  }

  /// Merge the insert operations if their paths are consecutive.
  ///
  /// For example, if the operations are:
  /// [InsertOperation(path: [0], nodes: [node1]), InsertOperation(path: [1], nodes: [node2])]
  /// The result will be:
  /// [InsertOperation(path: [0], nodes: [node1, node2])]
  List<Operation> mergeInsertOperations(List<Operation> operations) {
    if (enableDebugLog) {
      debugPrint(
        'mergeInsertOperations[before]: ${operations.map((op) => op.toJson()).toList()}',
      );
    }

    List<Operation> copy = [...operations];

    // merge the insert operations
    final insertOperations = operations
        .whereType<InsertOperation>()
        .sorted((a, b) => a.path <= b.path ? -1 : 1)
        .toList();
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

    if (insertOperations.isNotEmpty) {
      copy.removeWhere((op) => op is InsertOperation);
      // Note: the insert operations must be at the front of the list
      copy = [
        ...insertOperations,
        ...copy,
      ];
    }

    if (enableDebugLog) {
      debugPrint(
        'mergeInsertOperations[after]: ${copy.map((op) => op.toJson()).toList()}',
      );
    }

    return copy;
  }

  List<Operation> mergeDeleteOperations(List<Operation> operations) {
    if (enableDebugLog) {
      debugPrint(
        'mergeDeleteOperations[before]: ${operations.map((op) => op.toJson()).toList()}',
      );
    }

    List<Operation> copy = [...operations];

    // merge the insert operations
    final deleteOperations = operations
        .whereType<DeleteOperation>()
        .sorted((a, b) => a.path <= b.path ? -1 : 1)
        .toList();
    for (var i = deleteOperations.length - 1; i > 0; i--) {
      final op = deleteOperations[i];
      final previousOp = deleteOperations[i - 1];

      if (op.path.equals(previousOp.path.next)) {
        // merge the two operations
        deleteOperations.removeAt(i);
        deleteOperations[i - 1] = DeleteOperation(
          previousOp.path,
          [...previousOp.nodes, ...op.nodes],
        );
      }
    }

    if (deleteOperations.isNotEmpty) {
      copy.removeWhere((op) => op is DeleteOperation);
      // Note: the delete operations must be at the end of the list
      copy = [
        ...copy,
        ...deleteOperations,
      ];
    }

    if (enableDebugLog) {
      debugPrint(
        'mergeDeleteOperations[after]: ${copy.map((op) => op.toJson()).toList()}',
      );
    }

    return copy;
  }
}
