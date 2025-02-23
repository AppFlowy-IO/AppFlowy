import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Windows / Linux : ctrl + shift + e
/// macOS           : cmd + shift + e
/// Allows the user to insert math equation by shortcut
///
/// - support
///   - desktop
///   - web
///
final CommandShortcutEvent insertInlineMathEquationCommand =
    CommandShortcutEvent(
  key: 'Insert inline math equation',
  command: 'ctrl+shift+e',
  macOSCommand: 'cmd+shift+e',
  getDescription: LocaleKeys.document_plugins_mathEquation_name.tr,
  handler: (editorState) {
    final selection = editorState.selection;
    if (selection == null || selection.isCollapsed || !selection.isSingle) {
      return KeyEventResult.ignored;
    }
    final node = editorState.getNodeAtPath(selection.start.path);
    final delta = node?.delta;
    if (node == null || delta == null) {
      return KeyEventResult.ignored;
    }
    if (node.delta == null || !toolbarItemWhiteList.contains(node.type)) {
      return KeyEventResult.ignored;
    }
    final transaction = editorState.transaction;
    final nodes = editorState.getNodesInSelection(selection);
    final isHighlight = nodes.allSatisfyInSelection(selection, (delta) {
      return delta.everyAttributes(
        (attributes) => attributes[InlineMathEquationKeys.formula] != null,
      );
    });
    if (isHighlight) {
      final formula = delta
          .slice(selection.startIndex, selection.endIndex)
          .whereType<TextInsert>()
          .firstOrNull
          ?.attributes?[InlineMathEquationKeys.formula];
      assert(formula != null);
      if (formula == null) {
        return KeyEventResult.ignored;
      }
      // clear the format
      transaction.replaceText(
        node,
        selection.startIndex,
        selection.length,
        formula,
        attributes: {},
      );
    } else {
      final text = editorState.getTextInSelection(selection).join();
      transaction.replaceText(
        node,
        selection.startIndex,
        selection.length,
        MentionBlockKeys.mentionChar,
        attributes: {
          InlineMathEquationKeys.formula: text,
        },
      );
    }
    editorState.apply(transaction);
    return KeyEventResult.handled;
  },
);
