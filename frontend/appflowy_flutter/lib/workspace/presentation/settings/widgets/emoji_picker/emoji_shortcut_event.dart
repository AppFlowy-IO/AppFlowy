import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/emoji_picker.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

final CommandShortcutEvent emojiShortcutEvent = CommandShortcutEvent(
  key: 'Ctrl + Alt + E to show emoji picker',
  command: 'ctrl+alt+e',
  macOSCommand: 'cmd+alt+e',
  getDescription: () => 'Show an emoji picker',
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

  Alignment alignment = Alignment.topLeft;
  Offset offset = Offset.zero;

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
  alignment = Alignment.topLeft;
  final bottomRight = rect.bottomRight;
  final topRight = rect.topRight;
  final newOffset = bottomRight + menuOffset;
  offset = Offset(
    newOffset.dx,
    newOffset.dy,
  );

  // show above
  if (newOffset.dy + menuHeight >= editorOffset.dy + editorHeight) {
    offset = topRight - menuOffset;
    alignment = Alignment.bottomLeft;

    offset = Offset(
      newOffset.dx,
      MediaQuery.of(context).size.height - newOffset.dy,
    );
  }

  // show on left
  if (offset.dx - editorOffset.dx > editorWidth / 2) {
    alignment = alignment == Alignment.topLeft
        ? Alignment.topRight
        : Alignment.bottomRight;

    offset = Offset(
      editorWidth - offset.dx + editorOffset.dx,
      offset.dy,
    );
  }

  showEmojiPickerMenu(
    container,
    editorState,
    alignment,
    offset,
  );

  return KeyEventResult.handled;
};
