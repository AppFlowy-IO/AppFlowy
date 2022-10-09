import 'dart:math';

import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/core/document/path.dart';
import 'package:appflowy_editor/src/document/text_delta.dart';
import '../core/document/attributes.dart';

class StateTree {
  final Node root;

  StateTree({
    required this.root,
  });

  factory StateTree.empty() {
    return StateTree(
      root: Node.fromJson({
        'type': 'editor',
        'children': [
          {
            'type': 'text',
          }
        ]
      }),
    );
  }

  factory StateTree.fromJson(Attributes json) {
    assert(json['document'] is Map);

    final document = Map<String, Object>.from(json['document'] as Map);
    final root = Node.fromJson(document);
    return StateTree(root: root);
  }

  Map<String, Object> toJson() {
    return {
      'document': root.toJson(),
    };
  }

  Node? nodeAtPath(Path path) {
    return root.childAtPath(path);
  }

  bool insert(Path path, List<Node> nodes) {
    if (path.isEmpty) {
      return false;
    }
    Node? insertedNode = root.childAtPath(
      path.sublist(0, path.length - 1) + [max(0, path.last - 1)],
    );
    if (insertedNode == null) {
      final insertedNode = root.childAtPath(
        path.sublist(0, path.length - 1),
      );
      if (insertedNode != null) {
        for (final node in nodes) {
          insertedNode.insert(node);
        }
        return true;
      }
      return false;
    }
    if (path.last <= 0) {
      for (var i = 0; i < nodes.length; i++) {
        final node = nodes[i];
        insertedNode.insertBefore(node);
      }
    } else {
      for (var i = 0; i < nodes.length; i++) {
        final node = nodes[i];
        insertedNode!.insertAfter(node);
        insertedNode = node;
      }
    }
    return true;
  }

  bool textEdit(Path path, Delta delta) {
    if (path.isEmpty) {
      return false;
    }
    final node = root.childAtPath(path);
    if (node == null || node is! TextNode) {
      return false;
    }
    node.delta = node.delta.compose(delta);
    return false;
  }

  delete(Path path, [int length = 1]) {
    if (path.isEmpty) {
      return null;
    }
    var deletedNode = root.childAtPath(path);
    while (deletedNode != null && length > 0) {
      final next = deletedNode.next;
      deletedNode.unlink();
      length--;
      deletedNode = next;
    }
  }

  bool update(Path path, Attributes attributes) {
    if (path.isEmpty) {
      return false;
    }
    final updatedNode = root.childAtPath(path);
    if (updatedNode == null) {
      return false;
    }
    updatedNode.updateAttributes(attributes);
    return true;
  }
}
