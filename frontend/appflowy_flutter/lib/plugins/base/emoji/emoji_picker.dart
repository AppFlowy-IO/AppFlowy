import 'dart:math';

import 'package:appflowy/plugins/base/emoji/emoji_picker_header.dart';
import 'package:appflowy/shared/icon_emoji_picker/emoji_search_bar.dart';
import 'package:appflowy/shared/icon_emoji_picker/emoji_skin_tone.dart';
import 'package:appflowy/shared/icon_emoji_picker/recent_icons.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_emoji_mart/flutter_emoji_mart.dart';

// use a global value to store the selected emoji to prevent reloading every time.
EmojiData? kCachedEmojiData;
const _kRecentEmojiCategoryId = 'Recent';

class EmojiPickerResult {
  EmojiPickerResult({
    required this.emojiId,
    required this.emoji,
    this.isRandom = false,
  });

  final String emojiId;
  final String emoji;
  final bool isRandom;
}

class FlowyEmojiPicker extends StatefulWidget {
  const FlowyEmojiPicker({
    super.key,
    required this.onEmojiSelected,
    this.emojiPerLine = 9,
    this.ensureFocus = false,
  });

  final ValueChanged<EmojiPickerResult> onEmojiSelected;
  final int emojiPerLine;
  final bool ensureFocus;

  @override
  State<FlowyEmojiPicker> createState() => _FlowyEmojiPickerState();
}

class _FlowyEmojiPickerState extends State<FlowyEmojiPicker> {
  late EmojiData emojiData;
  bool loaded = false;

  @override
  void initState() {
    super.initState();

    // load the emoji data from cache if it's available
    if (kCachedEmojiData != null) {
      loadEmojis(kCachedEmojiData!);
    } else {
      EmojiData.builtIn().then(
        (value) {
          kCachedEmojiData = value;
          loadEmojis(value);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
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
      emojiData: emojiData,
      configuration: EmojiPickerConfiguration(
        showTabs: false,
        defaultSkinTone: lastSelectedEmojiSkinTone ?? EmojiSkinTone.none,
      ),
      onEmojiSelected: (id, emoji) {
        widget.onEmojiSelected.call(
          EmojiPickerResult(emojiId: id, emoji: emoji),
        );
        RecentIcons.putEmoji(id);
      },
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      headerBuilder: (_, category) => FlowyEmojiHeader(category: category),
      itemBuilder: (context, emojiId, emoji, callback) {
        final name = emojiData.emojis[emojiId]?.name ?? '';
        return SizedBox.square(
          dimension: 36.0,
          child: FlowyButton(
            margin: EdgeInsets.zero,
            radius: Corners.s8Border,
            text: FlowyTooltip(
              message: name,
              preferBelow: false,
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
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: FlowyEmojiSearchBar(
            emojiData: emojiData,
            ensureFocus: widget.ensureFocus,
            onKeywordChanged: (value) {
              keyword.value = value;
            },
            onSkinToneChanged: (value) {
              skinTone.value = value;
            },
            onRandomEmojiSelected: (id, emoji) {
              widget.onEmojiSelected.call(
                EmojiPickerResult(emojiId: id, emoji: emoji, isRandom: true),
              );
              RecentIcons.putEmoji(id);
            },
          ),
        );
      },
    );
  }

  void loadEmojis(EmojiData data) {
    RecentIcons.getEmojiIds().then((v) {
      if (v.isEmpty) {
        emojiData = data;
        if (mounted) setState(() => loaded = true);
        return;
      }
      final categories = List.of(data.categories);
      categories.insert(
        0,
        Category(
          id: _kRecentEmojiCategoryId,
          emojiIds: v.sublist(0, min(widget.emojiPerLine, v.length)),
        ),
      );
      emojiData = EmojiData(categories: categories, emojis: data.emojis);
      if (mounted) setState(() => loaded = true);
    });
  }
}
