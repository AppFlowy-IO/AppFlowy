import 'package:appflowy/plugins/document/presentation/editor_plugins/desktop_toolbar/link/link_edit_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/toolbar_item/custom_link_toolbar_item.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

class LinkUtil {
  static void removeLink(
    EditorState editorState,
    Selection selection,
  ) {
    final node = editorState.getNodeAtPath(selection.end.path);
    if (node == null) {
      return;
    }
    final index = selection.normalized.startIndex;
    final length = selection.length;
    final transaction = editorState.transaction
      ..formatText(
        node,
        index,
        length,
        {
          BuiltInAttributeKey.href: null,
          kIsPageLink: null,
        },
      );
    editorState.apply(transaction);
  }

  static void applyLink(
    EditorState editorState,
    Selection selection,
    LinkInfo info,
  ) {
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) return;
    final transaction = editorState.transaction;
    transaction.replaceText(
      node,
      selection.startIndex,
      selection.length,
      info.name,
      attributes: info.toAttribute(),
    );
    editorState.apply(transaction);
  }
}
