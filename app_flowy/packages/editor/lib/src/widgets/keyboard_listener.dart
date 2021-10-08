import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

//fixme workaround flutter MacOS issue https://github.com/flutter/flutter/issues/75595
extension _LogicalKeyboardKeyCaseExt on LogicalKeyboardKey {
  static const _kUpperToLowerDist = 0x20;
  static final _kLowerCaseA = LogicalKeyboardKey.keyA.keyId;
  static final _kLowerCaseZ = LogicalKeyboardKey.keyZ.keyId;

  LogicalKeyboardKey toUpperCase() {
    if (keyId < _kLowerCaseA || keyId > _kLowerCaseZ) return this;
    return LogicalKeyboardKey(keyId - _kUpperToLowerDist);
  }
}

enum InputShortcut { CUT, COPY, PASTE, SELECT_ALL, UNDO, REDO }

typedef CursorMoveCallback = void Function(
    LogicalKeyboardKey key, bool wordModifier, bool lineModifier, bool shift);
typedef InputShortcutCallback = void Function(InputShortcut? shortcut);
typedef OnDeleteCallback = void Function(bool forward);

class KeyboardEventHandler {
  KeyboardEventHandler(this.onCursorMove, this.onShortcut, this.onDelete);

  final CursorMoveCallback onCursorMove;
  final InputShortcutCallback onShortcut;
  final OnDeleteCallback onDelete;

  static final Set<LogicalKeyboardKey> _moveKeys = <LogicalKeyboardKey>{
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
  };

  static final Set<LogicalKeyboardKey> _shortcutKeys = <LogicalKeyboardKey>{
    LogicalKeyboardKey.keyA,
    LogicalKeyboardKey.keyC,
    LogicalKeyboardKey.keyV,
    LogicalKeyboardKey.keyX,
    LogicalKeyboardKey.keyZ.toUpperCase(),
    LogicalKeyboardKey.keyZ,
    LogicalKeyboardKey.delete,
    LogicalKeyboardKey.backspace,
  };

  static final Set<LogicalKeyboardKey> _nonModifierKeys = <LogicalKeyboardKey>{
    ..._shortcutKeys,
    ..._moveKeys,
  };

  static final Set<LogicalKeyboardKey> _modifierKeys = <LogicalKeyboardKey>{
    LogicalKeyboardKey.shift,
    LogicalKeyboardKey.control,
    LogicalKeyboardKey.alt,
  };

  static final Set<LogicalKeyboardKey> _macOsModifierKeys =
      <LogicalKeyboardKey>{
    LogicalKeyboardKey.shift,
    LogicalKeyboardKey.meta,
    LogicalKeyboardKey.alt,
  };

  static final Set<LogicalKeyboardKey> _interestingKeys = <LogicalKeyboardKey>{
    ..._modifierKeys,
    ..._macOsModifierKeys,
    ..._nonModifierKeys,
  };

  static final Map<LogicalKeyboardKey, InputShortcut> _keyToShortcut = {
    LogicalKeyboardKey.keyX: InputShortcut.CUT,
    LogicalKeyboardKey.keyC: InputShortcut.COPY,
    LogicalKeyboardKey.keyV: InputShortcut.PASTE,
    LogicalKeyboardKey.keyA: InputShortcut.SELECT_ALL,
  };

  KeyEventResult handleRawKeyEvent(RawKeyEvent event) {
    if (kIsWeb) {
      // On web platform, we ignore the key because it's already processed.
      return KeyEventResult.ignored;
    }

    if (event is! RawKeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final keysPressed =
        LogicalKeyboardKey.collapseSynonyms(RawKeyboard.instance.keysPressed);
    final key = event.logicalKey;
    final isMacOS = event.data is RawKeyEventDataMacOs;
    if (!_nonModifierKeys.contains(key) ||
        keysPressed
                .difference(isMacOS ? _macOsModifierKeys : _modifierKeys)
                .length >
            1 ||
        keysPressed.difference(_interestingKeys).isNotEmpty) {
      return KeyEventResult.ignored;
    }

    final isShortcutModifierPressed =
        isMacOS ? event.isMetaPressed : event.isControlPressed;

    if (_moveKeys.contains(key)) {
      onCursorMove(
          key,
          isMacOS ? event.isAltPressed : event.isControlPressed,
          isMacOS ? event.isMetaPressed : event.isAltPressed,
          event.isShiftPressed);
    } else if (isShortcutModifierPressed && (_shortcutKeys.contains(key))) {
      if (key == LogicalKeyboardKey.keyZ ||
          key == LogicalKeyboardKey.keyZ.toUpperCase()) {
        onShortcut(
            event.isShiftPressed ? InputShortcut.REDO : InputShortcut.UNDO);
      } else {
        onShortcut(_keyToShortcut[key]);
      }
    } else if (key == LogicalKeyboardKey.delete) {
      onDelete(true);
    } else if (key == LogicalKeyboardKey.backspace) {
      onDelete(false);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }
}
