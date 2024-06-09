import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/emoji_shortcut/emoji_shortcut_builder.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/src/emji_picker_config.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/src/emoji_picker.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';

CharacterShortcutEvent emojiShortcutCommand(
  BuildContext context, {
  String character = ':',
}) {
  final container = Overlay.of(context);

  final style = Theme.of(context);

  late OverlayEntry overlayEntry;

  return CharacterShortcutEvent(
    key: 'show emoji selection menu',
    character: character,
    handler: (editorState) async {
      final selectionRects =
          editorState.service.selectionService.selectionRects;
      if (selectionRects.isEmpty) return false;

      // Cursor position
      final cursor = selectionRects.first;

      // Estimate the location where to display the emoji picker menu
      final editorOffset =
          editorState.renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;

      // Determine if emoji menu will overflow on right side of editor
      final bool dxOverflow = cursor.bottomLeft.dx + menuWidth >
          editorState.renderBox!.size.width + editorOffset.dx;

      // By default, display the menu under the cursor
      var dy = cursor.bottomLeft.dy + menuOffset.dy;

      // Determine if emoji menu wil overflow when placed below the cursor
      if (menuHeight + dy >=
          editorState.renderBox!.size.height + editorOffset.dy) {
        // If not, display the menu above the cursor
        dy = cursor.topLeft.dy - menuOffset.dy - menuHeight;
      }

      await editorState.insertTextAtCurrentSelection(character);

      keepEditorFocusNotifier.increase();

      overlayEntry = FullScreenOverlayEntry(
        top: dy,
        right: dxOverflow ? 0 : null,
        left: dxOverflow ? null : cursor.bottomLeft.dx,
        dismissCallback: () {
          overlayEntry.remove();
          keepEditorFocusNotifier.decrease();
        },
        builder: (context) => Material(
          borderRadius: Corners.s8Border,
          elevation: 1,
          child: Align(
            child: Container(
              width: menuWidth,
              height: menuHeight,
              padding: const EdgeInsets.all(4.0),
              child: EmojiPicker(
                config: EmojiPickerConfig(
                  emojiNumberPerRow: emojiNumberPerRow,
                  emojiSizeMax: emojiSizeMax,
                  bgColor: Colors.transparent,
                  buttonMode: ButtonMode.CUPERTINO,
                  progressIndicatorColor: style.colorScheme.primary,
                  noRecentsText: LocaleKeys.emoji_noRecent.tr(),
                  noRecentsStyle: style.textTheme.bodyMedium,
                  noEmojiFoundText: LocaleKeys.emoji_noEmojiFound.tr(),
                ),
                customWidget: (config, state) => EmojiShortcutPickerView(
                  config,
                  state,
                  editorState,
                  character,
                  overlayEntry.remove,
                ),
                onEmojiSelected: (_, emoji) async {},
              ),
            ),
          ),
        ),
      ).build();
      container.insert(overlayEntry);
      return true;
    },
  );
}
