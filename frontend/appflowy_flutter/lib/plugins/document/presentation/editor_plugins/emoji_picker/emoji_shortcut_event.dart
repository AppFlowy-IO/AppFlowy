import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

import 'emoji_menu_item.dart';

CommandShortcutEvent showEmojiPickerEvent(BuildContext context) =>
    CommandShortcutEvent(
      key: 'Show emoji picker',
      command: 'ctrl+alt+e',
      macOSCommand: 'cmd+alt+e',
      handler: (state) =>
          _showEmojiSelectionMenuShortcut(Overlay.of(context), state, context),
    );

KeyEventResult _showEmojiSelectionMenuShortcut(
  OverlayState container,
  EditorState editorState,
  BuildContext context,
) {
  const menuHeight = 200.0;
  final selectionService = editorState.service.selectionService;
  final selectionRects = selectionService.selectionRects;
  const menuOffset = Offset(0, 10);
  final editorOffset =
      editorState.renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
  final editorHeight = editorState.renderBox!.size.height;

  // show below default
  var showBelow = true;
  var alignment = Alignment.bottomLeft;
  final bottomRight = selectionRects.first.bottomRight;
  final topRight = selectionRects.first.topRight;
  var offset = bottomRight + menuOffset;
  // overflow
  if (offset.dy + menuHeight >= editorOffset.dy + editorHeight) {
    // show above
    offset = topRight - menuOffset;
    showBelow = false;
    alignment = Alignment.topLeft;
  }
  offset = Offset(
    offset.dx,
    showBelow ? offset.dy : MediaQuery.of(context).size.height - offset.dy,
  );
  final top = alignment == Alignment.bottomLeft ? offset.dy : null;
  final bottom = alignment == Alignment.topLeft ? offset.dy : null;

  final emojiPickerMenuEntry = FullScreenOverlayEntry(
    top: top,
    bottom: bottom,
    left: offset.dx,
    builder: (context) => Material(
      child: Container(
        width: 300,
        height: 250,
        padding: const EdgeInsets.all(4.0),
        child: EmojiSelectionMenu(
          onSubmitted: (emoji) {
            editorState.insertTextAtCurrentSelection(emoji.emoji);
          },
        ),
      ),
    ),
  ).build();
  container.insert(emojiPickerMenuEntry);
  return KeyEventResult.handled;
}
