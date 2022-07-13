import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/document/path.dart';

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

  bool insert(Path path, Node node) {
    if (path.isEmpty) {
      return false;
    }
    final insertedNode = root.childAtPath(
      path.sublist(0, path.length - 1) + [path.last - 1],
    );
    if (insertedNode == null) {
      return false;
    }
    insertedNode.insertAfter(node);
    return true;
  }

  Node? delete(Path path) {
    if (path.isEmpty) {
      return null;
    }
    final deletedNode = root.childAtPath(path);
    deletedNode?.unlink();
    return deletedNode;
  }

  Attributes? update(Path path, Attributes attributes) {
    if (path.isEmpty) {
      return null;
    }
    final updatedNode = root.childAtPath(path);
    if (updatedNode == null) {
      return null;
    }
    final previousAttributes = {...updatedNode.attributes};
    updatedNode.updateAttributes(attributes);
    return previousAttributes;
  }
}
