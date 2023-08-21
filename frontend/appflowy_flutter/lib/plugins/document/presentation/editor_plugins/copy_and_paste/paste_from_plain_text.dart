import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/editor_state_paste_node_extension.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

RegExp _hrefRegex = RegExp(
  r'https?://(?:www\.)?[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,}(?:/[^\s]*)?',
);

extension PasteFromPlainText on EditorState {
  Future<void> pastePlainText(String plainText) async {
    final nodes = plainText
        .split('\n')
        .map(
          (e) => e
            ..replaceAll(r'\r', '')
            ..trimRight(),
        )
        .map((e) {
          // parse the url content
          final Attributes attributes = {};
          if (_hrefRegex.hasMatch(e)) {
            attributes[AppFlowyRichTextKeys.href] = e;
          }
          return Delta()..insert(e, attributes: attributes);
        })
        .map((e) => paragraphNode(delta: e))
        .toList();
    if (nodes.isEmpty) {
      return;
    }
    if (nodes.length == 1) {
      await pasteSingleLineNode(nodes.first);
    } else {
      await pasteMultiLineNodes(nodes.toList());
    }
  }
}
