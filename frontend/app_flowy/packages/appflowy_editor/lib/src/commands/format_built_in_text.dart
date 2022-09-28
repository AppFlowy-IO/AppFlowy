import 'package:appflowy_editor/src/commands/format_text.dart';
import 'package:appflowy_editor/src/document/attributes.dart';
import 'package:appflowy_editor/src/document/built_in_attribute_keys.dart';
import 'package:appflowy_editor/src/document/node.dart';
import 'package:appflowy_editor/src/document/path.dart';
import 'package:appflowy_editor/src/editor_state.dart';

Future<void> formatBuiltInTextAttributes(
  EditorState editorState,
  String key,
  Attributes attributes, {
  Path? path,
  TextNode? textNode,
}) async {
  if (BuiltInAttributeKey.globalStyleKeys.contains(key)) {
    assert(!(path != null && textNode != null));
    assert(!(path == null && textNode == null));

    TextNode formattedTextNode;
    if (textNode != null) {
      formattedTextNode = textNode;
    } else if (path != null) {
      formattedTextNode = editorState.document.nodeAtPath(path) as TextNode;
    } else {
      throw Exception('path and textNode cannot be null at the same time');
    }
    // remove all the existing style
    final newAttributes = formattedTextNode.attributes
      ..removeWhere((key, value) {
        if (BuiltInAttributeKey.globalStyleKeys.contains(key)) {
          return true;
        }
        return false;
      })
      ..addAll(attributes)
      ..addAll({
        BuiltInAttributeKey.subtype: key,
      });
    return updateTextNodeAttributes(
      editorState,
      newAttributes,
      textNode: textNode,
    );
  }
}

Future<void> formatTextToCheckbox(
  EditorState editorState,
  bool check, {
  Path? path,
  TextNode? textNode,
}) async {
  return formatBuiltInTextAttributes(
    editorState,
    BuiltInAttributeKey.checkbox,
    {
      BuiltInAttributeKey.checkbox: check,
    },
    path: path,
    textNode: textNode,
  );
}
