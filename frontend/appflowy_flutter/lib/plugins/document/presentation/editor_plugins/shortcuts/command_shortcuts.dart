import 'dart:io';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/align_toolbar_item/custom_text_align_command.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/math_equation/math_equation_shortcut.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/shortcuts/custom_delete_command.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/undo_redo/custom_undo_redo_commands.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/emoji_picker.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'exit_edit_mode_command.dart';

final closeTabCommand = CommandShortcutEvent(
  key: 'close_current_tab',
  getDescription: () => 'Close current tab',
  command: Platform.isMacOS ? 'cmd+w' : 'ctrl+w',
  handler: (editorState) => KeyEventResult.ignored,
);

final nextTabCommand = CommandShortcutEvent(
  key: 'go_to_next_tab',
  getDescription: () => 'Go to next tab',
  command: Platform.isMacOS ? 'cmd+pagedown' : 'ctrl+pagedown',
  handler: (editorState) => KeyEventResult.ignored,
);

final previousTabCommand = CommandShortcutEvent(
  key: 'go_to_previous_tab',
  getDescription: () => 'Go to previous tab',
  command: Platform.isMacOS ? 'cmd+pageup' : 'ctrl+pageup',
  handler: (editorState) => KeyEventResult.ignored,
);

final collapseSidebarCommand = CommandShortcutEvent(
  key: 'collapse_sidebar_menu',
  getDescription: () => 'Collapse sidebar menu',
  command: Platform.isMacOS ? 'cmd+\\' : 'ctrl+\\',
  handler: (editorState) => KeyEventResult.ignored,
);

final toggleThemeModeCommand = CommandShortcutEvent(
  key: 'toggle_theme_mode',
  getDescription: () => 'Toggle theme mode',
  command: Platform.isMacOS ? 'cmd+shift+l' : 'ctrl+shift+l',
  handler: (editorState) => KeyEventResult.ignored,
);

final List<CommandShortcutEvent> defaultCommandShortcutEvents = [
  ...commandShortcutEvents.map((e) => e.copyWith()),
];

// Command shortcuts are order-sensitive. Verify order when modifying.
List<CommandShortcutEvent> commandShortcutEvents = [
  ...simpleTableCommands,

  customExitEditingCommand,
  backspaceToTitle,
  removeToggleHeadingStyle,

  arrowUpToTitle,
  arrowLeftToTitle,

  toggleToggleListCommand,

  ...localizedCodeBlockCommands,

  customCopyCommand,
  customPasteCommand,
  customPastePlainTextCommand,
  customCutCommand,
  customUndoCommand,
  customRedoCommand,

  ...customTextAlignCommands,

  customDeleteCommand,
  insertInlineMathEquationCommand,

  closeTabCommand,
  nextTabCommand,
  previousTabCommand,
  collapseSidebarCommand,
  toggleThemeModeCommand,

  // remove standard shortcuts for copy, cut, paste, todo
  ...standardCommandShortcutEvents
    ..removeWhere(
      (shortcut) => [
        copyCommand,
        cutCommand,
        pasteCommand,
        pasteTextWithoutFormattingCommand,
        toggleTodoListCommand,
        undoCommand,
        redoCommand,
        exitEditingCommand,
        ...tableCommands,
        deleteCommand,
      ].contains(shortcut),
    ),

  emojiShortcutEvent,
];

final _codeBlockLocalization = CodeBlockLocalizations(
  codeBlockNewParagraph:
      LocaleKeys.settings_shortcutsPage_commands_codeBlockNewParagraph.tr(),
  codeBlockIndentLines:
      LocaleKeys.settings_shortcutsPage_commands_codeBlockIndentLines.tr(),
  codeBlockOutdentLines:
      LocaleKeys.settings_shortcutsPage_commands_codeBlockOutdentLines.tr(),
  codeBlockSelectAll:
      LocaleKeys.settings_shortcutsPage_commands_codeBlockSelectAll.tr(),
  codeBlockPasteText:
      LocaleKeys.settings_shortcutsPage_commands_codeBlockPasteText.tr(),
  codeBlockAddTwoSpaces:
      LocaleKeys.settings_shortcutsPage_commands_codeBlockAddTwoSpaces.tr(),
);

final localizedCodeBlockCommands = codeBlockCommands(
  localizations: _codeBlockLocalization,
);
