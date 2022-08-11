import 'package:flowy_editor/src/document/node.dart';
import 'package:flowy_editor/src/document/path.dart';
import 'package:flowy_editor/src/document/text_delta.dart';
import './attributes.dart';

class StateTree {
  final Node root;

  StateTree({
    required this.root,
  });

  factory StateTree.fromJson(Attributes json) {
    assert(json['document'] is Map);

    final document = Map<String, Object>.from(json['document'] as Map);
    final root = Node.fromJson(document);
    return StateTree(root: root);
  }

  Node? nodeAtPath(Path path) {
    return root.childAtPath(path);
  }

  bool insert(Path path, List<Node> nodes) {
    if (path.isEmpty) {
      return false;
    }
    Node? insertedNode = root.childAtPath(
      path.sublist(0, path.length - 1) + [path.last - 1],
    );
    if (insertedNode == null) {
      return false;
    }
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      insertedNode!.insertAfter(node);
      insertedNode = node;
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

  Attributes? update(Path path, Attributes attributes) {
    if (path.isEmpty) {
      return null;
    }
    final updatedNode = root.childAtPath(path);
    if (updatedNode == null) {
      return null;
    }
    final previousAttributes = Attributes.from(updatedNode.attributes);
    updatedNode.updateAttributes(attributes);
    return previousAttributes;
  }
}
