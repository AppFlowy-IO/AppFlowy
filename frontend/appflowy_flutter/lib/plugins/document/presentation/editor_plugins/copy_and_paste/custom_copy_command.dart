import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/sub_page/sub_page_block_component.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

/// Copy.
///
/// - support
///   - desktop
///   - web
///   - mobile
///
final CommandShortcutEvent customCopyCommand = CommandShortcutEvent(
  key: 'copy the selected content',
  getDescription: () => AppFlowyEditorL10n.current.cmdCopySelection,
  command: 'ctrl+c',
  macOSCommand: 'cmd+c',
  handler: _copyCommandHandler,
);

CommandShortcutEventHandler _copyCommandHandler =
    (editorState) => handleCopyCommand(editorState);

KeyEventResult handleCopyCommand(
  EditorState editorState, {
  bool isCut = false,
}) {
  final selection = editorState.selection?.normalized;
  if (selection == null) {
    return KeyEventResult.ignored;
  }

  String? text;
  String? html;
  String? inAppJson;

  if (selection.isCollapsed) {
    // if the selection is collapsed, we will copy the text of the current line.
    final node = editorState.getNodeAtPath(selection.end.path);
    if (node == null) {
      return KeyEventResult.ignored;
    }

    // plain text.
    text = node.delta?.toPlainText();

    // in app json
    final document = Document.blank()
      ..insert([0], [_handleNode(node.copyWith(), isCut)]);
    inAppJson = jsonEncode(document.toJson());

    // html
    html = documentToHTML(document);
  } else {
    // plain text.
    text = editorState.getTextInSelection(selection).join('\n');

    final selectedNodes = editorState.getSelectedNodes(selection: selection);
    final nodes = _handleSubPageNodes(selectedNodes, isCut);
    final document = Document.blank()..insert([0], nodes);

    // in app json
    inAppJson = jsonEncode(document.toJson());

    // html
    html = documentToHTML(document);
  }

  () async {
    await getIt<ClipboardService>().setData(
      ClipboardServiceData(
        plainText: text,
        html: html,
        inAppJson: inAppJson,
      ),
    );
  }();

  return KeyEventResult.handled;
}

List<Node> _handleSubPageNodes(List<Node> nodes, [bool isCut = false]) {
  final handled = <Node>[];
  for (final node in nodes) {
    handled.add(_handleNode(node, isCut));
  }

  return handled;
}

Node _handleNode(Node node, [bool isCut = false]) {
  if (!isCut) {
    return node.copyWith();
  }

  final newChildren = node.children.map(_handleNode).toList();

  if (node.type == SubPageBlockKeys.type) {
    return node.copyWith(
      attributes: {
        ...node.attributes,
        SubPageBlockKeys.wasCopied: !isCut,
        SubPageBlockKeys.wasCut: isCut,
      },
      children: newChildren,
    );
  }

  return node.copyWith(children: newChildren);
}
