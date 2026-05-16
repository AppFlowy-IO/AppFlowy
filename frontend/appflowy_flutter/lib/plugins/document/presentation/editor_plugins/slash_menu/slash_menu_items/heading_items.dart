import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/selectable_svg_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';

import 'slash_menu_item_builder.dart';

final _h1Keywords = [
  'heading 1',
  'h1',
  'heading1',
];
final _h2Keywords = [
  'heading 2',
  'h2',
  'heading2',
];
final _h3Keywords = [
  'heading 3',
  'h3',
  'heading3',
];

final _toggleH1Keywords = [
  'toggle heading 1',
  'toggle h1',
  'toggle heading1',
  'toggleheading1',
  'toggleh1',
];
final _toggleH2Keywords = [
  'toggle heading 2',
  'toggle h2',
  'toggle heading2',
  'toggleheading2',
  'toggleh2',
];
final _toggleH3Keywords = [
  'toggle heading 3',
  'toggle h3',
  'toggle heading3',
  'toggleheading3',
  'toggleh3',
];

// heading 1 - 3 menu items
final heading1SlashMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_slashMenu_name_heading1.tr(),
  keywords: _h1Keywords,
  handler: (editorState, _, __) async => insertHeadingAfterSelection(
    editorState,
    1,
  ),
  nameBuilder: slashMenuItemNameBuilder,
  icon: (editorState, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_h1_s,
    isSelected: isSelected,
    style: style,
  ),
);

final heading2SlashMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_slashMenu_name_heading2.tr(),
  keywords: _h2Keywords,
  handler: (editorState, _, __) async => insertHeadingAfterSelection(
    editorState,
    2,
  ),
  nameBuilder: slashMenuItemNameBuilder,
  icon: (editorState, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_h2_s,
    isSelected: isSelected,
    style: style,
  ),
);

final heading3SlashMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_slashMenu_name_heading3.tr(),
  keywords: _h3Keywords,
  handler: (editorState, _, __) async => insertHeadingAfterSelection(
    editorState,
    3,
  ),
  nameBuilder: slashMenuItemNameBuilder,
  icon: (editorState, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_h3_s,
    isSelected: isSelected,
    style: style,
  ),
);

// toggle heading 1 menu item
// heading 1 - 3 menu items
final toggleHeading1SlashMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_slashMenu_name_toggleHeading1.tr(),
  keywords: _toggleH1Keywords,
  handler: (editorState, _, __) async => insertNodeAfterSelection(
    editorState,
    toggleHeadingNode(),
  ),
  nameBuilder: slashMenuItemNameBuilder,
  icon: (editorState, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.toggle_heading1_s,
    isSelected: isSelected,
    style: style,
  ),
);

final toggleHeading2SlashMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_slashMenu_name_toggleHeading2.tr(),
  keywords: _toggleH2Keywords,
  handler: (editorState, _, __) async => insertNodeAfterSelection(
    editorState,
    toggleHeadingNode(level: 2),
  ),
  nameBuilder: slashMenuItemNameBuilder,
  icon: (editorState, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.toggle_heading2_s,
    isSelected: isSelected,
    style: style,
  ),
);

final toggleHeading3SlashMenuItem = SelectionMenuItem(
  getName: () => LocaleKeys.document_slashMenu_name_toggleHeading3.tr(),
  keywords: _toggleH3Keywords,
  handler: (editorState, _, __) async => insertNodeAfterSelection(
    editorState,
    toggleHeadingNode(level: 3),
  ),
  nameBuilder: slashMenuItemNameBuilder,
  icon: (editorState, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.toggle_heading3_s,
    isSelected: isSelected,
    style: style,
  ),
);
