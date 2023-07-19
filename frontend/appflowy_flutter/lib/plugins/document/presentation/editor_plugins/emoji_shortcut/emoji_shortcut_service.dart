import 'package:appflowy/plugins/document/presentation/editor_plugins/emoji_picker/src/config.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/emoji_picker/src/emoji_picker.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/emoji_shortcut/emoji_picker_builder.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';

class EmojiShortcutService {
  Alignment _alignment = Alignment.topLeft;

  customEmojiMenuLink(
    BuildContext context, {
    bool shouldInsertKeyword = true,
    String character = ':',
  }) {
    return CharacterShortcutEvent(
      key: 'show emoji selection menu',
      character: character,
      handler: (editorState) async {
        final container = Overlay.of(context);
        showEmojiPickerMenu(
          container,
          editorState,
          context,
          shouldInsertKeyword,
        );
        return true;
      },
    );
  }

  void showEmojiPickerMenu(
    OverlayState container,
    EditorState editorState,
    BuildContext context,
    bool shouldInsertCharacter,
  ) async {
    final selectionService = editorState.service.selectionService;
    final selectionRects = selectionService.selectionRects;
    if (selectionRects.isEmpty) {
      return;
    }

    if (shouldInsertCharacter) {
      if (foundation.kIsWeb) {
        // Have no idea why the focus will lose after inserting on web.
        keepEditorFocusNotifier.value += 1;
        await editorState.insertTextAtPosition(
          ':',
          position: editorState.selection!.start,
        );
        WidgetsBinding.instance.addPostFrameCallback(
          (timeStamp) => keepEditorFocusNotifier.value -= 1,
        );
      } else {
        await editorState.insertTextAtPosition(
          ':',
          position: editorState.selection!.start,
        );
      }
    }
    // Workaround: We can customize the padding through the [EditorStyle],
    //  but the coordinates of overlay are not properly converted currently.
    //  Just subtract the padding here as a result.
    const menuHeight = 200.0;
    const menuOffset = Offset(0, 10);
    final editorOffset =
        editorState.renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final editorHeight = editorState.renderBox!.size.height;

    // show below default
    _alignment = Alignment.bottomLeft;
    final bottomRight = selectionRects.first.bottomRight;
    final topRight = selectionRects.first.topRight;
    var offset = bottomRight + menuOffset;
    // overflow
    if (offset.dy + menuHeight >= editorOffset.dy + editorHeight) {
      // show above
      offset = topRight - menuOffset;
      _alignment = Alignment.topLeft;
    }

    final alignment = _alignment;
    offset = offset;
    final top = alignment == Alignment.bottomLeft ? offset.dy : null;
    final bottom = alignment == Alignment.topLeft ? offset.dy : null;

    keepEditorFocusNotifier.value += 1;
    const Config config = Config(
      columns: 7,
      emojiSizeMax: 28,
      bgColor: Colors.transparent,
      iconColor: Colors.grey,
      iconColorSelected: Color(0xff333333),
      indicatorColor: Color(0xff333333),
      progressIndicatorColor: Color(0xff333333),
      buttonMode: ButtonMode.CUPERTINO,
      initCategory: Category.RECENT,
    );
    late OverlayEntry emojiPickerMenuEntry;
    emojiPickerMenuEntry = FullScreenOverlayEntry(
      top: top,
      bottom: bottom,
      left: offset.dx,
      dismissCallback: () => keepEditorFocusNotifier.value -= 1,
      builder: (context) => Material(
        child: Container(
          width: 300,
          height: 250,
          padding: const EdgeInsets.all(4.0),
          child: EmojiPicker(
            onEmojiSelected: (category, emoji) {
              editorState.insertTextAtCurrentSelection(emoji.emoji);
            },
            config: config,
            customWidget: (config, state) {
              return ShortcutEmojiPickerView(config, state, editorState, () {
                emojiPickerMenuEntry.remove();
              });
            },
          ),
        ),
      ),
    ).build();
    container.insert(emojiPickerMenuEntry);
  }
}
