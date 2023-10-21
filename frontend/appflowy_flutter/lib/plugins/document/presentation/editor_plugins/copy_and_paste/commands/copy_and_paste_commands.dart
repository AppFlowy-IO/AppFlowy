import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/commands/custom_copy_command.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/commands/custom_cut_command.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/commands/custom_paste_command.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

final List<CommandShortcutEvent> customCopyAndPasteCommands = [
  customCopyCommand,
  customPasteCommand,
  customCutCommand,
];
