import 'package:appflowy_editor/src/commands/format_text.dart';
import 'package:appflowy_editor/src/document/attributes.dart';
import 'package:appflowy_editor/src/document/built_in_attribute_keys.dart';
import 'package:appflowy_editor/src/document/node.dart';
import 'package:appflowy_editor/src/document/path.dart';
import 'package:appflowy_editor/src/document/selection.dart';
import 'package:appflowy_editor/src/editor_state.dart';

Future<void> formatBuiltInTextAttributes(
  EditorState editorState,
  String key,
  Attributes attributes, {
  Selection? selection,
  Path? path,
  TextNode? textNode,
}) async {
  final result = getTextNodeToBeFormatted(
    editorState,
    path: path,
    textNode: textNode,
  );
  if (BuiltInAttributeKey.globalStyleKeys.contains(key)) {
    // remove all the existing style
    final newAttributes = result.attributes
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
  } else if (BuiltInAttributeKey.partialStyleKeys.contains(key)) {
    return updateTextNodeDeltaAttributes(
      editorState,
      selection,
      attributes,
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

Future<void> formatLinkInText(
  EditorState editorState,
  String? link, {
  Path? path,
  TextNode? textNode,
}) async {
  return formatBuiltInTextAttributes(
    editorState,
    BuiltInAttributeKey.href,
    {
      BuiltInAttributeKey.href: link,
    },
    path: path,
    textNode: textNode,
  );
}
