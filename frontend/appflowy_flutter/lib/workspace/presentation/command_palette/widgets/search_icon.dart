import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/emoji_icon_widget.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy/workspace/application/command_palette/search_result_ext.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-search/result.pb.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

extension SearchIconExtension on ViewPB {
  Widget buildIcon(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return icon.value.isNotEmpty
        ? SizedBox(
            width: 16,
            child: RawEmojiIconWidget(
              emoji: icon.toEmojiIconData(),
              emojiSize: 16,
              lineHeight: 20 / 16,
            ),
          )
        : FlowySvg(
            iconData,
            size: const Size.square(18),
            color: theme.iconColorScheme.secondary,
          );
  }
}

extension SearchIconItemExtension on ResultIconPB {
  Widget? buildIcon(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final color = theme.iconColorScheme.secondary;

    if (ty == ResultIconTypePB.Emoji) {
      return SizedBox(
        width: 16,
        child: getIcon(size: 16, lineHeight: 20 / 16, iconColor: color) ??
            SizedBox.shrink(),
      );
    } else {
      return getIcon(iconColor: color) ?? SizedBox.shrink();
    }
  }
}
