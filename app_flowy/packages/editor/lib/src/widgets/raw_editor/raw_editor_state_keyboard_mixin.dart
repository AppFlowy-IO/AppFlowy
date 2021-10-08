import 'dart:ui';

import 'package:characters/characters.dart';
import 'package:flutter/services.dart';

import '../../models/documents/document.dart';
import '../../utils/diff_delta.dart';
import '../editor.dart';
import '../keyboard_listener.dart';

mixin RawEditorStateKeyboardMixin on EditorState {
  // Holds the last cursor location the user selected in the case the user tries
  // to select vertically past the end or beginning of the field. If they do,
  // then we need to keep the old cursor location so that we can go back to it
  // if they change their minds. Only used for moving selection up and down in a
  // multiline text field when selecting using the keyboard.
  int _cursorResetLocation = -1;

  // Whether we should reset the location of the cursor in the case the user
  // tries to select vertically past the end or beginning of the field. If they
  // do, then we need to keep the old cursor location so that we can go back to
  // it if they change their minds. Only used for resetting selection up and
  // down in a multiline text field when selecting using the keyboard.
  bool _wasSelectingVerticallyWithKeyboard = false;

  void handleCursorMovement(
    LogicalKeyboardKey key,
    bool wordModifier,
    bool lineModifier,
    bool shift,
  ) {
    if (wordModifier && lineModifier) {
      // If both modifiers are down, nothing happens on any of the platforms.
      return;
    }
    final selection = widget.controller.selection;

    var newSelection = widget.controller.selection;

    final plainText = getTextEditingValue().text;

    final rightKey = key == LogicalKeyboardKey.arrowRight,
        leftKey = key == LogicalKeyboardKey.arrowLeft,
        upKey = key == LogicalKeyboardKey.arrowUp,
        downKey = key == LogicalKeyboardKey.arrowDown;

    if ((rightKey || leftKey) && !(rightKey && leftKey)) {
      newSelection = _jumpToBeginOrEndOfWord(newSelection, wordModifier,
          leftKey, rightKey, plainText, lineModifier, shift);
    }

    if (downKey || upKey) {
      newSelection = _handleMovingCursorVertically(
          upKey, downKey, shift, selection, newSelection, plainText);
    }

    if (!shift) {
      newSelection =
          _placeCollapsedSelection(selection, newSelection, leftKey, rightKey);
    }

    widget.controller.updateSelection(newSelection, ChangeSource.LOCAL);
  }

  // Handles shortcut functionality including cut, copy, paste and select all
  // using control/command + (X, C, V, A).
  // TODO: Add support for formatting shortcuts: Cmd+B (bold), Cmd+I (italic)
  // set editing value from clipboard for web
  Future<void> handleShortcut(InputShortcut? shortcut) async {
    final selection = widget.controller.selection;
    final plainText = getTextEditingValue().text;
    if (shortcut == InputShortcut.COPY) {
      if (!selection.isCollapsed) {
        await Clipboard.setData(
            ClipboardData(text: selection.textInside(plainText)));
      }
      return;
    }
    if (shortcut == InputShortcut.UNDO) {
      if (widget.controller.hasUndo) {
        widget.controller.undo();
      }
      return;
    }
    if (shortcut == InputShortcut.REDO) {
      if (widget.controller.hasRedo) {
        widget.controller.redo();
      }
      return;
    }
    if (shortcut == InputShortcut.CUT && !widget.readOnly) {
      if (!selection.isCollapsed) {
        final data = selection.textInside(plainText);
        await Clipboard.setData(ClipboardData(text: data));

        widget.controller.replaceText(
          selection.start,
          data.length,
          '',
          TextSelection.collapsed(offset: selection.start),
        );

        setTextEditingValue(TextEditingValue(
          text:
              selection.textBefore(plainText) + selection.textAfter(plainText),
          selection: TextSelection.collapsed(offset: selection.start),
        ));
      }
      return;
    }
    if (shortcut == InputShortcut.PASTE && !widget.readOnly) {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null) {
        widget.controller.replaceText(
          selection.start,
          selection.end - selection.start,
          data.text,
          TextSelection.collapsed(offset: selection.start + data.text!.length),
        );
      }
      return;
    }
    if (shortcut == InputShortcut.SELECT_ALL &&
        widget.enableInteractiveSelection) {
      widget.controller.updateSelection(
          selection.copyWith(
            baseOffset: 0,
            extentOffset: getTextEditingValue().text.length,
          ),
          ChangeSource.REMOTE);
      return;
    }
  }

  void handleDelete(bool forward) {
    final selection = widget.controller.selection;
    final plainText = getTextEditingValue().text;
    var cursorPosition = selection.start;
    var textBefore = selection.textBefore(plainText);
    var textAfter = selection.textAfter(plainText);
    if (selection.isCollapsed) {
      if (!forward && textBefore.isNotEmpty) {
        final characterBoundary =
            _previousCharacter(textBefore.length, textBefore, true);
        textBefore = textBefore.substring(0, characterBoundary);
        cursorPosition = characterBoundary;
      }
      if (forward && textAfter.isNotEmpty && textAfter != '\n') {
        final deleteCount = _nextCharacter(0, textAfter, true);
        textAfter = textAfter.substring(deleteCount);
      }
    }
    final newSelection = TextSelection.collapsed(offset: cursorPosition);
    final newText = textBefore + textAfter;
    final size = plainText.length - newText.length;
    widget.controller.replaceText(
      cursorPosition,
      size,
      '',
      newSelection,
    );
  }

  TextSelection _jumpToBeginOrEndOfWord(
      TextSelection newSelection,
      bool wordModifier,
      bool leftKey,
      bool rightKey,
      String plainText,
      bool lineModifier,
      bool shift) {
    if (wordModifier) {
      if (leftKey) {
        final textSelection = getRenderEditor()!.selectWordAtPosition(
            TextPosition(
                offset: _previousCharacter(
                    newSelection.extentOffset, plainText, false)));
        return newSelection.copyWith(extentOffset: textSelection.baseOffset);
      }
      final textSelection = getRenderEditor()!.selectWordAtPosition(
          TextPosition(
              offset:
                  _nextCharacter(newSelection.extentOffset, plainText, false)));
      return newSelection.copyWith(extentOffset: textSelection.extentOffset);
    } else if (lineModifier) {
      if (leftKey) {
        final textSelection = getRenderEditor()!.selectLineAtPosition(
            TextPosition(
                offset: _previousCharacter(
                    newSelection.extentOffset, plainText, false)));
        return newSelection.copyWith(extentOffset: textSelection.baseOffset);
      }
      final startPoint = newSelection.extentOffset;
      if (startPoint < plainText.length) {
        final textSelection = getRenderEditor()!
            .selectLineAtPosition(TextPosition(offset: startPoint));
        return newSelection.copyWith(extentOffset: textSelection.extentOffset);
      }
      return newSelection;
    }

    if (rightKey && newSelection.extentOffset < plainText.length) {
      final nextExtent =
          _nextCharacter(newSelection.extentOffset, plainText, true);
      final distance = nextExtent - newSelection.extentOffset;
      newSelection = newSelection.copyWith(extentOffset: nextExtent);
      if (shift) {
        _cursorResetLocation += distance;
      }
      return newSelection;
    }

    if (leftKey && newSelection.extentOffset > 0) {
      final previousExtent =
          _previousCharacter(newSelection.extentOffset, plainText, true);
      final distance = newSelection.extentOffset - previousExtent;
      newSelection = newSelection.copyWith(extentOffset: previousExtent);
      if (shift) {
        _cursorResetLocation -= distance;
      }
      return newSelection;
    }
    return newSelection;
  }

  /// Returns the index into the string of the next character boundary after the
  /// given index.
  ///
  /// The character boundary is determined by the characters package, so
  /// surrogate pairs and extended grapheme clusters are considered.
  ///
  /// The index must be between 0 and string.length, inclusive. If given
  /// string.length, string.length is returned.
  ///
  /// Setting includeWhitespace to false will only return the index of non-space
  /// characters.
  int _nextCharacter(int index, String string, bool includeWhitespace) {
    assert(index >= 0 && index <= string.length);
    if (index == string.length) {
      return string.length;
    }

    var count = 0;
    final remain = string.characters.skipWhile((currentString) {
      if (count <= index) {
        count += currentString.length;
        return true;
      }
      if (includeWhitespace) {
        return false;
      }
      return WHITE_SPACE.contains(currentString.codeUnitAt(0));
    });
    return string.length - remain.toString().length;
  }

  /// Returns the index into the string of the previous character boundary
  /// before the given index.
  ///
  /// The character boundary is determined by the characters package, so
  /// surrogate pairs and extended grapheme clusters are considered.
  ///
  /// The index must be between 0 and string.length, inclusive. If index is 0,
  /// 0 will be returned.
  ///
  /// Setting includeWhitespace to false will only return the index of non-space
  /// characters.
  int _previousCharacter(int index, String string, includeWhitespace) {
    assert(index >= 0 && index <= string.length);
    if (index == 0) {
      return 0;
    }

    var count = 0;
    int? lastNonWhitespace;
    for (final currentString in string.characters) {
      if (!includeWhitespace &&
          !WHITE_SPACE.contains(
              currentString.characters.first.toString().codeUnitAt(0))) {
        lastNonWhitespace = count;
      }
      if (count + currentString.length >= index) {
        return includeWhitespace ? count : lastNonWhitespace ?? 0;
      }
      count += currentString.length;
    }
    return 0;
  }

  TextSelection _handleMovingCursorVertically(
      bool upKey,
      bool downKey,
      bool shift,
      TextSelection selection,
      TextSelection newSelection,
      String plainText) {
    final originPosition = TextPosition(
        offset: upKey ? selection.baseOffset : selection.extentOffset);

    final child = getRenderEditor()!.childAtPosition(originPosition);
    final localPosition = TextPosition(
        offset: originPosition.offset - child.getContainer().documentOffset);

    var position = upKey
        ? child.getPositionAbove(localPosition)
        : child.getPositionBelow(localPosition);

    if (position == null) {
      final sibling = upKey
          ? getRenderEditor()!.childBefore(child)
          : getRenderEditor()!.childAfter(child);
      if (sibling == null) {
        position = TextPosition(offset: upKey ? 0 : plainText.length - 1);
      } else {
        final finalOffset = Offset(
            child.getOffsetForCaret(localPosition).dx,
            sibling
                .getOffsetForCaret(TextPosition(
                    offset: upKey ? sibling.getContainer().length - 1 : 0))
                .dy);
        final siblingPosition = sibling.getPositionForOffset(finalOffset);
        position = TextPosition(
            offset:
                sibling.getContainer().documentOffset + siblingPosition.offset);
      }
    } else {
      position = TextPosition(
          offset: child.getContainer().documentOffset + position.offset);
    }

    if (position.offset == newSelection.extentOffset) {
      if (downKey) {
        newSelection = newSelection.copyWith(extentOffset: plainText.length);
      } else if (upKey) {
        newSelection = newSelection.copyWith(extentOffset: 0);
      }
      _wasSelectingVerticallyWithKeyboard = shift;
      return newSelection;
    }

    if (_wasSelectingVerticallyWithKeyboard && shift) {
      newSelection = newSelection.copyWith(extentOffset: _cursorResetLocation);
      _wasSelectingVerticallyWithKeyboard = false;
      return newSelection;
    }
    newSelection = newSelection.copyWith(extentOffset: position.offset);
    _cursorResetLocation = newSelection.extentOffset;
    return newSelection;
  }

  TextSelection _placeCollapsedSelection(TextSelection selection,
      TextSelection newSelection, bool leftKey, bool rightKey) {
    var newOffset = newSelection.extentOffset;
    if (!selection.isCollapsed) {
      if (leftKey) {
        newOffset = newSelection.baseOffset < newSelection.extentOffset
            ? newSelection.baseOffset
            : newSelection.extentOffset;
      } else if (rightKey) {
        newOffset = newSelection.baseOffset > newSelection.extentOffset
            ? newSelection.baseOffset
            : newSelection.extentOffset;
      }
    }
    return TextSelection.fromPosition(TextPosition(offset: newOffset));
  }
}
