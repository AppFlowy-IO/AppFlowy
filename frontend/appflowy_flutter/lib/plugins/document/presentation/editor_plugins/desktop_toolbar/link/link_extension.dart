import 'package:appflowy/plugins/document/presentation/editor_plugins/desktop_toolbar/link/link_edit_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/toolbar_item/custom_link_toolbar_item.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

extension LinkExtension on EditorState {
  void removeLink(Selection selection) {
    final node = getNodeAtPath(selection.end.path);
    if (node == null) {
      return;
    }
    final index = selection.normalized.startIndex;
    final length = selection.length;
    final transaction = this.transaction
      ..formatText(
        node,
        index,
        length,
        {
          BuiltInAttributeKey.href: null,
          kIsPageLink: null,
        },
      );
    apply(transaction);
  }

  void applyLink(Selection selection, LinkInfo info) {
    final node = getNodeAtPath(selection.start.path);
    if (node == null) return;
    final transaction = this.transaction;
    transaction.replaceText(
      node,
      selection.startIndex,
      selection.length,
      info.name,
      attributes: info.toAttribute(),
    );
    apply(transaction);
  }
}
