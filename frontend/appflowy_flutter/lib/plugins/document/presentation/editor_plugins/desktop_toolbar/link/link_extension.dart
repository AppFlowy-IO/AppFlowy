import 'package:appflowy/plugins/document/presentation/editor_plugins/desktop_toolbar/link/link_edit_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/toolbar_item/custom_link_toolbar_item.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

extension LinkExtension on EditorState {
  void removeLink(Selection selection) {
    final node = getNodeAtPath(selection.end.path);
    if (node == null) {
      return;
    }
    final attributes = _getAttribute(node, selection);
    attributes[BuiltInAttributeKey.href] = null;
    attributes[kIsPageLink] = null;
    final index = selection.normalized.startIndex;
    final length = selection.length;
    final transaction = this.transaction
      ..formatText(node, index, length, attributes);
    apply(transaction);
  }

  void applyLink(Selection selection, LinkInfo info) {
    final node = getNodeAtPath(selection.start.path);
    if (node == null) return;
    final transaction = this.transaction;
    final attributes = _getAttribute(node, selection);
    attributes.addAll(info.toAttribute());
    final linkName = info.name.isEmpty ? info.link : info.name;
    transaction.replaceText(
      node,
      selection.startIndex,
      selection.length,
      linkName,
      attributes: attributes,
    );
    apply(transaction);
  }

  void removeAndReplaceLink(
    Selection selection,
    String text,
  ) {
    final node = getNodeAtPath(selection.end.path);
    if (node == null) {
      return;
    }
    final attributes = _getAttribute(node, selection);
    attributes[BuiltInAttributeKey.href] = null;
    attributes[kIsPageLink] = null;
    final index = selection.normalized.startIndex;
    final length = selection.length;
    final transaction = this.transaction
      ..replaceText(node, index, length, text, attributes: attributes);
    apply(transaction);
  }

  Attributes _getAttribute(Node node, Selection selection) {
    Attributes attributes = {};
    final ops = node.delta?.whereType<TextInsert>() ?? [];
    final startOffset = selection.start.offset;
    var start = 0;
    for (final op in ops) {
      if (start > startOffset) break;
      final length = op.length;
      if (start + length > startOffset) {
        attributes = op.attributes ?? {};
        break;
      }
      start += length;
    }

    return attributes;
  }
}
