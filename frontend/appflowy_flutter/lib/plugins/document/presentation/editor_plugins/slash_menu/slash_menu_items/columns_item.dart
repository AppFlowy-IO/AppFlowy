import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/selectable_svg_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/slash_menu/slash_menu_items/slash_menu_item_builder.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';

final _baseKeywords = [
  'columns',
  'column block',
];

final _twoColumnsKeywords = [
  ..._baseKeywords,
  'two columns',
  '2 columns',
];

final _threeColumnsKeywords = [
  ..._baseKeywords,
  'three columns',
  '3 columns',
];

final _fourColumnsKeywords = [
  ..._baseKeywords,
  'four columns',
  '4 columns',
];

final _fiveColumnsKeywords = [
  ..._baseKeywords,
  'five columns',
  '5 columns',
];

// 2 columns menu item
SelectionMenuItem twoColumnsSlashMenuItem = SelectionMenuItem.node(
  getName: () => LocaleKeys.document_slashMenu_name_twoColumns.tr(),
  keywords: _twoColumnsKeywords,
  nodeBuilder: (_, __) => simpleColumnsNode(columnCount: 2),
  replace: (_, node) => node.delta?.isEmpty ?? false,
  nameBuilder: slashMenuItemNameBuilder,
  iconBuilder: (_, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_two_columns_s,
    isSelected: isSelected,
    style: style,
  ),
);

// 3 columns menu item
SelectionMenuItem threeColumnsSlashMenuItem = SelectionMenuItem.node(
  getName: () => LocaleKeys.document_slashMenu_name_threeColumns.tr(),
  keywords: _threeColumnsKeywords,
  nodeBuilder: (_, __) => simpleColumnsNode(columnCount: 3),
  replace: (_, node) => node.delta?.isEmpty ?? false,
  nameBuilder: slashMenuItemNameBuilder,
  iconBuilder: (_, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_three_columns_s,
    isSelected: isSelected,
    style: style,
  ),
);

// 4 columns menu item
SelectionMenuItem fourColumnsSlashMenuItem = SelectionMenuItem.node(
  getName: () => LocaleKeys.document_slashMenu_name_fourColumns.tr(),
  keywords: _fourColumnsKeywords,
  nodeBuilder: (_, __) => simpleColumnsNode(columnCount: 4),
  replace: (_, node) => node.delta?.isEmpty ?? false,
  nameBuilder: slashMenuItemNameBuilder,
  iconBuilder: (_, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_four_columns_s,
    isSelected: isSelected,
    style: style,
  ),
);

// 5 columns menu item
SelectionMenuItem fiveColumnsSlashMenuItem = SelectionMenuItem.node(
  getName: () => '5 Columns',
  keywords: _fiveColumnsKeywords,
  nodeBuilder: (_, __) => simpleColumnsNode(columnCount: 5),
  replace: (_, node) => node.delta?.isEmpty ?? false,
  nameBuilder: slashMenuItemNameBuilder,
  iconBuilder: (_, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_code_block_s,
    isSelected: isSelected,
    style: style,
  ),
);
