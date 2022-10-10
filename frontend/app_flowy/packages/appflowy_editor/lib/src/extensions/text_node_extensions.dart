import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/core/document/path.dart';
import 'package:appflowy_editor/src/core/selection/position.dart';
import 'package:appflowy_editor/src/document/selection.dart';
import 'package:appflowy_editor/src/core/document/text_delta.dart';
import 'package:appflowy_editor/src/document/built_in_attribute_keys.dart';

extension TextNodeExtension on TextNode {
  T? getAttributeInSelection<T>(Selection selection, String styleKey) {
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
        final attributes = op.attributes;
        if (attributes != null && attributes[styleKey] is T?) {
          return attributes[styleKey];
        }
      }
      start += length;
    }
    return null;
  }

  bool allSatisfyLinkInSelection(Selection selection) =>
      allSatisfyInSelection(selection, BuiltInAttributeKey.href, (value) {
        return value != null;
      });

  bool allSatisfyBoldInSelection(Selection selection) =>
      allSatisfyInSelection(selection, BuiltInAttributeKey.bold, (value) {
        return value == true;
      });

  bool allSatisfyItalicInSelection(Selection selection) =>
      allSatisfyInSelection(selection, BuiltInAttributeKey.italic, (value) {
        return value == true;
      });

  bool allSatisfyUnderlineInSelection(Selection selection) =>
      allSatisfyInSelection(selection, BuiltInAttributeKey.underline, (value) {
        return value == true;
      });

  bool allSatisfyStrikethroughInSelection(Selection selection) =>
      allSatisfyInSelection(selection, BuiltInAttributeKey.strikethrough,
          (value) {
        return value == true;
      });

  bool allSatisfyCodeInSelection(Selection selection) =>
      allSatisfyInSelection(selection, BuiltInAttributeKey.code, (value) {
        return value == true;
      });

  bool allSatisfyInSelection(
    Selection selection,
    String styleKey,
    bool Function(dynamic value) test,
  ) {
    if (BuiltInAttributeKey.globalStyleKeys.contains(styleKey)) {
      if (attributes.containsKey(styleKey)) {
        return test(attributes[styleKey]);
      }
    } else if (BuiltInAttributeKey.partialStyleKeys.contains(styleKey)) {
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
        BuiltInAttributeKey.bold,
        (value) => value == true,
      );

  bool allSatisfyItalicInSelection(Selection selection) =>
      allSatisfyInSelection(
        selection,
        BuiltInAttributeKey.italic,
        (value) => value == true,
      );

  bool allSatisfyUnderlineInSelection(Selection selection) =>
      allSatisfyInSelection(
        selection,
        BuiltInAttributeKey.underline,
        (value) => value == true,
      );

  bool allSatisfyStrikethroughInSelection(Selection selection) =>
      allSatisfyInSelection(
        selection,
        BuiltInAttributeKey.strikethrough,
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
        if (i == 0 && node.path.equals(selection.start.path)) {
          if (selection.isBackward) {
            newSelection = selection.copyWith(
              end: Position(path: node.path, offset: node.toPlainText().length),
            );
          } else {
            newSelection = selection.copyWith(
              end: Position(path: node.path, offset: 0),
            );
          }
        } else if (i == length - 1 && node.path.equals(selection.end.path)) {
          if (selection.isBackward) {
            newSelection = selection.copyWith(
              start: Position(path: node.path, offset: 0),
            );
          } else {
            newSelection = selection.copyWith(
              start:
                  Position(path: node.path, offset: node.toPlainText().length),
            );
          }
        } else {
          newSelection = Selection(
            start: Position(path: node.path, offset: 0),
            end: Position(path: node.path, offset: node.toPlainText().length),
          );
        }
        if (!node.allSatisfyInSelection(newSelection, styleKey, test)) {
          return false;
        }
      }
      return true;
    }
  }
}
