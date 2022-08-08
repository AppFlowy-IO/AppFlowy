import 'package:flowy_editor/document/node.dart';

import './state_tree.dart';
import './node.dart';

/// [NodeIterator] is used to traverse the nodes in visual order.
class NodeIterator implements Iterator<Node> {
  final StateTree stateTree;
  final Node _startNode;
  final Node? _endNode;
  Node? _currentNode;
  bool _began = false;

  NodeIterator(this.stateTree, Node startNode, [Node? endNode])
      : _startNode = startNode,
        _endNode = endNode;

  @override
  bool moveNext() {
    if (!_began) {
      _currentNode = _startNode;
      _began = true;
      return true;
    }

    final node = _currentNode;
    if (node == null) {
      return false;
    }

    if (_endNode != null && _endNode == node) {
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
        _currentNode = _findLeadingChild(nextOfParent);
      }
    }

    return _currentNode != null;
  }

  Node _findLeadingChild(Node node) {
    while (node.children.isNotEmpty) {
      node = node.children.first;
    }
    return node;
  }

  @override
  Node get current {
    return _currentNode!;
  }

  List<Node> toList() {
    final result = <Node>[];

    while (moveNext()) {
      result.add(current);
    }

    return result;
  }
}
