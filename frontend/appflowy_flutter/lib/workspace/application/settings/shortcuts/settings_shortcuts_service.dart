import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appflowy/startup/tasks/prelude.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';

import 'shortcuts_modal.dart';

class SettingsShortcutService {
  /// If file is non null then the SettingsShortcutService uses that
  /// file to store all the shortcuts, otherwise uses the default
  /// Document Directory.
  /// Typically we only intend to pass a file during testing.
  SettingsShortcutService({
    File? file,
  }) {
    _initializeService(file);
  }

  late final File _file;
  final _initCompleter = Completer<void>();

  ///Takes in commandShortcuts as an input and saves them to the shortcuts.json file.
  Future<void> saveAllShortcuts(
    List<CommandShortcutEvent> commandShortcuts,
  ) async {
    final shortcuts = Shortcuts(
      commandShortcuts: commandShortcuts.toCommandShortcutModelList(),
    );

    await _file.writeAsString(
      jsonEncode(shortcuts.toJson()),
      flush: true,
    );
  }

  ///Checks the file for saved shortcuts. If shortcuts do NOT exist then returns
  ///the standard shortcuts from the AppFlowyEditor package. If shortcuts exist
  ///then calls an utility method i.e loadAllSavedShortcuts which returns the saved shortcuts.
  Future<List<CommandShortcutEvent>> loadShortcuts() async {
    await _initCompleter.future;
    final shortcutsInJson = await _file.readAsString();

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
      final shortcutEvent = _findMatchingShortcutEvent(shortcut);
      if (shortcutEvent != null) {
        shortcutEvent.updateCommand(command: shortcut.command);
      }
    }
    return standardCommandShortcutEvents;
  }

  // Accesses the shortcuts.json file within the default AppFlowy Document Directory or creates a new file if it already doesn't exist.
  Future<void> _initializeService(File? file) async {
    _file = file ?? await _defaultShortcutFile();
    _initCompleter.complete();
  }

  //returns the default file for storing shortcuts
  Future<File> _defaultShortcutFile() async {
    final Directory flowyDir = await appFlowyDocumentDirectory();
    return File('${flowyDir.path}/shortcuts/shortcuts.json')
      ..createSync(recursive: true);
  }

  //returns ShortcutEvent if its key matches with saved shortcut and commmand doesn't. May return null if nothing found.
  CommandShortcutEvent? _findMatchingShortcutEvent(CommandShortcutModel c) {
    return standardCommandShortcutEvents.firstWhereOrNull(
      (s) => (s.key == c.key && s.command != c.command),
    );
  }
}

extension on List<CommandShortcutEvent> {
  /// Utility method for converting a CommandShortcutEvent List to a
  /// CommandShortcutModal List. This is necessary for creating shortcuts
  /// object, which is used for saving the shortcuts list.
  List<CommandShortcutModel> toCommandShortcutModelList() =>
      map((e) => CommandShortcutModel.fromCommandEvent(e)).toList();
}
