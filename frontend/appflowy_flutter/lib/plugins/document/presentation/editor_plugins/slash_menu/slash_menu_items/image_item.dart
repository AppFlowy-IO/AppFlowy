import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/selectable_svg_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/image_placeholder.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'slash_menu_item_builder.dart';

final _keywords = [
  'image',
  'photo',
  'picture',
  'img',
];

/// Image menu item
final imageSlashMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_slashMenu_name_image.tr(),
  keywords: _keywords,
  handler: (editorState, _, __) async => editorState.insertImageBlock(),
  nameBuilder: slashMenuItemNameBuilder,
  icon: (editorState, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_image_s,
    isSelected: isSelected,
    style: style,
  ),
);

extension on EditorState {
  Future<void> insertImageBlock() async {
    // use the key to retrieve the state of the image block to show the popover automatically
    final imagePlaceholderKey = GlobalKey<ImagePlaceholderState>();
    await insertEmptyImageBlock(imagePlaceholderKey);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      imagePlaceholderKey.currentState?.controller.show();
    });
  }
}
