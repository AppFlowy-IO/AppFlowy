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
      allSatisfyInSelection(selection, StyleKey.href, (value) {
        return value != null;
      });

  bool allSatisfyBoldInSelection(Selection selection) =>
      allSatisfyInSelection(selection, StyleKey.bold, (value) {
        return value == true;
      });

  bool allSatisfyItalicInSelection(Selection selection) =>
      allSatisfyInSelection(selection, StyleKey.italic, (value) {
        return value == true;
      });

  bool allSatisfyUnderlineInSelection(Selection selection) =>
      allSatisfyInSelection(selection, StyleKey.underline, (value) {
        return value == true;
      });

  bool allSatisfyStrikethroughInSelection(Selection selection) =>
      allSatisfyInSelection(selection, StyleKey.strikethrough, (value) {
        return value == true;
      });

  bool allSatisfyInSelection(
    Selection selection,
    String styleKey,
    bool Function(dynamic value) test,
  ) {
    if (StyleKey.globalStyleKeys.contains(styleKey)) {
      if (attributes.containsKey(styleKey)) {
        return test(attributes[styleKey]);
      }
    } else if (StyleKey.partialStyleKeys.contains(styleKey)) {
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
              !test(op.attributes![styleKey])) {
            return false;
          }
        }
        start += length;
      }
      return true;
    }
    return false;
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
  bool allSatisfyBoldInSelection(Selection selection) => allSatisfyInSelection(
        selection,
        StyleKey.bold,
        (value) => value == true,
      );

  bool allSatisfyItalicInSelection(Selection selection) =>
      allSatisfyInSelection(
        selection,
        StyleKey.italic,
        (value) => value == true,
      );

  bool allSatisfyUnderlineInSelection(Selection selection) =>
      allSatisfyInSelection(
        selection,
        StyleKey.underline,
        (value) => value == true,
      );

  bool allSatisfyStrikethroughInSelection(Selection selection) =>
      allSatisfyInSelection(
        selection,
        StyleKey.strikethrough,
        (value) => value == true,
      );

  bool allSatisfyInSelection(
    Selection selection,
    String styleKey,
    bool Function(dynamic value) test,
  ) {
    if (isEmpty) {
      return false;
    }
    if (length == 1) {
      return first.allSatisfyInSelection(selection, styleKey, (value) {
        return test(value);
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
        if (!node.allSatisfyInSelection(newSelection, styleKey, (value) {
          return test(value);
        })) {
          return false;
        }
      }
      return true;
    }
  }
}
