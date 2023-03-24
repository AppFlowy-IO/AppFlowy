import 'dart:convert';
import 'dart:io';

import 'package:appflowy/startup/tasks/prelude.dart';
import 'package:appflowy/workspace/application/settings/shortcuts/shortcuts_model.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

class SettingsShortcutService {
  late File file;

  SettingsShortcutService({File? passedFile}) {
    if (passedFile == null) {
      _initializeService();
    } else {
      file = passedFile;
    }
  }

  Future<void> _initializeService() async {
    Directory flowyDir = await appFlowyDocumentDirectory();
    file = await File('${flowyDir.path}/shortcuts/shorcuts.json')
        .create(recursive: true);
  }

  Future<void> saveShortcuts(List<ShortcutEvent> currentShortcuts) async {
    file = await file.writeAsString(jsonEncode(currentShortcuts.toJson()),
        flush: true);
  }

  Future<List<ShortcutEvent>> loadShortcuts() async {
    final shortcutsInJson = await file.readAsString();

    if (shortcutsInJson.isEmpty) {
      return builtInShortcutEvents;
    } else {
      return loadAllSavedShortcuts(shortcutsInJson);
    }
  }

  List<ShortcutEvent> loadAllSavedShortcuts(String savedJson) {
    final shortcuts = Shortcuts.fromJson(jsonDecode(savedJson));
    for (final shortcut in shortcuts.shortcuts) {
      ShortcutEvent? shortcutEvent = builtInShortcutEvents.firstWhereOrNull(
          (sEvent) => (sEvent.key == shortcut.key &&
              sEvent.command != shortcut.command));
      if (shortcutEvent != null) {
        shortcutEvent.updateCommand(command: shortcut.command);
      }
    }
    return builtInShortcutEvents;
  }
}

extension on ShortcutEvent {
  Map<String, dynamic> toJson() => {
        "key": key,
        "command": command,
      };
}

extension on List<ShortcutEvent> {
  Map<String, dynamic> toJson() => {
        "shortcuts": List<dynamic>.from(map((sEvent) => sEvent.toJson())),
      };
}
