import 'dart:collection';

import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/core/document/path.dart';
import 'package:appflowy_editor/src/core/document/text_delta.dart';
import '../document/attributes.dart';

/// [Document] reprensents a AppFlowy Editor document structure.
///
/// It stores the root of the document.
///
/// DO NOT directly mutate the properties of a [Document] object.
class Document {
  Document({
    required this.root,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    assert(json['document'] is Map);

    final document = Map<String, Object>.from(json['document'] as Map);
    final root = Node.fromJson(document);
    return Document(root: root);
  }

  /// Creates a empty document with a single text node.
  factory Document.empty() {
    final root = Node(
      type: 'editor',
      children: LinkedList<Node>()..add(TextNode.empty()),
    );
    return Document(
      root: root,
    );
  }

  final Node root;

  /// Returns the node at the given [path].
  Node? nodeAtPath(Path path) {
    return root.childAtPath(path);
  }

  /// Inserts a [Node]s at the given [Path].
  bool insert(Path path, List<Node> nodes) {
    if (path.isEmpty || nodes.isEmpty) {
      return false;
    }

    final target = nodeAtPath(path);
    if (target != null) {
      for (final node in nodes) {
        target.insertBefore(node);
      }
      return true;
    }

    final parent = nodeAtPath(path.parent);
    if (parent != null) {
      for (final node in nodes) {
        parent.insert(node, index: path.last);
      }
      return true;
    }

    return false;
  }

  /// Deletes the [Node]s at the given [Path].
  bool delete(Path path, [int length = 1]) {
    if (path.isEmpty || length <= 0) {
      return false;
    }
    var target = nodeAtPath(path);
    if (target == null) {
      return false;
    }
    while (target != null && length > 0) {
      final next = target.next;
      target.unlink();
      target = next;
      length--;
    }
    return true;
  }

  /// Updates the [Node] at the given [Path]
  bool update(Path path, Attributes attributes) {
    if (path.isEmpty) {
      return false;
    }
    final target = nodeAtPath(path);
    if (target == null) {
      return false;
    }
    target.updateAttributes(attributes);
    return true;
  }

  /// Updates the [TextNode] at the given [Path]
  bool updateText(Path path, Delta delta) {
    if (path.isEmpty) {
      return false;
    }
    final target = nodeAtPath(path);
    if (target == null || target is! TextNode) {
      return false;
    }
    target.delta = target.delta.compose(delta);
    return true;
  }

  Map<String, Object> toJson() {
    return {
      'document': root.toJson(),
    };
  }
}
