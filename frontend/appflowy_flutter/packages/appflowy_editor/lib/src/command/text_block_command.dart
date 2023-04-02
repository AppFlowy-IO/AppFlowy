import 'package:appflowy_editor/appflowy_editor.dart';

extension TextBlockCommand on Transaction {
  void deleteTextWithSelection(
    Node node,
    Selection selection,
  ) {
    assert(selection.isSingle);
    if (selection.startIndex != 0) {
      assert(selection.isSingle);
      if (selection.isCollapsed) {
        deleteTextV2(
          node,
          selection.startIndex - 1,
          1,
        );
      } else {
        deleteTextV2(
          node,
          selection.startIndex,
          selection.length,
        );
      }
    }
  }

  void mergeTextIntoNode(Node node, Node mergedNode) {
    assert(node.delta != null && mergedNode.delta != null);
    mergeTextV2(mergedNode, node);
    if (node.children.isNotEmpty) {
      insertNodes(
        mergedNode.path.next,
        node.children.toList(growable: false),
      );
    }
    deleteNode(node);
    afterSelection = Selection.collapsed(
      Position(
        path: mergedNode.path,
        offset: mergedNode.delta!.length,
      ),
    );
  }

  void moveToParentsSibling(Node node) {
    if (node.parent != null && node.parent?.type != 'editor') {
      deleteNode(node);
      insertNode(node.parent!.path.next, node);
      afterSelection = Selection.collapsed(
        Position(path: node.parent!.path.next, offset: 0),
      );
    }
  }
}
