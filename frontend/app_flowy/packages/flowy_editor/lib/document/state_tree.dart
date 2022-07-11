import 'package:flowy_editor/document/node.dart';

class StateTree {
  Node root;

  StateTree({required this.root});

  factory StateTree.fromJson(Map<String, Object> json) {
    assert(json['document'] is Map);

    final document = Map<String, Object>.from(json['document'] as Map);
    final root = Node.fromJson(document);
    return StateTree(root: root);
  }

  // bool insert(Path path, Node node) {
  //   final insertedNode = root
  //   return false;
  // }
}
