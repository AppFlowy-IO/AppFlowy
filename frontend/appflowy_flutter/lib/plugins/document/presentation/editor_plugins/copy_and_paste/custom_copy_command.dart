import 'dart:convert';

import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/sub_page/sub_page_block_component.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

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
      ..insert([0], [_handleNode(node.deepCopy(), isCut)]);
    inAppJson = jsonEncode(document.toJson());

    // html
    html = documentToHTML(document);
  } else {
    // plain text.
    text = editorState.getTextInSelection(selection).join('\n');

    final document = _buildCopiedDocument(
      editorState,
      selection,
      isCut: isCut,
    );

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

Document _buildCopiedDocument(
  EditorState editorState,
  Selection selection, {
  bool isCut = false,
}) {
  // filter the table nodes
  final filteredNodes = <Node>[];
  final selectedNodes = editorState.getSelectedNodes(selection: selection);
  final nodes = _handleSubPageNodes(selectedNodes, isCut);
  for (final node in nodes) {
    if (node.type == SimpleTableCellBlockKeys.type) {
      // if the node is a table cell, we will fetch its children instead.
      filteredNodes.addAll(node.children);
    } else if (node.type == SimpleTableRowBlockKeys.type) {
      // if the node is a table row, we will fetch its children instead.
      filteredNodes.addAll(node.children.expand((e) => e.children));
    } else {
      filteredNodes.add(node);
    }
  }
  final document = Document.blank()
    ..insert(
      [0],
      filteredNodes.map((e) => e.deepCopy()),
    );
  return document;
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
    return node.deepCopy();
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
