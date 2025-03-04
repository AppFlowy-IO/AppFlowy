import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

extension SimpleColumnNodeExtension on Node {
  /// Returns the parent [Node] of the current node if it is a [SimpleColumnsBlock].
  Node? get parentColumnsBlock {
    Node? currentNode = parent;
    while (currentNode != null) {
      if (currentNode.type == SimpleColumnsBlockKeys.type) {
        return currentNode;
      }
      currentNode = currentNode.parent;
    }
    return null;
  }

  /// Returns the parent [Node] of the current node if it is a [SimpleColumnBlock].
  Node? get parentColumn {
    Node? currentNode = parent;
    while (currentNode != null) {
      if (currentNode.type == SimpleColumnBlockKeys.type) {
        return currentNode;
      }
      currentNode = currentNode.parent;
    }
    return null;
  }

  /// Returns whether the current node is in a [SimpleColumnsBlock].
  bool get isInColumnsBlock => parentColumnsBlock != null;

  /// Returns whether the current node is in a [SimpleColumnBlock].
  bool get isInColumnBlock => parentColumn != null;
}
