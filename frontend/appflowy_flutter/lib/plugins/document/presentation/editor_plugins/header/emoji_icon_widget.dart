import 'package:appflowy/plugins/base/emoji/emoji_text.dart';
import 'package:flutter/material.dart';

class EmojiIconWidget extends StatefulWidget {
  const EmojiIconWidget({
    super.key,
    required this.emoji,
    this.emojiSize = 60,
  });

  final String emoji;
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
              ? Theme.of(context).colorScheme.inverseSurface.withOpacity(0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: EmojiText(
          emoji: widget.emoji,
          fontSize: widget.emojiSize,
          textAlign: TextAlign.center,
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
