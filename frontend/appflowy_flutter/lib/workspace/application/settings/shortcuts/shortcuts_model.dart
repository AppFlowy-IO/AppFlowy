import 'package:appflowy_editor/appflowy_editor.dart';

class Shortcuts {
  Shortcuts({
    required this.shortcuts,
  });

  List<Shortcut> shortcuts;

  factory Shortcuts.fromJson(Map<String, dynamic> json) => Shortcuts(
        shortcuts: List<Shortcut>.from(
            json["shortcuts"].map((x) => Shortcut.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "shortcuts": List<dynamic>.from(shortcuts.map((x) => x.toJson())),
      };
}

class Shortcut {
  final String key;
  final String command;

  const Shortcut({
    required this.key,
    required this.command,
  });

  factory Shortcut.fromJson(Map<String, dynamic> json) =>
      Shortcut(key: json["key"], command: json["command"]);

  factory Shortcut.fromShortcutEvent(ShortcutEvent sEvent) =>
      Shortcut(key: sEvent.key, command: sEvent.command ?? '');

  Map<String, dynamic> toJson() => {
        "key": key,
        "command": command,
      };
}
