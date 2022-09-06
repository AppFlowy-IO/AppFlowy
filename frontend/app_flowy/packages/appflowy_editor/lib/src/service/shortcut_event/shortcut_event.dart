import 'dart:io';

import 'package:appflowy_editor/src/service/shortcut_event/keybinding.dart';
import 'package:appflowy_editor/src/service/shortcut_event/shortcut_event_handler.dart';

/// Defines the implementation of shortcut event.
class ShortcutEvent {
  ShortcutEvent({
    required this.key,
    required this.command,
    required this.handler,
    String? windowsCommand,
    String? macOSCommand,
    String? linuxCommand,
  }) {
    updateCommand(
      command: command,
      windowsCommand: windowsCommand,
      macOSCommand: macOSCommand,
      linuxCommand: linuxCommand,
    );
  }

  /// The unique key.
  ///
  /// Usually, uses the description as the key.
  final String key;

  /// The string representation for the keyboard keys.
  ///
  /// The following is the mapping relationship of modify key.
  ///   ctrl: Ctrl
  ///   meta: Command in macOS or Control in Windows.
  ///   alt: Alt
  ///   shift: Shift
  ///   cmd: meta
  ///   win: meta
  ///
  /// Refer to [keyMapping] for other keys.
  ///
  /// Uses ',' to split different keyboard key combinations.
  ///
  /// Like, 'ctrl+c,cmd+c'
  ///
  String command;

  final ShortcutEventHandler handler;

  List<Keybinding> get keybindings => _keybindings;
  List<Keybinding> _keybindings = [];

  void updateCommand({
    String? command,
    String? windowsCommand,
    String? macOSCommand,
    String? linuxCommand,
  }) {
    var matched = false;
    if (Platform.isWindows &&
        windowsCommand != null &&
        windowsCommand.isNotEmpty) {
      this.command = windowsCommand;
      matched = true;
    } else if (Platform.isMacOS &&
        macOSCommand != null &&
        macOSCommand.isNotEmpty) {
      this.command = macOSCommand;
      matched = true;
    } else if (Platform.isLinux &&
        linuxCommand != null &&
        linuxCommand.isNotEmpty) {
      this.command = linuxCommand;
      matched = true;
    } else if (command != null && command.isNotEmpty) {
      this.command = command;
      matched = true;
    }

    if (matched) {
      _keybindings = this
          .command
          .split(',')
          .map((e) => Keybinding.parse(e))
          .toList(growable: false);
    }
  }

  ShortcutEvent copyWith({
    String? key,
    String? command,
    ShortcutEventHandler? handler,
  }) {
    return ShortcutEvent(
      key: key ?? this.key,
      command: command ?? this.command,
      handler: handler ?? this.handler,
    );
  }

  @override
  String toString() =>
      'ShortcutEvent(key: $key, command: $command, handler: $handler)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ShortcutEvent &&
        other.key == key &&
        other.command == command &&
        other.handler == handler;
  }

  @override
  int get hashCode => key.hashCode ^ command.hashCode ^ handler.hashCode;
}
