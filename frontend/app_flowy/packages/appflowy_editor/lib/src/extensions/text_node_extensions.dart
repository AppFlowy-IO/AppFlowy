import 'package:appflowy_editor/src/document/node.dart';
import 'package:appflowy_editor/src/document/path.dart';
import 'package:appflowy_editor/src/document/position.dart';
import 'package:appflowy_editor/src/document/selection.dart';
import 'package:appflowy_editor/src/document/text_delta.dart';
import 'package:appflowy_editor/src/render/rich_text/rich_text_style.dart';

extension TextNodeExtension on TextNode {
  bool allSatisfyBoldInSelection(Selection selection) =>
      allSatisfyInSelection(StyleKey.bold, true, selection);

  bool allSatisfyItalicInSelection(Selection selection) =>
      allSatisfyInSelection(StyleKey.italic, true, selection);

  bool allSatisfyUnderlineInSelection(Selection selection) =>
      allSatisfyInSelection(StyleKey.underline, true, selection);

  bool allSatisfyStrikethroughInSelection(Selection selection) =>
      allSatisfyInSelection(StyleKey.strikethrough, true, selection);

  bool allSatisfyInSelection(
    String styleKey,
    dynamic value,
    Selection selection,
  ) {
    final ops = delta.whereType<TextInsert>();
    final startOffset =
        selection.isBackward ? selection.start.offset : selection.end.offset;
    final endOffset =
        selection.isBackward ? selection.end.offset : selection.start.offset;
    var start = 0;
    for (final op in ops) {
      if (start >= endOffset) {
        break;
      }
      final length = op.length;
      if (start < endOffset && start + length > startOffset) {
        if (op.attributes == null ||
            !op.attributes!.containsKey(styleKey) ||
            op.attributes![styleKey] != value) {
          return false;
        }
      }
      start += length;
    }
    return true;
  }

  bool allNotSatisfyInSelection(
    String styleKey,
    dynamic value,
    Selection selection,
  ) {
    final ops = delta.whereType<TextInsert>();
    final startOffset =
        selection.isBackward ? selection.start.offset : selection.end.offset;
    final endOffset =
        selection.isBackward ? selection.end.offset : selection.start.offset;
    var start = 0;
    for (final op in ops) {
      if (start >= endOffset) {
        break;
      }
      final length = op.length;
      if (start < endOffset && start + length > startOffset) {
        if (op.attributes != null &&
            op.attributes!.containsKey(styleKey) &&
            op.attributes![styleKey] == value) {
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
      allSatisfyInSelection(StyleKey.bold, selection, true);

  bool allSatisfyItalicInSelection(Selection selection) =>
      allSatisfyInSelection(StyleKey.italic, selection, true);

  bool allSatisfyUnderlineInSelection(Selection selection) =>
      allSatisfyInSelection(StyleKey.underline, selection, true);

  bool allSatisfyStrikethroughInSelection(Selection selection) =>
      allSatisfyInSelection(StyleKey.strikethrough, selection, true);

  bool allSatisfyInSelection(
    String styleKey,
    Selection selection,
    dynamic value,
  ) {
    if (isEmpty) {
      return false;
    }
    if (length == 1) {
      return first.allSatisfyInSelection(styleKey, value, selection);
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
        if (!node.allSatisfyInSelection(styleKey, value, newSelection)) {
          return false;
        }
      }
      return true;
    }
  }
}
