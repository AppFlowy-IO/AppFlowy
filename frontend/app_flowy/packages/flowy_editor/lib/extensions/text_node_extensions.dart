import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/document/path.dart';
import 'package:flowy_editor/document/position.dart';
import 'package:flowy_editor/document/selection.dart';
import 'package:flowy_editor/document/text_delta.dart';
import 'package:flowy_editor/render/rich_text/rich_text_style.dart';

extension TextNodeExtension on TextNode {
  bool allSatisfyBoldInSelection(Selection selection) =>
      allSatisfyInSelection(StyleKey.bold, selection);

  bool allSatisfyItalicInSelection(Selection selection) =>
      allSatisfyInSelection(StyleKey.italic, selection);

  bool allSatisfyUnderlineInSelection(Selection selection) =>
      allSatisfyInSelection(StyleKey.underline, selection);

  bool allSatisfyStrikethroughInSelection(Selection selection) =>
      allSatisfyInSelection(StyleKey.strikethrough, selection);

  bool allSatisfyInSelection(String styleKey, Selection selection) {
    final ops = delta.operations.whereType<TextInsert>();
    var start = 0;
    for (final op in ops) {
      if (start >= selection.end.offset) {
        break;
      }
      final length = op.length;
      if (start < selection.end.offset &&
          start + length > selection.start.offset) {
        if (op.attributes == null ||
            !op.attributes!.containsKey(styleKey) ||
            op.attributes![styleKey] == false) {
          return false;
        }
      }
      start += length;
    }
    return true;
  }
}

extension TextNodesExtension on List<TextNode> {
  bool allSatisfyBoldInSelection(Selection selection) =>
      allSatisfyInSelection(StyleKey.bold, selection);

  bool allSatisfyItalicInSelection(Selection selection) =>
      allSatisfyInSelection(StyleKey.italic, selection);

  bool allSatisfyUnderlineInSelection(Selection selection) =>
      allSatisfyInSelection(StyleKey.underline, selection);

  bool allSatisfyStrikethroughInSelection(Selection selection) =>
      allSatisfyInSelection(StyleKey.strikethrough, selection);

  bool allSatisfyInSelection(String styleKey, Selection selection) {
    if (isEmpty) {
      return false;
    }
    if (length == 1) {
      return first.allSatisfyInSelection(styleKey, selection);
    } else {
      for (var i = 0; i < length; i++) {
        final node = this[i];
        final Selection newSelection;
        if (i == 0 && pathEquals(node.path, selection.start.path)) {
          newSelection = selection.copyWith(
            end: Position(path: node.path, offset: node.toRawString().length),
          );
        } else if (i == length - 1 &&
            pathEquals(node.path, selection.end.path)) {
          newSelection = selection.copyWith(
            start: Position(path: node.path, offset: 0),
          );
        } else {
          newSelection = Selection(
            start: Position(path: node.path, offset: 0),
            end: Position(path: node.path, offset: node.toRawString().length),
          );
        }
        if (!node.allSatisfyInSelection(styleKey, newSelection)) {
          return false;
        }
      }
      return true;
    }
  }
}
