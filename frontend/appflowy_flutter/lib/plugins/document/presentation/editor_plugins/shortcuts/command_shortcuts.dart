import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/align_toolbar_item/custom_text_align_command.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/emoji_picker.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:easy_localization/easy_localization.dart';

final List<CommandShortcutEvent> defaultCommandShortcutEvents = [
  ...commandShortcutEvents.map((e) => e.copyWith()),
];

// Command shortcuts are order-sensitive. Verify order when modifying.
List<CommandShortcutEvent> commandShortcutEvents = [
  backspaceToTitle,

  arrowUpToTitle,
  arrowLeftToTitle,

  toggleToggleListCommand,

  ...localizedCodeBlockCommands,

  customCopyCommand,
  customPasteCommand,
  customCutCommand,

  ...customTextAlignCommands,

  // remove standard shortcuts for copy, cut, paste, todo
  ...standardCommandShortcutEvents
    ..removeWhere(
      (shortcut) => [
        copyCommand,
        cutCommand,
        pasteCommand,
        toggleTodoListCommand,
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
