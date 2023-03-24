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
    shortcutsJson =
        """
{
"shortcuts": [
{ 
"key":"Home",
"command":"alt+home"
},
{
"key":"End",
"command":"alt+end"
},
{
"key":"Delete Text",
"command":"alt+delete"
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

      test('returns updated shortcut event list from json', () {
        final shortcuts = service.loadAllSavedShortcuts(shortcutsJson);
        final updatedCopyShortcutEvent =
            shortcuts.firstWhere((el) => el.key == "Home");
        expect(updatedCopyShortcutEvent.command, 'alt+home');
        expect(shortcuts.length, builtInShortcutEvents.length);
        expect(shortcuts, builtInShortcutEvents);
      });

      test(
        "saveShortcuts saves shortcuts",
        () async {
          final currentShortcuts = builtInShortcutEvents;
          final shortcutEvent = currentShortcuts
              .firstWhere((element) => element.key == "Page up");

          expect(shortcutEvent.command, 'page up');

          //updating the command.
          shortcutEvent.updateCommand(command: 'alt+page up');

          //saving the updated shortcuts
          final expectedShortcutJson = jsonEncode(currentShortcuts.toJson());
          service.saveShortcuts(currentShortcuts);

          //reading from the mock file the saved shortcut list.

          final savedDataInFile = await mockFile.readAsString();
          expect(expectedShortcutJson, savedDataInFile);

          //now checking if the modified command of page up is alt+page up
          final shortcuts = service.loadAllSavedShortcuts(savedDataInFile);
          final updatedPageUpSEvent =
              shortcuts.firstWhere((el) => el.key == "Page up");

          expect(updatedPageUpSEvent.command, 'alt+page up');
        },
      );

      test('load shortcuts from file', () async {
        final currentShortcuts = builtInShortcutEvents;
        final shortcutEvent =
            currentShortcuts.firstWhere((e) => e.key == "Page down");

        expect(shortcutEvent.command, 'page down');

        //updating the command.
        shortcutEvent.updateCommand(command: 'alt+page down');

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
