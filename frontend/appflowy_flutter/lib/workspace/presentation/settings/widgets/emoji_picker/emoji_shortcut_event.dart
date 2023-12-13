import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/emoji_picker.dart';

final CommandShortcutEvent emojiShortcutEvent = CommandShortcutEvent(
  key: 'show emoji picker',
  command: 'ctrl+alt+e',
  macOSCommand: 'cmd+alt+e',
  handler: _emojiShortcutHandler,
);

CommandShortcutEventHandler _emojiShortcutHandler = (editorState) {
  final selection = editorState.selection;
  if (selection == null) {
    return KeyEventResult.ignored;
  }
  final context = editorState.getNodeAtPath(selection.start.path)?.context;
  if (context == null) {
    return KeyEventResult.ignored;
  }

  final container = Overlay.of(context);

  Alignment _alignment = Alignment.topLeft;
  Offset _offset = Offset.zero;

  final selectionService = editorState.service.selectionService;
  final selectionRects = selectionService.selectionRects;
  if (selectionRects.isEmpty) {
    return KeyEventResult.ignored;
  }
  final rect = selectionRects.first;

  // Calculate the offset and alignment
  // Don't like these values being hardcoded but unsure how to grab the
  // values dynamically to match the /emoji command.
  const menuHeight = 200.0;
  const menuOffset = Offset(10, 10); // Tried (0, 10) but that looked off

  final editorOffset =
      editorState.renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
  final editorHeight = editorState.renderBox!.size.height;
  final editorWidth = editorState.renderBox!.size.width;

  // show below default
  _alignment = Alignment.topLeft;
  final bottomRight = rect.bottomRight;
  final topRight = rect.topRight;
  var offset = bottomRight + menuOffset;
  _offset = Offset(
    offset.dx,
    offset.dy,
  );

  // show above
  if (offset.dy + menuHeight >= editorOffset.dy + editorHeight) {
    offset = topRight - menuOffset;
    _alignment = Alignment.bottomLeft;

    _offset = Offset(
      offset.dx,
      MediaQuery.of(context).size.height - offset.dy,
    );
  }

  // show on left
  if (_offset.dx - editorOffset.dx > editorWidth / 2) {
    _alignment = _alignment == Alignment.topLeft
        ? Alignment.topRight
        : Alignment.bottomRight;

    _offset = Offset(
      editorWidth - _offset.dx + editorOffset.dx,
      _offset.dy,
    );
  }

  showEmojiPickerMenu(
    container,
    editorState,
    _alignment,
    _offset,
  );

  return KeyEventResult.handled;
};
