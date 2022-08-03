import 'package:flowy_editor/document/node.dart';

import './state_tree.dart';
import './node.dart';

/// [NodeTraverser] is used to traverse the nodes in visual order.
class NodeTraverser {
  final StateTree stateTree;
  Node? currentNode;

  NodeTraverser(this.stateTree, Node beginNode) : currentNode = beginNode;

  Node? next() {
    final node = currentNode;
    if (node == null) {
      return null;
    }

    if (node.children.isNotEmpty) {
      currentNode = _findLeadingChild(node);
    } else if (node.next != null) {
      currentNode = node.next!;
    } else {
      final parent = node.parent!;
      final nextOfParent = parent.next;
      if (nextOfParent == null) {
        currentNode = null;
      } else {
        currentNode = _findLeadingChild(node);
      }
    }

    return node;
  }

  Node _findLeadingChild(Node node) {
    while (node.children.isNotEmpty) {
      node = node.children.first;
    }
    return node;
  }
}
