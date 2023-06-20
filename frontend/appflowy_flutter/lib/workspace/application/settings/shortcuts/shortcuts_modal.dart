import 'package:appflowy_editor/appflowy_editor.dart';

class Shortcuts {
  Shortcuts({
    required this.commandShortcuts,
  });

  List<CommandShortcutModal> commandShortcuts;

  factory Shortcuts.fromJson(Map<String, dynamic> json) => Shortcuts(
        commandShortcuts: List<CommandShortcutModal>.from(
          json["commandShortcuts"].map(
            (x) => CommandShortcutModal.fromJson(x),
          ),
        ),
      );

  Map<String, dynamic> toJson() => {
        "commandShortcuts":
            List<dynamic>.from(commandShortcuts.map((x) => x.toJson())),
      };
}

class CommandShortcutModal {
  final String key;
  final String command;

  const CommandShortcutModal({
    required this.key,
    required this.command,
  });

  factory CommandShortcutModal.fromJson(Map<String, dynamic> json) =>
      CommandShortcutModal(
        key: json["key"],
        command: (json["command"] ?? ''),
      );

  factory CommandShortcutModal.fromCommandEvent(
    CommandShortcutEvent commandShortcutEvent,
  ) =>
      CommandShortcutModal(
        key: commandShortcutEvent.key,
        command: commandShortcutEvent.command,
      );

  Map<String, dynamic> toJson() => {
        "key": key,
        "command": command,
      };
}
