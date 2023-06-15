import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appflowy/startup/tasks/prelude.dart';
import 'package:appflowy/workspace/application/settings/shortcuts/shortcuts_model.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';

class SettingsShortcutService {
  late File file;
  final _initCompleter = Completer<void>();

  ///If passedFile is non null then the SettingsShortcutService uses that
  ///file to store all the shortcuts, otherwise uses the default
  ///Document Directory.
  ///Typically we only intend to pass a file during testing.
  SettingsShortcutService({File? passedFile}) {
    if (passedFile == null) {
      _initializeService();
    } else {
      file = passedFile;
      _initCompleter.complete();
    }
  }

  //Accesses the shortcuts.json file within the default AppFlowy Document Directory or creates a new file if it already doesn't exist.
  Future<void> _initializeService() async {
    final Directory flowyDir = await appFlowyDocumentDirectory();
    file = File('${flowyDir.path}/shortcuts/shortcuts.json')
      ..createSync(recursive: true);
    _initCompleter.complete();
  }

  ///Takes in commandShortcuts as input and saves them to the shortcuts.json file.
  Future<void> saveAllShortcuts(
    List<CommandShortcutEvent> commandShortcuts,
  ) async {
    final shortcuts = Shortcuts(
      commandShortcuts: commandShortcuts._toCommandShortcutModalList(),
    );

    file = await file.writeAsString(
      jsonEncode(shortcuts.toJson()),
      flush: true,
    );
  }

  ///Checks the file for saved shortcuts. If shortcuts do NOT exist then returns
  ///the standard shortcuts from the AppFlowyEditor package. If shortcuts exist
  ///then calls an utility method i.e loadAllSavedShortcuts which returns the saved shortcuts.
  Future<List<CommandShortcutEvent>> loadShortcuts() async {
    await _initCompleter.future;
    final shortcutsInJson = await file.readAsString();

    if (shortcutsInJson.isEmpty) {
      return standardCommandShortcutEvents;
    } else {
      return getShortcutsFromJson(shortcutsInJson);
    }
  }

  ///Extracts shortcuts from the saved json file. The shortcuts in the saved file consists List<CommandShortcutModal\>.
  /// This list needs to be converted to List<CommandShortcutEvent\>. This function is intended to facilitate the same.
  List<CommandShortcutEvent> getShortcutsFromJson(String savedJson) {
    final shortcuts = Shortcuts.fromJson(jsonDecode(savedJson));
    for (final shortcut in shortcuts.commandShortcuts) {
      final shortcutEvent = standardCommandShortcutEvents.firstWhereOrNull(
        (sEvent) =>
            (sEvent.key == shortcut.key && sEvent.command != shortcut.command),
      );
      if (shortcutEvent != null) {
        shortcutEvent.updateCommand(command: shortcut.command);
      }
    }
    return standardCommandShortcutEvents;
  }
}

extension on List<CommandShortcutEvent> {
  /// Utility method for converting a CommandShortcutEvent List to a
  /// CommandShortcutModal List. This is necessary for creating shortcuts
  /// object, which is used for saving the shortcuts list.
  List<CommandShortcutModal> _toCommandShortcutModalList() =>
      map((e) => CommandShortcutModal.fromCommandEvent(e)).toList();
}
