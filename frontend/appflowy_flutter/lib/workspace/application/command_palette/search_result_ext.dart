import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/emoji_icon_widget.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy_backend/protobuf/flowy-search/result.pb.dart';
import 'package:flutter/material.dart';

extension GetIcon on ResultIconPB {
  Widget? getIcon({
    double size = 18.0,
    double lineHeight = 1.0,
    Color? iconColor,
  }) {
    final iconValue = value, iconType = ty;
    if (iconType == ResultIconTypePB.Emoji) {
      return iconValue.isNotEmpty
          ? RawEmojiIconWidget(
              emoji: EmojiIconData(iconType.toFlowyIconType(), iconValue),
              emojiSize: size,
              lineHeight: lineHeight,
            )
          : null;
    } else if (ty == ResultIconTypePB.Icon) {
      if (_resultIconValueTypes.contains(iconValue)) {
        return FlowySvg(
          getViewSvg(),
          size: Size.square(size),
          color: iconColor,
        );
      }
      return RawEmojiIconWidget(
        emoji: EmojiIconData(iconType.toFlowyIconType(), iconValue),
        emojiSize: size,
        lineHeight: lineHeight,
      );
    }
    return null;
  }
}

extension ResultIconTypePBToFlowyIconType on ResultIconTypePB {
  FlowyIconType toFlowyIconType() {
    switch (this) {
      case ResultIconTypePB.Emoji:
        return FlowyIconType.emoji;
      case ResultIconTypePB.Icon:
        return FlowyIconType.icon;
      case ResultIconTypePB.Url:
        return FlowyIconType.custom;
      default:
        return FlowyIconType.custom;
    }
  }
}

extension _ToViewIcon on ResultIconPB {
  FlowySvgData getViewSvg() => switch (value) {
        "0" => FlowySvgs.icon_document_s,
        "1" => FlowySvgs.icon_grid_s,
        "2" => FlowySvgs.icon_board_s,
        "3" => FlowySvgs.icon_calendar_s,
        "4" => FlowySvgs.chat_ai_page_s,
        _ => FlowySvgs.icon_document_s,
      };
}

const _resultIconValueTypes = {'0', '1', '2', '3', '4'};
