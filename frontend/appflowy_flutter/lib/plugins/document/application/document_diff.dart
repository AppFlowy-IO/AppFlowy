import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

/// DocumentDiff compares two document states and generates operations needed
/// to transform one state into another.
class DocumentDiff {
  const DocumentDiff({
    this.enableDebugLog = false,
  });

  final bool enableDebugLog;

  // Using DeepCollectionEquality for deep comparison of collections
  static const _equality = DeepCollectionEquality();

  /// Generates operations needed to transform oldDocument into newDocument.
  /// Returns a list of operations (Insert, Delete, Update) that can be applied sequentially.
  List<Operation> diffDocument(Document oldDocument, Document newDocument) {
    return diffNode(oldDocument.root, newDocument.root);
  }

  /// Compares two nodes and their children recursively to generate transformation operations.
  /// Returns a list of operations that will transform oldNode into newNode.
  List<Operation> diffNode(Node oldNode, Node newNode) {
    final operations = <Operation>[];

    // Compare and update node attributes if they're different.
    //  Using DeepCollectionEquality instead of == for deep comparison of collections
    if (!_equality.equals(oldNode.attributes, newNode.attributes)) {
      operations.add(
        UpdateOperation(oldNode.path, newNode.attributes, oldNode.attributes),
      );
    }

    final oldChildrenById = Map<String, Node>.fromEntries(
      oldNode.children.map((child) => MapEntry(child.id, child)),
    );
    final newChildrenById = Map<String, Node>.fromEntries(
      newNode.children.map((child) => MapEntry(child.id, child)),
    );

    // Insertion or Update
    for (final newChild in newNode.children) {
      final oldChild = oldChildrenById[newChild.id];
      if (oldChild == null) {
        // If the node doesn't exist in the old document, it's a new node.
        operations.add(InsertOperation(newChild.path, [newChild]));
      } else {
        // If the node exists in the old document, recursively compare its children
        operations.addAll(diffNode(oldChild, newChild));
      }
    }

    // Deletion
    for (final id in oldChildrenById.keys) {
      // If the node doesn't exist in the new document, it's a deletion.
      if (!newChildrenById.containsKey(id)) {
        final oldChild = oldChildrenById[id]!;
        operations.add(DeleteOperation(oldChild.path, [oldChild]));
      }
    }

    // Optimize operations by merging consecutive inserts and deletes
    return _optimizeOperations(operations);
  }

  /// Optimizes the list of operations by merging consecutive operations where possible.
  /// This reduces the total number of operations that need to be applied.
  List<Operation> _optimizeOperations(List<Operation> operations) {
    // Optimize the insert operations first, then the delete operations
    final optimizedOps = mergeDeleteOperations(
      mergeInsertOperations(
        operations,
      ),
    );
    return optimizedOps;
  }

  /// Merges consecutive insert operations to reduce the number of operations.
  /// Operations are merged if they target consecutive paths in the document.
  List<Operation> mergeInsertOperations(List<Operation> operations) {
    if (enableDebugLog) {
      _logOperations('mergeInsertOperations[before]', operations);
    }

    final copy = [...operations];
    final insertOperations = operations
        .whereType<InsertOperation>()
        .sorted(_descendingCompareTo)
        .toList();

    _mergeConsecutiveOperations<InsertOperation>(
      insertOperations,
      (prev, current) => InsertOperation(
        prev.path,
        [...prev.nodes, ...current.nodes],
      ),
    );

    if (insertOperations.isNotEmpty) {
      copy
        ..removeWhere((op) => op is InsertOperation)
        ..insertAll(0, insertOperations); // Insert ops must be at the start
    }

    if (enableDebugLog) {
      _logOperations('mergeInsertOperations[after]', copy);
    }

    return copy;
  }

  /// Merges consecutive delete operations to reduce the number of operations.
  /// Operations are merged if they target consecutive paths in the document.
  List<Operation> mergeDeleteOperations(List<Operation> operations) {
    if (enableDebugLog) {
      _logOperations('mergeDeleteOperations[before]', operations);
    }

    final copy = [...operations];
    final deleteOperations = operations
        .whereType<DeleteOperation>()
        .sorted(_descendingCompareTo)
        .toList();

    _mergeConsecutiveOperations<DeleteOperation>(
      deleteOperations,
      (prev, current) => DeleteOperation(
        prev.path,
        [...prev.nodes, ...current.nodes],
      ),
    );

    if (deleteOperations.isNotEmpty) {
      copy
        ..removeWhere((op) => op is DeleteOperation)
        ..addAll(deleteOperations); // Delete ops must be at the end
    }

    if (enableDebugLog) {
      _logOperations('mergeDeleteOperations[after]', copy);
    }

    return copy;
  }

  /// Merge consecutive operations of the same type
  void _mergeConsecutiveOperations<T extends Operation>(
    List<T> operations,
    T Function(T prev, T current) merge,
  ) {
    for (var i = operations.length - 1; i > 0; i--) {
      final op = operations[i];
      final previousOp = operations[i - 1];

      if (op.path.equals(previousOp.path.next)) {
        operations
          ..removeAt(i)
          ..[i - 1] = merge(previousOp, op);
      }
    }
  }

  void _logOperations(String prefix, List<Operation> operations) {
    debugPrint('$prefix: ${operations.map((op) => op.toJson()).toList()}');
  }

  int _descendingCompareTo(Operation a, Operation b) {
    return a.path > b.path ? 1 : -1;
  }
}
