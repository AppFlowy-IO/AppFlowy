import 'dart:convert';
import 'dart:io';

import 'package:appflowy/plugins/base/emoji/emoji_text.dart';
import 'package:appflowy/shared/appflowy_network_image.dart';
import 'package:appflowy/shared/appflowy_network_svg.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_picker.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flowy_svg/flowy_svg.dart';
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

class RawEmojiIconWidget extends StatefulWidget {
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
  State<RawEmojiIconWidget> createState() => _RawEmojiIconWidgetState();
}

class _RawEmojiIconWidgetState extends State<RawEmojiIconWidget> {
  UserProfilePB? userProfile;

  EmojiIconData get emoji => widget.emoji;

  @override
  void initState() {
    super.initState();
    loadUserProfile();
  }

  @override
  void didUpdateWidget(RawEmojiIconWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    loadUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    final defaultEmoji = SizedBox(
      width: widget.emojiSize,
      child: EmojiText(
        emoji: '❓',
        fontSize: widget.emojiSize,
        textAlign: TextAlign.center,
      ),
    );
    try {
      switch (widget.emoji.type) {
        case FlowyIconType.emoji:
          return SizedBox(
            width: widget.emojiSize,
            child: EmojiText(
              emoji: widget.emoji.emoji,
              fontSize: widget.emojiSize,
              textAlign: TextAlign.justify,
            ),
          );
        case FlowyIconType.icon:
          IconsData iconData =
              IconsData.fromJson(jsonDecode(widget.emoji.emoji));
          if (!widget.enableColor) {
            iconData = iconData.noColor();
          }

          /// Under the same width conditions, icons on macOS seem to appear
          /// larger than emojis, so 0.9 is used here to slightly reduce the
          /// size of the icons
          final iconSize =
              Platform.isMacOS ? widget.emojiSize * 0.9 : widget.emojiSize;
          return IconWidget(
            iconsData: iconData,
            size: iconSize,
          );
        case FlowyIconType.custom:
          final url = widget.emoji.emoji;
          final isSvg = url.endsWith('.svg');
          final hasUserProfile = userProfile != null;
          if (isURL(url)) {
            Widget child = const SizedBox.shrink();
            if (isSvg) {
              child = FlowyNetworkSvg(
                url,
                headers:
                    hasUserProfile ? _buildRequestHeader(userProfile!) : {},
                width: widget.emojiSize,
                height: widget.emojiSize,
              );
            } else if (hasUserProfile) {
              child = FlowyNetworkImage(
                url: url,
                width: widget.emojiSize,
                height: widget.emojiSize,
                userProfilePB: userProfile,
                errorWidgetBuilder: (context, url, error) {
                  return const SizedBox.shrink();
                },
              );
            }
            return SizedBox.square(
              dimension: widget.emojiSize,
              child: child,
            );
          }
          final imageFile = File(url);
          if (!imageFile.existsSync()) {
            throw PathNotFoundException(url, const OSError());
          }
          return SizedBox.square(
            dimension: widget.emojiSize,
            child: isSvg
                ? SvgPicture.file(
                    File(url),
                    width: widget.emojiSize,
                    height: widget.emojiSize,
                  )
                : Image.file(
                    imageFile,
                    fit: BoxFit.cover,
                    width: widget.emojiSize,
                    height: widget.emojiSize,
                  ),
          );
      }
    } catch (e) {
      Log.error("Display widget error: $e");
      return defaultEmoji;
    }
  }

  Map<String, String> _buildRequestHeader(UserProfilePB userProfilePB) {
    final header = <String, String>{};
    final token = userProfilePB.token;
    try {
      final decodedToken = jsonDecode(token);
      header['Authorization'] = 'Bearer ${decodedToken['access_token']}';
    } catch (e) {
      Log.error('Unable to decode token: $e');
    }
    return header;
  }

  Future<void> loadUserProfile() async {
    if (userProfile != null) return;
    if (emoji.type == FlowyIconType.custom) {
      final userProfile =
          (await UserBackendService.getCurrentUserProfile()).fold(
        (userProfile) => userProfile,
        (l) => null,
      );
      if (mounted) {
        setState(() {
          this.userProfile = userProfile;
        });
      }
    }
  }
}
