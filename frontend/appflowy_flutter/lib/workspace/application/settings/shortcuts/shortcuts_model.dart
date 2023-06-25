import 'package:appflowy_editor/appflowy_editor.dart';

class EditorShortcuts {
  EditorShortcuts({
    required this.commandShortcuts,
  });

  final List<CommandShortcutModel> commandShortcuts;

  factory EditorShortcuts.fromJson(Map<String, dynamic> json) =>
      EditorShortcuts(
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
  const CommandShortcutModel({
    required this.key,
    required this.command,
  });

  final String key;
  final String command;

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommandShortcutModel &&
          key == other.key &&
          command == other.command;

  @override
  int get hashCode => key.hashCode ^ command.hashCode;
}
