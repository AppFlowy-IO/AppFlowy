import 'dart:convert';

import 'package:appflowy_editor/src/service/shortcut_event/key_mapping.dart';
import 'package:flutter/material.dart';

extension KeybindingsExtension on List<Keybinding> {
  bool containsKeyEvent(RawKeyEvent keyEvent) {
    for (final keybinding in this) {
      if (keybinding.isMetaPressed == keyEvent.isMetaPressed &&
          keybinding.isControlPressed == keyEvent.isControlPressed &&
          keybinding.isAltPressed == keyEvent.isAltPressed &&
          keybinding.isShiftPressed == keyEvent.isShiftPressed &&
          keybinding.keyCode == keyEvent.logicalKey.keyId) {
        return true;
      }
    }
    return false;
  }
}

class Keybinding {
  Keybinding({
    required this.isAltPressed,
    required this.isControlPressed,
    required this.isMetaPressed,
    required this.isShiftPressed,
    required this.keyLabel,
  });

  factory Keybinding.parse(String command) {
    command = command.toLowerCase().trim();

    var isAltPressed = false;
    var isControlPressed = false;
    var isMetaPressed = false;
    var isShiftPressed = false;

    var matchedModifier = false;

    do {
      matchedModifier = false;
      if (RegExp(r'^alt(\+|\-)').hasMatch(command)) {
        isAltPressed = true;
        command = command.substring(4); // 4 = 'alt '.length
        matchedModifier = true;
      }
      if (RegExp(r'^ctrl(\+|\-)').hasMatch(command)) {
        isControlPressed = true;
        command = command.substring(5); // 5 = 'ctrl '.length
        matchedModifier = true;
      }
      if (RegExp(r'^shift(\+|\-)').hasMatch(command)) {
        isShiftPressed = true;
        command = command.substring(6); // 6 = 'shift '.length
        matchedModifier = true;
      }
      if (RegExp(r'^meta(\+|\-)').hasMatch(command)) {
        isMetaPressed = true;
        command = command.substring(5); // 5 = 'meta '.length
        matchedModifier = true;
      }
      if (RegExp(r'^cmd(\+|\-)').hasMatch(command) ||
          RegExp(r'^win(\+|\-)').hasMatch(command)) {
        isMetaPressed = true;
        command = command.substring(4); // 4 = 'win '.length
        matchedModifier = true;
      }
    } while (matchedModifier);

    return Keybinding(
      isAltPressed: isAltPressed,
      isControlPressed: isControlPressed,
      isMetaPressed: isMetaPressed,
      isShiftPressed: isShiftPressed,
      keyLabel: command,
    );
  }

  final bool isAltPressed;
  final bool isControlPressed;
  final bool isMetaPressed;
  final bool isShiftPressed;
  final String keyLabel;

  int get keyCode => keyToCodeMapping[keyLabel.toLowerCase()]!;

  Keybinding copyWith({
    bool? isAltPressed,
    bool? isControlPressed,
    bool? isMetaPressed,
    bool? isShiftPressed,
    String? keyLabel,
  }) {
    return Keybinding(
      isAltPressed: isAltPressed ?? this.isAltPressed,
      isControlPressed: isControlPressed ?? this.isControlPressed,
      isMetaPressed: isMetaPressed ?? this.isMetaPressed,
      isShiftPressed: isShiftPressed ?? this.isShiftPressed,
      keyLabel: keyLabel ?? this.keyLabel,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isAltPressed': isAltPressed,
      'isControlPressed': isControlPressed,
      'isMetaPressed': isMetaPressed,
      'isShiftPressed': isShiftPressed,
      'keyLabel': keyLabel,
    };
  }

  factory Keybinding.fromMap(Map<String, dynamic> map) {
    return Keybinding(
      isAltPressed: map['isAltPressed'] ?? false,
      isControlPressed: map['isControlPressed'] ?? false,
      isMetaPressed: map['isMetaPressed'] ?? false,
      isShiftPressed: map['isShiftPressed'] ?? false,
      keyLabel: map['keyLabel'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Keybinding.fromJson(String source) =>
      Keybinding.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Keybinding(isAltPressed: $isAltPressed, isControlPressed: $isControlPressed, isMetaPressed: $isMetaPressed, isShiftPressed: $isShiftPressed, keyLabel: $keyLabel)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Keybinding &&
        other.isAltPressed == isAltPressed &&
        other.isControlPressed == isControlPressed &&
        other.isMetaPressed == isMetaPressed &&
        other.isShiftPressed == isShiftPressed &&
        other.keyCode == keyCode;
  }

  @override
  int get hashCode {
    return isAltPressed.hashCode ^
        isControlPressed.hashCode ^
        isMetaPressed.hashCode ^
        isShiftPressed.hashCode ^
        keyCode;
  }
}
