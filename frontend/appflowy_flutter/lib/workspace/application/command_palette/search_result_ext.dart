import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/emoji_icon_widget.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy_backend/protobuf/flowy-search/result.pb.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';

extension GetIcon on SearchResponseItemPB {
  Widget? getIcon() {
    final iconValue = icon.value, iconType = icon.ty;
    if (iconType == ResultIconTypePB.Emoji) {
      return iconValue.isNotEmpty
          ? FlowyText.emoji(iconValue, fontSize: 18)
          : null;
    } else if (icon.ty == ResultIconTypePB.Icon) {
      if (_resultIconValueTypes.contains(iconValue)) {
        return FlowySvg(icon.getViewSvg(), size: const Size.square(18));
      }
      return RawEmojiIconWidget(
        emoji: EmojiIconData(iconType.toFlowyIconType(), icon.value),
        emojiSize: 18,
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
