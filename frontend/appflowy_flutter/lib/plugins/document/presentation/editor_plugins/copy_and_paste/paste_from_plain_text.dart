import 'package:appflowy/plugins/document/presentation/editor_plugins/link_preview/paste_as/paste_as_menu.dart';
import 'package:appflowy/shared/markdown_to_document.dart';
import 'package:appflowy/shared/patterns/common_patterns.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

extension PasteFromPlainText on EditorState {
  Future<void> pastePlainText(String plainText) async {
    await deleteSelectionIfNeeded();
    final nodes = plainText
        .split('\n')
        .map(
          (e) => e
            ..replaceAll(r'\r', '')
            ..trimRight(),
        )
        .map((e) => Delta()..insert(e))
        .map((e) => paragraphNode(delta: e))
        .toList();
    if (nodes.isEmpty) {
      return;
    }
    if (nodes.length == 1) {
      await pasteSingleLineNode(nodes.first);
    } else {
      await pasteMultiLineNodes(nodes.toList());
    }
  }

  Future<void> pasteText(String plainText) async {
    if (await pasteHtmlIfAvailable(plainText)) {
      return;
    }

    await deleteSelectionIfNeeded();

    /// try to parse the plain text as markdown
    final nodes = customMarkdownToDocument(plainText).root.children;
    if (nodes.isEmpty) {
      /// if the markdown parser failed, fallback to the plain text parser
      await pastePlainText(plainText);
      return;
    }
    if (nodes.length == 1) {
      await pasteSingleLineNode(nodes.first);
      final href = _getLinkFromNode(nodes.first);
      if (href != null) {
        final context = document.root.context;
        if (context != null && context.mounted) {
          PasteAsMenuService(context: context, editorState: this).show(href);
        }
      }
    } else {
      await pasteMultiLineNodes(nodes.toList());
    }
  }

  Future<bool> pasteHtmlIfAvailable(String plainText) async {
    final selection = this.selection;
    if (selection == null ||
        !selection.isSingle ||
        selection.isCollapsed ||
        !hrefRegex.hasMatch(plainText)) {
      return false;
    }

    final node = getNodeAtPath(selection.start.path);
    if (node == null) {
      return false;
    }

    final transaction = this.transaction;
    transaction.formatText(node, selection.startIndex, selection.length, {
      AppFlowyRichTextKeys.href: plainText,
    });
    await apply(transaction);
    return true;
  }

  String? _getLinkFromNode(Node node) {
    for (final insert in node.delta!) {
      final link = insert.attributes?.href;
      if (link != null) return link;
    }
    return null;
  }
}
