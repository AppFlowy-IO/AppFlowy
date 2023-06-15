import 'dart:convert';
import 'dart:io' show File;
import 'package:appflowy/workspace/application/settings/shortcuts/settings_shortcuts_service.dart';
import 'package:appflowy/workspace/application/settings/shortcuts/shortcuts_model.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
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
    shortcutsJson = """{
   "commandShortcuts":[
      {
         "key":"move the cursor upward",
         "command":"alt+arrow up"
      },
      {
         "key":"move the cursor forward one character",
         "command":"alt+arrow left"
      },
      {
         "key":"move the cursor downward",
         "command":"alt+arrow down"
      }
   ]
}""";
  });

  group(
    "Settings Shortcut Service",
    () {
      test(
        "returns default standard shortcuts if file is empty",
        () async {
          expect(await service.loadShortcuts(), standardCommandShortcutEvents);
        },
      );

      test('returns updated shortcut event list from json', () {
        final commandShortcuts = service.getShortcutsFromJson(shortcutsJson);

        final cursorUpShortcut = commandShortcuts
            .firstWhere((el) => el.key == "move the cursor upward");

        final cursorDownShortcut = commandShortcuts
            .firstWhere((el) => el.key == "move the cursor downward");

        expect(
          commandShortcuts.length,
          standardCommandShortcutEvents.length,
        );
        expect(cursorUpShortcut.command, "alt+arrow up");
        expect(cursorDownShortcut.command, "alt+arrow down");
      });

      test(
        "saveAllShortcuts saves shortcuts",
        () async {
          //updating one of standard command shortcut events.
          final currentCommandShortcuts = standardCommandShortcutEvents;
          const kKey = "scroll one page down";
          const oldCommand = "page down";
          const newCommand = "alt+page down";
          final commandShortcutEvent = currentCommandShortcuts
              .firstWhere((element) => element.key == kKey);

          expect(commandShortcutEvent.command, oldCommand);

          //updating the command.
          commandShortcutEvent.updateCommand(
            command: newCommand,
          );

          //saving the updated shortcuts
          await service.saveAllShortcuts(currentCommandShortcuts);

          //reading from the mock file the saved shortcut list.
          final savedDataInFile = await mockFile.readAsString();

          //Check if the lists where properly converted to json and saved.
          final shortcuts = Shortcuts(
            commandShortcuts:
                currentCommandShortcuts._toCommandShortcutModalList(),
          );

          expect(jsonEncode(shortcuts.toJson()), savedDataInFile);

          //now checking if the modified command of "move the cursor upward" is "arrow up"
          final newCommandShortcuts =
              service.getShortcutsFromJson(savedDataInFile);

          final updatedCommandEvent =
              newCommandShortcuts.firstWhere((el) => el.key == kKey);

          expect(updatedCommandEvent.command, newCommand);
        },
      );

      test('load shortcuts from file', () async {
        //updating one of standard command shortcut events.
        const kKey = "scroll one page up";
        const oldCommand = "page up";
        const newCommand = "alt+page up";
        final currentCommandShortcuts = standardCommandShortcutEvents;
        final commandShortcutEvent = currentCommandShortcuts
            .firstWhere((element) => element.key == kKey);

        expect(commandShortcutEvent.command, oldCommand);

        //updating the command.
        commandShortcutEvent.updateCommand(command: newCommand);

        //saving the updated shortcuts
        service.saveAllShortcuts(currentCommandShortcuts);

        //now directly fetching the shortcuts from loadShortcuts
        final commandShortcuts = await service.loadShortcuts();
        expect(commandShortcuts, currentCommandShortcuts);

        final updatedCommandEvent =
            commandShortcuts.firstWhere((el) => el.key == kKey);

        expect(updatedCommandEvent.command, newCommand);
      });
    },
  );
}

extension on List<CommandShortcutEvent> {
  List<CommandShortcutModal> _toCommandShortcutModalList() =>
      map((e) => CommandShortcutModal.fromCommandEvent(e)).toList();
}
