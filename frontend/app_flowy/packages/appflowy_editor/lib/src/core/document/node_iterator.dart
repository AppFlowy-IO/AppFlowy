import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/document/state_tree.dart';

/// [NodeIterator] is used to traverse the nodes in visual order.
class NodeIterator implements Iterator<Node> {
  NodeIterator({
    required this.stateTree,
    required this.startNode,
    this.endNode,
  });

  final StateTree stateTree;
  final Node startNode;
  final Node? endNode;

  Node? _currentNode;
  bool _began = false;

  @override
  Node get current => _currentNode!;

  @override
  bool moveNext() {
    if (!_began) {
      _currentNode = startNode;
      _began = true;
      return true;
    }

    final node = _currentNode;
    if (node == null) {
      return false;
    }

    if (endNode != null && endNode == node) {
      _currentNode = null;
      return false;
    }

    if (node.children.isNotEmpty) {
      _currentNode = _findLeadingChild(node);
    } else if (node.next != null) {
      _currentNode = node.next!;
    } else {
      final parent = node.parent!;
      final nextOfParent = parent.next;
      if (nextOfParent == null) {
        _currentNode = null;
      } else {
        _currentNode = nextOfParent;
      }
    }

    return _currentNode != null;
  }

  List<Node> toList() {
    final result = <Node>[];
    while (moveNext()) {
      result.add(current);
    }
    return result;
  }

  Node _findLeadingChild(Node node) {
    while (node.children.isNotEmpty) {
      node = node.children.first;
    }
    return node;
  }
}
