import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/commands/commands.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

final List<CommandShortcutEvent> copyAndPasteCommands = [
  customCopyCommand,
  customPasteCommand,
  customCutCommand,
];
