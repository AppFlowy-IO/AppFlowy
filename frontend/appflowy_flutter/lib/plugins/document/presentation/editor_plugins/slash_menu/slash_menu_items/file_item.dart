import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/selectable_svg_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'slash_menu_items.dart';

final _keywords = [
  'file upload',
  'pdf',
  'zip',
  'archive',
  'upload',
  'attachment',
];

// file menu item
SelectionMenuItem fileSlashMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_slashMenu_name_file.tr(),
  keywords: _keywords,
  handler: (editorState, _, __) async => editorState.insertFileBlock(),
  nameBuilder: slashMenuItemNameBuilder,
  icon: (_, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_file_s,
    isSelected: isSelected,
    style: style,
  ),
);

extension on EditorState {
  Future<void> insertFileBlock() async {
    final fileGlobalKey = GlobalKey<FileBlockComponentState>();
    await insertEmptyFileBlock(fileGlobalKey);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      fileGlobalKey.currentState?.controller.show();
    });
  }
}
