import 'dart:convert';
import 'dart:io';

import 'package:appflowy/plugins/base/emoji/emoji_text.dart';
import 'package:appflowy/shared/appflowy_network_image.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_picker.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter/material.dart';
import 'package:string_validator/string_validator.dart';

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
              ? Theme.of(context).colorScheme.inverseSurface.withOpacity(0.5)
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
    this.enableColor = true,
  });

  final EmojiIconData emoji;
  final double emojiSize;
  final bool enableColor;

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
          return SizedBox(
            width: emojiSize,
            child: EmojiText(
              emoji: emoji.emoji,
              fontSize: emojiSize,
              textAlign: TextAlign.justify,
            ),
          );
        case FlowyIconType.icon:
          IconsData iconData = IconsData.fromJson(jsonDecode(emoji.emoji));
          if (!enableColor) {
            iconData = iconData.noColor();
          }

          /// Under the same width conditions, icons on macOS seem to appear
          /// larger than emojis, so 0.9 is used here to slightly reduce the
          /// size of the icons
          final iconSize = Platform.isMacOS ? emojiSize * 0.9 : emojiSize;
          return IconWidget(
            iconsData: iconData,
            size: iconSize,
          );
        case FlowyIconType.custom:
          final url = emoji.emoji;
          if (isURL(url)) {
            return SizedBox.square(
              dimension: emojiSize,
              child: FutureBuilder(
                future: UserBackendService.getCurrentUserProfile(),
                builder: (context, value) {
                  final userProfile = value.data?.fold(
                    (userProfile) => userProfile,
                    (l) => null,
                  );
                  if (userProfile == null) return const SizedBox.shrink();
                  return FlowyNetworkImage(
                    url: url,
                    width: emojiSize,
                    height: emojiSize,
                    userProfilePB: userProfile,
                    errorWidgetBuilder: (context, url, error) =>
                        const SizedBox.shrink(),
                  );
                },
              ),
            );
          }
          final imageFile = File(url);
          if (!imageFile.existsSync()) {
            throw PathNotFoundException(url, const OSError());
          }
          return SizedBox.square(
            dimension: emojiSize,
            child: Image.file(
              imageFile,
              fit: BoxFit.cover,
              width: emojiSize,
              height: emojiSize,
            ),
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
