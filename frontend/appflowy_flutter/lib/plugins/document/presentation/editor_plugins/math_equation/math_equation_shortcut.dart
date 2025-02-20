import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'math_equation_block_component.dart';

/// Windows / Linux : ctrl + shift + e
/// macOS           : ctrl + shift + e
/// Allows the user to insert math equation by shortcut
///
/// - support
///   - desktop
///   - web
///
final CommandShortcutEvent insertMathEquationCommand = CommandShortcutEvent(
  key: 'Insert math equation',
  command: 'ctrl+shift+e',
  getDescription: LocaleKeys.document_plugins_mathEquation_name.tr,
  handler: (editorState) {
    final selection = editorState.selection;
    if (selection == null || !selection.isCollapsed) {
      return KeyEventResult.ignored;
    }
    final node = editorState.getNodeAtPath(selection.end.path);
    final delta = node?.delta;
    if (node == null || delta == null) {
      return KeyEventResult.ignored;
    }
    final newNode = mathEquationNode();
    final transaction = editorState.transaction;
    final bReplace = node.delta?.isEmpty ?? false;

    var path = node.path.next;
    if (bReplace) {
      path = node.path;
    }

    transaction
      ..insertNode(path, newNode)
      ..afterSelection = null;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final mathEquationState =
          editorState.getNodeAtPath(path)?.key.currentState;
      if (mathEquationState != null &&
          mathEquationState is MathEquationBlockComponentWidgetState) {
        mathEquationState.showEditingDialog();
      }
    });

    if (bReplace) {
      transaction.deleteNode(node);
    }
    editorState.apply(transaction);
    return KeyEventResult.handled;
  },
);
