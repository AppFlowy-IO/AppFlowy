import 'dart:convert';
import 'dart:io' show File;

import 'package:appflowy/workspace/application/settings/shortcuts/settings_shortcuts_service.dart';
import 'package:appflowy/workspace/application/settings/shortcuts/shortcuts_model.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
// ignore: depend_on_referenced_packages
import 'package:file/memory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SettingsShortcutService service;
  late File mockFile;
  String shortcutsJson = '';

  setUp(() async {
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    mockFile = await fileSystem.file("shortcuts.json").create(recursive: true);
    service = SettingsShortcutService(file: mockFile);
    shortcutsJson = """{
   "commandShortcuts":[
      {
         "key":"move the cursor upward",
         "command":"alt+arrow up"
      },
      {
         "key":"move the cursor backward one character",
         "command":"alt+arrow left"
      },
      {
         "key":"move the cursor downward",
         "command":"alt+arrow down"
      }
   ]
}""";
  });

  group("Settings Shortcut Service", () {
    test(
      "returns default standard shortcuts if file is empty",
      () async {
        expect(await service.getCustomizeShortcuts(), []);
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
        3,
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

        //Check if the lists where properly converted to JSON and saved.
        final shortcuts = EditorShortcuts(
          commandShortcuts:
              currentCommandShortcuts.toCommandShortcutModelList(),
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
      //updating one of standard command shortcut event.
      const kKey = "scroll one page up";
      const oldCommand = "page up";
      const newCommand = "alt+page up";
      final currentCommandShortcuts = standardCommandShortcutEvents;
      final commandShortcutEvent =
          currentCommandShortcuts.firstWhere((element) => element.key == kKey);

      expect(commandShortcutEvent.command, oldCommand);

      //updating the command.
      commandShortcutEvent.updateCommand(command: newCommand);

      //saving the updated shortcuts
      await service.saveAllShortcuts(currentCommandShortcuts);

      //now directly fetching the shortcuts from loadShortcuts
      final commandShortcuts = await service.getCustomizeShortcuts();
      expect(
        commandShortcuts,
        currentCommandShortcuts.toCommandShortcutModelList(),
      );

      final updatedCommandEvent =
          commandShortcuts.firstWhere((el) => el.key == kKey);

      expect(updatedCommandEvent.command, newCommand);
    });

    test('updateCommandShortcuts works properly', () async {
      //updating one of standard command shortcut event.
      const kKey = "move the cursor backward one character";
      const oldCommand = "arrow left";
      const newCommand = "alt+arrow left";
      final currentCommandShortcuts = standardCommandShortcutEvents;

      //check if the current shortcut event's key is set to old command.
      final currentCommandEvent =
          currentCommandShortcuts.firstWhere((el) => el.key == kKey);

      expect(currentCommandEvent.command, oldCommand);

      final commandShortcutModelList =
          EditorShortcuts.fromJson(jsonDecode(shortcutsJson)).commandShortcuts;

      //now calling the updateCommandShortcuts method
      await service.updateCommandShortcuts(
        currentCommandShortcuts,
        commandShortcutModelList,
      );

      //check if the shortcut event's key is updated.
      final updatedCommandEvent =
          currentCommandShortcuts.firstWhere((el) => el.key == kKey);

      expect(updatedCommandEvent.command, newCommand);
    });
  });
}

extension on List<CommandShortcutEvent> {
  List<CommandShortcutModel> toCommandShortcutModelList() =>
      map((e) => CommandShortcutModel.fromCommandEvent(e)).toList();
}
