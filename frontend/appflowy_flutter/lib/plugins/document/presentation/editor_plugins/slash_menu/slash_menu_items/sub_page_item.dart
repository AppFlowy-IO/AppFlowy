import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/selectable_svg_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/shared_context/shared_context.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'slash_menu_items.dart';

final _keywords = [
  LocaleKeys.document_slashMenu_subPage_keyword1.tr(),
  LocaleKeys.document_slashMenu_subPage_keyword2.tr(),
  LocaleKeys.document_slashMenu_subPage_keyword3.tr(),
  LocaleKeys.document_slashMenu_subPage_keyword4.tr(),
  LocaleKeys.document_slashMenu_subPage_keyword5.tr(),
  LocaleKeys.document_slashMenu_subPage_keyword6.tr(),
  LocaleKeys.document_slashMenu_subPage_keyword7.tr(),
  LocaleKeys.document_slashMenu_subPage_keyword8.tr(),
];

// Sub-page menu item
SelectionMenuItem subPageSlashMenuItem = SelectionMenuItem.node(
  getName: () => LocaleKeys.document_slashMenu_subPage_name.tr(),
  keywords: _keywords,
  updateSelection: (editorState, path, __, ___) {
    final context = editorState.document.root.context;
    if (context != null) {
      final isInDatabase =
          context.read<SharedEditorContext>().isInDatabaseRowPage;
      if (isInDatabase) {
        Navigator.of(context).pop();
      }
    }
    return Selection.collapsed(Position(path: path));
  },
  replace: (_, node) => node.delta?.isEmpty ?? false,
  nodeBuilder: (_, __) => subPageNode(),
  nameBuilder: slashMenuItemNameBuilder,
  iconBuilder: (_, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.insert_document_s,
    isSelected: isSelected,
    style: style,
  ),
);
