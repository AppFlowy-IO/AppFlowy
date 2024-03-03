import 'dart:io';

import 'package:appflowy/plugins/base/emoji/emoji_picker_header.dart';
import 'package:appflowy/plugins/base/emoji/emoji_search_bar.dart';
import 'package:appflowy/plugins/base/emoji/emoji_skin_tone.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_emoji_mart/flutter_emoji_mart.dart';
import 'package:google_fonts/google_fonts.dart';

// use a global value to store the selected emoji to prevent reloading every time.
EmojiData? _cachedEmojiData;

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
  List<String>? fallbackFontFamily;

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

    if (Platform.isAndroid || Platform.isLinux) {
      final notoColorEmoji = GoogleFonts.notoColorEmoji().fontFamily;
      if (notoColorEmoji != null) {
        fallbackFontFamily = [notoColorEmoji];
      }
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
        return FlowyIconButton(
          iconPadding: const EdgeInsets.all(2.0),
          icon: FlowyText(
            emoji,
            fontSize: 28.0,
            fallbackFontFamily: fallbackFontFamily,
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
