import 'package:appflowy_editor/src/document/node.dart';
import 'package:appflowy_editor/src/document/path.dart';
import 'package:appflowy_editor/src/document/position.dart';
import 'package:appflowy_editor/src/document/selection.dart';
import 'package:appflowy_editor/src/document/text_delta.dart';
import 'package:appflowy_editor/src/render/rich_text/rich_text_style.dart';

extension TextNodeExtension on TextNode {
  dynamic getAttributeInSelection(Selection selection, String styleKey) {
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
        if (op.attributes?.containsKey(styleKey) == true) {
          return op.attributes![styleKey];
        }
      }
      start += length;
    }
    return null;
  }

  bool allSatisfyLinkInSelection(Selection selection) =>
      allSatisfyInSelection(StyleKey.href, selection, (value) {
        return value != null;
      });

  bool allSatisfyBoldInSelection(Selection selection) =>
      allSatisfyInSelection(StyleKey.bold, selection, (value) {
        return value == true;
      });

  bool allSatisfyItalicInSelection(Selection selection) =>
      allSatisfyInSelection(StyleKey.italic, selection, (value) {
        return value == true;
      });

  bool allSatisfyUnderlineInSelection(Selection selection) =>
      allSatisfyInSelection(StyleKey.underline, selection, (value) {
        return value == true;
      });

  bool allSatisfyStrikethroughInSelection(Selection selection) =>
      allSatisfyInSelection(StyleKey.strikethrough, selection, (value) {
        return value == true;
      });

  bool allSatisfyInSelection(
    String styleKey,
    Selection selection,
    bool Function(dynamic value) compare,
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
            !compare(op.attributes![styleKey])) {
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
    dynamic matchValue,
  ) {
    if (isEmpty) {
      return false;
    }
    if (length == 1) {
      return first.allSatisfyInSelection(styleKey, selection, (value) {
        return value == matchValue;
      });
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
        if (!node.allSatisfyInSelection(styleKey, newSelection, (value) {
          return value == matchValue;
        })) {
          return false;
        }
      }
      return true;
    }
  }
}
