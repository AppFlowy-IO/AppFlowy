import 'package:appflowy/plugins/base/emoji/emoji_picker_header.dart';
import 'package:appflowy/plugins/base/emoji/emoji_search_bar.dart';
import 'package:appflowy/plugins/base/emoji/emoji_skin_tone.dart';
import 'package:emoji_mart/emoji_mart.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

// use a global value to store the selected emoji to prevent reloading every time.
EmojiData? _cachedEmojiData;

class FlowyEmojiPicker extends StatefulWidget {
  const FlowyEmojiPicker({
    super.key,
    required this.onEmojiSelected,
  });

  final EmojiSelectedCallback onEmojiSelected;

  @override
  State<FlowyEmojiPicker> createState() => _FlowyEmojiPickerState();
}

class _FlowyEmojiPickerState extends State<FlowyEmojiPicker> {
  EmojiData? emojiData;

  @override
  void initState() {
    super.initState();

    // load the emoji data from cache if it's available
    if (_cachedEmojiData != null) {
      emojiData = _cachedEmojiData;
    } else {
      EmojiData.builtIn().then(
        (value) {
          _cachedEmojiData = value;
          setState(() {
            emojiData = value;
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (emojiData == null) {
      return const Center(
        child: SizedBox.square(
          dimension: 24.0,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
          ),
        ),
      );
    }

    return EmojiPicker(
      emojiData: emojiData!,
      configuration: EmojiPickerConfiguration(
        showSectionHeader: true,
        showTabs: false,
        defaultSkinTone: lastSelectedEmojiSkinTone ?? EmojiSkinTone.none,
      ),
      onEmojiSelected: widget.onEmojiSelected,
      headerBuilder: (context, category) {
        return FlowyEmojiHeader(
          category: category,
        );
      },
      itemBuilder: (context, emojiId, emoji, callback) {
        return FlowyIconButton(
          iconPadding: const EdgeInsets.all(2.0),
          icon: FlowyText(
            emoji,
            fontSize: 28.0,
          ),
          onPressed: () => callback(emojiId, emoji),
        );
      },
      searchBarBuilder: (context, keyword, skinTone) {
        return FlowyEmojiSearchBar(
          emojiData: emojiData!,
          onKeywordChanged: (value) {
            keyword.value = value;
          },
          onSkinToneChanged: (value) {
            skinTone.value = value;
          },
          onRandomEmojiSelected: widget.onEmojiSelected,
        );
      },
    );
  }
}
