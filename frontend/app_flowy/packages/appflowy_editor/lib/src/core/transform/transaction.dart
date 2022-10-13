import 'dart:math';

import 'package:appflowy_editor/src/core/document/attributes.dart';
import 'package:appflowy_editor/src/core/document/document.dart';
import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/core/document/path.dart';
import 'package:appflowy_editor/src/core/document/text_delta.dart';
import 'package:appflowy_editor/src/core/location/position.dart';
import 'package:appflowy_editor/src/core/location/selection.dart';
import 'package:appflowy_editor/src/core/transform/operation.dart';

/// A [Transaction] has a list of [Operation] objects that will be applied
/// to the editor.
///
/// There will be several ways to consume the transaction:
/// 1. Apply to the state to update the UI.
/// 2. Send to the backend to store and do operation transforming.
class Transaction {
  Transaction({
    required this.document,
  });

  final Document document;

  /// The operations to be applied.
  final List<Operation> operations = [];

  /// The selection to be applied.
  Selection? afterSelection;

  /// The before selection is to be recovered if needed.
  Selection? beforeSelection;

  /// Inserts the [Node] at the given [Path].
  void insertNode(
    Path path,
    Node node, {
    bool deepCopy = true,
  }) {
    insertNodes(path, [node], deepCopy: deepCopy);
  }

  /// Inserts a sequence of [Node]s at the given [Path].
  void insertNodes(
    Path path,
    Iterable<Node> nodes, {
    bool deepCopy = true,
  }) {
    if (deepCopy) {
      add(InsertOperation(path, nodes.map((e) => e.copyWith())));
    } else {
      add(InsertOperation(path, nodes));
    }
  }

  /// Updates the attributes of the [Node].
  ///
  /// The [attributes] will be merged into the existing attributes.
  void updateNode(Node node, Attributes attributes) {
    final inverted = invertAttributes(node.attributes, attributes);
    add(UpdateOperation(
      node.path,
      {...attributes},
      inverted,
    ));
  }

  /// Deletes the [Node] in the document.
  void deleteNode(Node node) {
    deleteNodesAtPath(node.path);
  }

  /// Deletes the [Node]s in the document.
  void deleteNodes(Iterable<Node> nodes) {
    nodes.forEach(deleteNode);
  }

  /// Deletes the [Node]s at the given [Path].
  ///
  /// The [length] indicates the number of consecutive deletions,
  ///   including the node of the current path.
  void deleteNodesAtPath(Path path, [int length = 1]) {
    if (path.isEmpty) return;
    final nodes = <Node>[];
    final parent = path.parent;
    for (var i = 0; i < length; i++) {
      final node = document.nodeAtPath(parent + [path.last + i]);
      if (node == null) {
        break;
      }
      nodes.add(node);
    }
    add(DeleteOperation(path, nodes));
  }

  /// Update the [TextNode]s with the given [Delta].
  void updateText(TextNode textNode, Delta delta) {
    final inverted = delta.invert(textNode.delta);
    add(UpdateTextOperation(textNode.path, delta, inverted));
  }

  /// Returns the JSON representation of the transaction.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (operations.isNotEmpty) {
      json['operations'] = operations.map((o) => o.toJson());
    }
    if (afterSelection != null) {
      json['after_selection'] = afterSelection!.toJson();
    }
    if (beforeSelection != null) {
      json['before_selection'] = beforeSelection!.toJson();
    }
    return json;
  }

  /// Adds an operation to the transaction.
  /// This method will merge operations if they are both TextEdits.
  ///
  /// Also, this method will transform the path of the operations
  /// to avoid conflicts.
  void add(Operation op, {bool transform = true}) {
    final Operation? last = operations.isEmpty ? null : operations.last;
    if (last != null) {
      if (op is UpdateTextOperation &&
          last is UpdateTextOperation &&
          op.path.equals(last.path)) {
        final newOp = UpdateTextOperation(
          op.path,
          last.delta.compose(op.delta),
          op.inverted.compose(last.inverted),
        );
        operations[operations.length - 1] = newOp;
        return;
      }
    }
    if (transform) {
      for (var i = 0; i < operations.length; i++) {
        op = transformOperation(operations[i], op);
      }
    }
    if (op is UpdateTextOperation && op.delta.isEmpty) {
      return;
    }
    operations.add(op);
  }
}

extension TextTransaction on Transaction {
  void mergeText(
    TextNode first,
    TextNode second, {
    int? firstOffset,
    int secondOffset = 0,
  }) {
    final firstLength = first.delta.length;
    final secondLength = second.delta.length;
    firstOffset ??= firstLength;
    updateText(
      first,
      Delta()
        ..retain(firstOffset)
        ..delete(firstLength - firstOffset)
        ..addAll(second.delta.slice(secondOffset, secondLength)),
    );
    afterSelection = Selection.collapsed(Position(
      path: first.path,
      offset: firstOffset,
    ));
  }

  /// Inserts the text content at a specified index.
  ///
  /// Optionally, you may specify formatting attributes that are applied to the inserted string.
  /// By default, the formatting attributes before the insert position will be reused.
  void insertText(
    TextNode textNode,
    int index,
    String text, {
    Attributes? attributes,
  }) {
    var newAttributes = attributes;
    if (index != 0 && attributes == null) {
      newAttributes =
          textNode.delta.slice(max(index - 1, 0), index).first.attributes;
      if (newAttributes != null) {
        newAttributes = {...newAttributes}; // make a copy
      }
    }
    updateText(
      textNode,
      Delta()
        ..retain(index)
        ..insert(text, attributes: newAttributes),
    );
    afterSelection = Selection.collapsed(
      Position(path: textNode.path, offset: index + text.length),
    );
  }

  /// Assigns a formatting attributes to a range of text.
  void formatText(
    TextNode textNode,
    int index,
    int length,
    Attributes attributes,
  ) {
    afterSelection = beforeSelection;
    updateText(
      textNode,
      Delta()
        ..retain(index)
        ..retain(length, attributes: attributes),
    );
  }

  /// Deletes the text of specified length starting at index.
  void deleteText(
    TextNode textNode,
    int index,
    int length,
  ) {
    updateText(
      textNode,
      Delta()
        ..retain(index)
        ..delete(length),
    );
    afterSelection = Selection.collapsed(
      Position(path: textNode.path, offset: index),
    );
  }

  /// Replaces the text of specified length starting at index.
  ///
  /// Optionally, you may specify formatting attributes that are applied to the inserted string.
  /// By default, the formatting attributes before the insert position will be reused.
  void replaceText(
    TextNode textNode,
    int index,
    int length,
    String text, {
    Attributes? attributes,
  }) {
    var newAttributes = attributes;
    if (index != 0 && attributes == null) {
      newAttributes =
          textNode.delta.slice(max(index - 1, 0), index).first.attributes;
      if (newAttributes != null) {
        newAttributes = {...newAttributes}; // make a copy
      }
    }
    updateText(
      textNode,
      Delta()
        ..retain(index)
        ..delete(length)
        ..insert(text, attributes: newAttributes),
    );
    afterSelection = Selection.collapsed(
      Position(
        path: textNode.path,
        offset: index + text.length,
      ),
    );
  }
}
