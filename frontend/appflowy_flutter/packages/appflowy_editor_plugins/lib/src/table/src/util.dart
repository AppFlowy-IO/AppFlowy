import 'package:appflowy_editor/appflowy_editor.dart';

Node? getCellNode(Node tableNode, int col, int row) {
  return tableNode.children.firstWhereOrNull((n) =>
      n.attributes['position']['col'] == col &&
      n.attributes['position']['row'] == row);
}
