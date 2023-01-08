import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/commands/command_extension.dart';

extension TextCommands on EditorState {
  /// Insert text at the given index of the given [TextNode] or the [Path].
  ///
  /// [Path] and [TextNode] are mutually exclusive.
  /// One of these two parameters must have a value.
  Future<void> insertText(
    int index,
    String text, {
    Path? path,
    TextNode? textNode,
  }) async {
    final n = getTextNode(path: path, textNode: textNode);
    return apply(
      transaction..insertText(n, index, text),
    );
  }

  Future<void> insertTextAtCurrentSelection(String text) async {
    final selection = getSelection(null);
    assert(selection.isCollapsed);
    final textNode = getTextNode(path: selection.start.path);
    return insertText(
      selection.startIndex,
      text,
      textNode: textNode,
    );
  }

  Future<void> formatText(
    EditorState editorState,
    Selection? selection,
    Attributes attributes, {
    Path? path,
    TextNode? textNode,
  }) async {
    final n = getTextNode(path: path, textNode: textNode);
    final s = getSelection(selection);
    return apply(
      transaction..formatText(n, s.startIndex, s.length, attributes),
    );
  }

  Future<void> formatTextWithBuiltInAttribute(
    EditorState editorState,
    String key,
    Attributes attributes, {
    Selection? selection,
    Path? path,
    TextNode? textNode,
  }) async {
    final n = getTextNode(path: path, textNode: textNode);
    if (BuiltInAttributeKey.globalStyleKeys.contains(key)) {
      final attr = n.attributes
        ..removeWhere(
            (key, _) => BuiltInAttributeKey.globalStyleKeys.contains(key))
        ..addAll(attributes)
        ..addAll({
          BuiltInAttributeKey.subtype: key,
        });
      return apply(
        transaction..updateNode(n, attr),
      );
    } else if (BuiltInAttributeKey.partialStyleKeys.contains(key)) {
      final s = getSelection(selection);
      return apply(
        transaction..formatText(n, s.startIndex, s.length, attributes),
      );
    }
  }

  Future<void> formatTextToCheckbox(
    EditorState editorState,
    bool check, {
    Path? path,
    TextNode? textNode,
  }) async {
    return formatTextWithBuiltInAttribute(
      editorState,
      BuiltInAttributeKey.checkbox,
      {BuiltInAttributeKey.checkbox: check},
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
    return formatTextWithBuiltInAttribute(
      editorState,
      BuiltInAttributeKey.href,
      {BuiltInAttributeKey.href: link},
      path: path,
      textNode: textNode,
    );
  }

  Future<void> insertNewLine({
    Path? path,
  }) async {
    final p = path ?? getSelection(null).start.path.next;
    final transaction = this.transaction;
    transaction.insertNode(p, TextNode.empty());
    transaction.afterSelection = Selection.single(
      path: p,
      startOffset: 0,
    );
    return apply(transaction);
  }

  Future<void> insertNewLineAtCurrentSelection() async {
    final selection = getSelection(null);
    assert(selection.isCollapsed);
    final textNode = getTextNode(path: selection.start.path);
    final transaction = this.transaction;
    transaction.splitText(
      textNode,
      selection.startIndex,
    );
    return apply(transaction);
  }
}
