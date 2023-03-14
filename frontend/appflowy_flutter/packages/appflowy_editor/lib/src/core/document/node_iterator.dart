import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/core/document/document.dart';

/// [NodeIterator] is used to traverse the nodes in visual order.
class NodeIterator implements Iterator<Node> {
  NodeIterator({
    required this.document,
    required this.startNode,
    this.endNode,
  });

  final Document document;
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

    if (_currentNode == null) {
      return false;
    }
    Node node = _currentNode!;

    if (endNode != null && endNode == node) {
      _currentNode = null;
      return false;
    }

    if (node.children.isNotEmpty) {
      _currentNode = node.children.first;
    } else if (node.next != null) {
      _currentNode = node.next!;
    } else {
      while (node.parent != null) {
        node = node.parent!;
        final nextOfParent = node.next;
        if (nextOfParent == null) {
          _currentNode = null;
        } else {
          _currentNode = nextOfParent;
          break;
        }
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
}
