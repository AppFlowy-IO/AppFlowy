import 'package:appflowy_editor/appflowy_editor.dart';

class Shortcuts {
  Shortcuts({
    required this.commandShortcuts,
  });

  final List<CommandShortcutModel> commandShortcuts;

  factory Shortcuts.fromJson(Map<String, dynamic> json) => Shortcuts(
        commandShortcuts: List<CommandShortcutModel>.from(
          json["commandShortcuts"].map(
            (x) => CommandShortcutModel.fromJson(x),
          ),
        ),
      );

  Map<String, dynamic> toJson() => {
        "commandShortcuts":
            List<dynamic>.from(commandShortcuts.map((x) => x.toJson())),
      };
}

class CommandShortcutModel {
  final String key;
  final String command;

  const CommandShortcutModel({
    required this.key,
    required this.command,
  });

  factory CommandShortcutModel.fromJson(Map<String, dynamic> json) =>
      CommandShortcutModel(
        key: json["key"],
        command: (json["command"] ?? ''),
      );

  factory CommandShortcutModel.fromCommandEvent(
    CommandShortcutEvent commandShortcutEvent,
  ) =>
      CommandShortcutModel(
        key: commandShortcutEvent.key,
        command: commandShortcutEvent.command,
      );

  Map<String, dynamic> toJson() => {
        "key": key,
        "command": command,
      };
}
