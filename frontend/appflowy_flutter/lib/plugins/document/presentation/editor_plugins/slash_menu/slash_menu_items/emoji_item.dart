import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/selectable_svg_widget.dart';
import 'package:appflowy/plugins/emoji/emoji_actions_command.dart';
import 'package:appflowy/plugins/emoji/emoji_menu.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';

import 'slash_menu_item_builder.dart';

final _keywords = [
  'emoji',
  'reaction',
  'emoticon',
];

// emoji menu item
SelectionMenuItem emojiSlashMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_slashMenu_name_emoji.tr(),
  keywords: _keywords,
  handler: (editorState, menuService, context) => editorState.showEmojiPicker(
    context,
    menuService: menuService,
  ),
  nameBuilder: slashMenuItemNameBuilder,
  icon: (_, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_emoji_picker_s,
    isSelected: isSelected,
    style: style,
  ),
);

extension on EditorState {
  Future<void> showEmojiPicker(
    BuildContext context, {
    required SelectionMenuService menuService,
  }) async {
    final container = Overlay.of(context);
    menuService.dismiss();
    if (UniversalPlatform.isMobile || selection == null) {
      return;
    }

    final node = getNodeAtPath(selection!.end.path);
    final delta = node?.delta;
    if (node == null || delta == null || node.type == CodeBlockKeys.type) {
      return;
    }
    emojiMenuService = EmojiMenu(editorState: this, overlay: container);
    emojiMenuService?.show('');
  }
}
