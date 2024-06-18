import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';

final List<CommandShortcutEvent> customTextAlignCommands = [
  customTextLeftAlignCommand,
  customTextCenterAlignCommand,
  customTextRightAlignCommand,
];

/// Windows / Linux : ctrl + shift + l
/// macOS           : ctrl + shift + l
/// Allows the user to align text to the left
///
/// - support
///   - desktop
///   - web
///
final CommandShortcutEvent customTextLeftAlignCommand = CommandShortcutEvent(
  key: 'Align text to the left',
  command: 'ctrl+shift+l',
  getDescription: LocaleKeys.settings_shortcutsPage_commands_textAlignLeft.tr,
  handler: (editorState) => _textAlignHandler(editorState, leftAlignmentKey),
);

/// Windows / Linux : ctrl + shift + e
/// macOS           : ctrl + shift + e
/// Allows the user to align text to the center
///
/// - support
///   - desktop
///   - web
///
final CommandShortcutEvent customTextCenterAlignCommand = CommandShortcutEvent(
  key: 'Align text to the center',
  command: 'ctrl+shift+e',
  getDescription: LocaleKeys.settings_shortcutsPage_commands_textAlignCenter.tr,
  handler: (editorState) => _textAlignHandler(editorState, centerAlignmentKey),
);

/// Windows / Linux : ctrl + shift + r
/// macOS           : ctrl + shift + r
/// Allows the user to align text to the right
///
/// - support
///   - desktop
///   - web
///
final CommandShortcutEvent customTextRightAlignCommand = CommandShortcutEvent(
  key: 'Align text to the right',
  command: 'ctrl+shift+r',
  getDescription: LocaleKeys.settings_shortcutsPage_commands_textAlignRight.tr,
  handler: (editorState) => _textAlignHandler(editorState, rightAlignmentKey),
);

KeyEventResult _textAlignHandler(EditorState editorState, String align) {
  final Selection? selection = editorState.selection;

  if (selection == null) {
    return KeyEventResult.ignored;
  }

  editorState.updateNode(
    selection,
    (node) => node.copyWith(
      attributes: {
        ...node.attributes,
        blockComponentAlign: align,
      },
    ),
  );

  return KeyEventResult.handled;
}
