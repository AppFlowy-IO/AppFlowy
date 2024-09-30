import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';

Future<void> convertUrlPreviewNodeToLink(
  EditorState editorState,
  Node node,
) async {
  if (node.type != LinkPreviewBlockKeys.type) {
    return;
  }

  final url = node.attributes[ImageBlockKeys.url];
  final delta = Delta()
    ..insert(
      url,
      attributes: {
        AppFlowyRichTextKeys.href: url,
      },
    );
  final transaction = editorState.transaction;
  transaction
    ..insertNode(node.path, paragraphNode(delta: delta))
    ..deleteNode(node);
  transaction.afterSelection = Selection.collapsed(
    Position(
      path: node.path,
      offset: url.length,
    ),
  );
  return editorState.apply(transaction);
}
