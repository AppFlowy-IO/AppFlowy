import 'package:appflowy/plugins/base/emoji/emoji_picker_header.dart';
import 'package:appflowy/plugins/base/emoji/emoji_search_bar.dart';
import 'package:appflowy/plugins/base/emoji/emoji_skin_tone.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_emoji_mart/flutter_emoji_mart.dart';

// use a global value to store the selected emoji to prevent reloading every time.
EmojiData? kCachedEmojiData;

class FlowyEmojiPicker extends StatefulWidget {
  const FlowyEmojiPicker({
    super.key,
    required this.onEmojiSelected,
    this.emojiPerLine = 9,
  });

  final EmojiSelectedCallback onEmojiSelected;
  final int emojiPerLine;

  @override
  State<FlowyEmojiPicker> createState() => _FlowyEmojiPickerState();
}

class _FlowyEmojiPickerState extends State<FlowyEmojiPicker> {
  EmojiData? emojiData;

  @override
  void initState() {
    super.initState();

    // load the emoji data from cache if it's available
    if (kCachedEmojiData != null) {
      emojiData = kCachedEmojiData;
    } else {
      EmojiData.builtIn().then(
        (value) {
          kCachedEmojiData = value;
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
        showTabs: false,
        defaultSkinTone: lastSelectedEmojiSkinTone ?? EmojiSkinTone.none,
        perLine: widget.emojiPerLine,
      ),
      onEmojiSelected: widget.onEmojiSelected,
      headerBuilder: (context, category) {
        return FlowyEmojiHeader(
          category: category,
        );
      },
      itemBuilder: (context, emojiId, emoji, callback) {
        return SizedBox(
          width: 36,
          height: 36,
          child: FlowyButton(
            margin: const EdgeInsets.all(0.0),
            radius: Corners.s8Border,
            text: Padding(
              padding: const EdgeInsets.only(top: 6.0, left: 6.0),
              child: FlowyText.emoji(
                emoji,
                fontSize: 24.0,
              ),
            ),
            onTap: () => callback(emojiId, emoji),
          ),
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
