import 'dart:convert';
import 'dart:io' show File;
import 'package:appflowy/workspace/application/settings/shortcuts/settings_shortcuts_service.dart';
import 'package:appflowy_editor/appflowy_editor.dart'
    show ShortcutEvent, builtInShortcutEvents;
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:file/memory.dart';

void main() {
  late SettingsShortcutService service;
  late File mockFile;
  String shortcutsJson = '';

  setUp(() async {
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    mockFile = await fileSystem.file("shortcuts.json").create(recursive: true);
    service = SettingsShortcutService(passedFile: mockFile);
    shortcutsJson = """
{
"shortcuts": [
{ 
"key":"Copy",
"command":"ctrl+shift+c"
},
{
"key":"Redo",
"command":"ctrl+y"
},
{
"key":"Undo",
"command":"ctrl+shift+z"
}
]
}""";
  });

  group(
    "Settings Shortcut Service",
    () {
      test(
        "returns builtInShortcutEvents if file is empty",
        () async {
          expect(await service.loadShortcuts(), builtInShortcutEvents);
        },
      );

      test('returns shortcut event list from json string', () {
        final shortcuts = service.loadUpdatedShortcuts(shortcutsJson);
        final updatedCopyShortcutEvent =
            shortcuts.firstWhere((el) => el.key == "Copy");
        expect(updatedCopyShortcutEvent.command, 'ctrl+shift+c');
      });

      test(
        "saveShortcuts saves shortcuts",
        () async {
          final currentShortcuts = builtInShortcutEvents;
          final shortcutEvent = currentShortcuts
              .firstWhere((element) => element.key == "Move cursor up");

          expect(shortcutEvent.command, 'arrow up');

          //updating the command.
          shortcutEvent.updateCommand(command: 'alt+arrow up');

          //saving the updated shortcuts
          final expectedShortcutJson = jsonEncode(currentShortcuts.toJson());
          service.saveShortcuts(currentShortcuts);

          //reading from the mock file the saved shortcut list.
          final savedDataInFile = await mockFile.readAsString();
          expect(expectedShortcutJson, savedDataInFile);

          //now checking if the modified command of paste is shift+insert
          final shortcuts = service.loadUpdatedShortcuts(savedDataInFile);
          final updatedPasteShortcutEvent =
              shortcuts.firstWhere((el) => el.key == "Move cursor up");

          expect(updatedPasteShortcutEvent.command, 'alt+arrow up');
        },
      );

      test('load shortcuts from file', () async {
        final currentShortcuts = builtInShortcutEvents;
        final shortcutEvent =
            currentShortcuts.firstWhere((e) => e.key == "Move cursor down");

        expect(shortcutEvent.command, 'arrow down');

        //updating the command.
        shortcutEvent.updateCommand(command: 'alt+arrow down');

        //saving the updated shortcuts
        service.saveShortcuts(currentShortcuts);

        //now directly fetching the shortcuts from loadShortcuts
        final shortcuts = await service.loadShortcuts();
        expect(currentShortcuts, shortcuts);
      });
    },
  );
}

extension on List<ShortcutEvent> {
  Map<String, dynamic> toJson() => {
        "shortcuts": List<dynamic>.from(map((sEvent) => sEvent.toJson())),
      };
}

extension on ShortcutEvent {
  Map<String, dynamic> toJson() => {
        "key": key,
        "command": command,
      };
}
