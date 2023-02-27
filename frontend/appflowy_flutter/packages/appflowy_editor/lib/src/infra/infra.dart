import 'package:appflowy_editor/src/core/document/node.dart';

class Infra {
// find the forward nearest text node
  static TextNode? forwardNearestTextNode(Node node) {
    var previous = node.previous;
    while (previous != null) {
      final lastTextNode = findLastTextNode(previous);
      if (lastTextNode != null) {
        return lastTextNode;
      }
      if (previous is TextNode) {
        return previous;
      }
      previous = previous.previous;
    }
    final parent = node.parent;
    if (parent != null) {
      if (parent is TextNode) {
        return parent;
      }
      return forwardNearestTextNode(parent);
    }
    return null;
  }

  // find the last text node
  static TextNode? findLastTextNode(Node node) {
    final children = node.children.toList(growable: false).reversed;
    for (final child in children) {
      if (child.children.isNotEmpty) {
        final result = findLastTextNode(child);
        if (result != null) {
          return result;
        }
      }
      if (child is TextNode) {
        return child;
      }
    }
    if (node is TextNode) {
      return node;
    }
    return null;
  }
}
