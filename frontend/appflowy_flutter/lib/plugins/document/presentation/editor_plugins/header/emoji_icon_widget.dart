import 'dart:convert';
import 'dart:io';

import 'package:appflowy/plugins/base/emoji/emoji_text.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_picker.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import '../../../../base/icon/icon_widget.dart';

class EmojiIconWidget extends StatefulWidget {
  const EmojiIconWidget({
    super.key,
    required this.emoji,
    this.emojiSize = 60,
  });

  final EmojiIconData emoji;
  final double emojiSize;

  @override
  State<EmojiIconWidget> createState() => _EmojiIconWidgetState();
}

class _EmojiIconWidgetState extends State<EmojiIconWidget> {
  bool hover = true;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setHidden(false),
      onExit: (_) => setHidden(true),
      cursor: SystemMouseCursors.click,
      child: Container(
        decoration: BoxDecoration(
          color: !hover
              ? Theme.of(context)
                  .colorScheme
                  .inverseSurface
                  .withValues(alpha: 0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: RawEmojiIconWidget(
          emoji: widget.emoji,
          emojiSize: widget.emojiSize,
        ),
      ),
    );
  }

  void setHidden(bool value) {
    if (hover == value) return;
    setState(() {
      hover = value;
    });
  }
}

class RawEmojiIconWidget extends StatelessWidget {
  const RawEmojiIconWidget({
    super.key,
    required this.emoji,
    required this.emojiSize,
  });

  final EmojiIconData emoji;
  final double emojiSize;

  @override
  Widget build(BuildContext context) {
    final defaultEmoji = SizedBox(
      width: emojiSize,
      child: EmojiText(
        emoji: '❓',
        fontSize: emojiSize,
        textAlign: TextAlign.center,
      ),
    );
    try {
      switch (emoji.type) {
        case FlowyIconType.emoji:
          return EmojiText(
            emoji: emoji.emoji,
            fontSize: emojiSize,
            textAlign: TextAlign.center,
          );
        case FlowyIconType.icon:
          final iconData = IconsData.fromJson(jsonDecode(emoji.emoji));

          /// Under the same width conditions, icons on macOS seem to appear
          /// larger than emojis, so 0.9 is used here to slightly reduce the
          /// size of the icons
          final iconSize = Platform.isMacOS ? emojiSize * 0.9 : emojiSize;
          return IconWidget(
            iconsData: iconData,
            size: iconSize,
          );
        default:
          return defaultEmoji;
      }
    } catch (e) {
      Log.error("Display widget error: $e");
      return defaultEmoji;
    }
  }
}
