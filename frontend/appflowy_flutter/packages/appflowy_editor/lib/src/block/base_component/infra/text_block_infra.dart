import 'package:appflowy_editor/appflowy_editor.dart';

class TextBlockInfra {
  static Node? previousNodeContainsDelta(Node node) {
    var previous = node.previous;
    while (previous != null) {
      final lastTextNode = lastNodeContainsDelta(previous);
      if (lastTextNode != null) {
        return lastTextNode;
      }
      if (previous.delta != null) {
        return previous;
      }
      previous = previous.previous;
    }
    final parent = node.parent;
    if (parent != null) {
      if (parent.delta != null) {
        return parent;
      }
      return previousNodeContainsDelta(parent);
    }
    return null;
  }

  static Node? lastNodeContainsDelta(Node node) {
    final children = node.children.toList(growable: false).reversed;
    for (final child in children) {
      if (child.children.isNotEmpty) {
        final result = lastNodeContainsDelta(child);
        if (result != null) {
          return result;
        }
      }
      if (child.delta != null) {
        return child;
      }
    }
    if (node.delta != null) {
      return node;
    }
    return null;
  }
}
