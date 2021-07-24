import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/* --------------------------------- Typedef -------------------------------- */

enum InputShortcut {
  CUT,
  COPY,
  PASTE,
  SELECT_ALL,
  SAVE,
}

typedef CursorMoveCallback = void Function(
  LogicalKeyboardKey key,
  bool wordModifier,
  bool lineModifier,
  bool shift,
);

typedef InputShortcutCallback = void Function(
  InputShortcut? shortcut,
);

typedef OnDeleteCallback = void Function(
  bool forward,
);

/* -------------------------------- Listener -------------------------------- */

class KeyboardListener {
  KeyboardListener(this.onCursorMove, this.onShortcut, this.onDelete);

  final CursorMoveCallback onCursorMove;
  final InputShortcutCallback onShortcut;
  final OnDeleteCallback onDelete;

  static final Set<LogicalKeyboardKey> _moveKeys = {
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
  };

  static final Set<LogicalKeyboardKey> _shortcutKeys = {
    LogicalKeyboardKey.keyA,
    LogicalKeyboardKey.keyC,
    LogicalKeyboardKey.keyV,
    LogicalKeyboardKey.keyX,
    LogicalKeyboardKey.keyS,
    LogicalKeyboardKey.delete,
    LogicalKeyboardKey.backspace,
  };

  static final Set<LogicalKeyboardKey> _nonModifierKeys = {
    ..._moveKeys,
    ..._shortcutKeys,
  };

  static final Set<LogicalKeyboardKey> _winModifierKeys = {
    LogicalKeyboardKey.control,
    LogicalKeyboardKey.alt,
    LogicalKeyboardKey.shift,
  };

  static final Set<LogicalKeyboardKey> _osxModifierKeys = {
    LogicalKeyboardKey.meta,
    LogicalKeyboardKey.alt,
    LogicalKeyboardKey.shift,
  };

  static final Set<LogicalKeyboardKey> _interestingKeys = {
    ..._winModifierKeys,
    ..._osxModifierKeys,
    ..._nonModifierKeys,
  };

  static final Map<LogicalKeyboardKey, InputShortcut> _keyToShortcut = {
    LogicalKeyboardKey.keyX: InputShortcut.CUT,
    LogicalKeyboardKey.keyC: InputShortcut.COPY,
    LogicalKeyboardKey.keyV: InputShortcut.PASTE,
    LogicalKeyboardKey.keyA: InputShortcut.SELECT_ALL,
    LogicalKeyboardKey.keyS: InputShortcut.SAVE,
  };

  bool handleRawKeyEvent(RawKeyEvent event) {
    if (kIsWeb) {
      // On web platform, we should ignore the key because it's processed already.
      return false;
    }
    if (event is! RawKeyDownEvent) {
      return false;
    }

    final keysPressed = LogicalKeyboardKey.collapseSynonyms(RawKeyboard.instance.keysPressed);
    final key = event.logicalKey;
    final isMacOS = event.data is RawKeyEventDataMacOs;
    final modifierKeys = isMacOS ? _osxModifierKeys : _winModifierKeys;
    // If any one of below cases is hitten:
    // 1. None of the nonModifierKeys is pressed
    // 2. Press the key except the keys that trigger shortcut
    // We will skip this event
    if (!_nonModifierKeys.contains(key) ||
        keysPressed.difference(modifierKeys).length > 1 ||
        keysPressed.difference(_interestingKeys).isNotEmpty) {
      return false;
    }

    if (_isCursorMoveAction(key)) {
      onCursorMove(
        key,
        isMacOS ? event.isAltPressed : event.isControlPressed,
        isMacOS ? event.isMetaPressed : event.isAltPressed,
        event.isShiftPressed,
      );
      return true;
    } else if (_isShortcutAction(event, key)) {
      onShortcut(_keyToShortcut[key]);
      return true;
    } else if (LogicalKeyboardKey.delete == key) {
      onDelete(true);
      return true;
    } else if (LogicalKeyboardKey.backspace == key) {
      onDelete(false);
      return true;
    }
    return false;
  }

  // Helper

  bool _isCursorMoveAction(LogicalKeyboardKey key) => _moveKeys.contains(key);

  bool _isShortcutAction(RawKeyEvent event, LogicalKeyboardKey key) {
    if (!_shortcutKeys.contains(key)) {
      return false;
    }

    if (event.data is RawKeyEventDataMacOs) {
      return event.isMetaPressed;
    } else {
      return event.isControlPressed;
    }
  }
}
