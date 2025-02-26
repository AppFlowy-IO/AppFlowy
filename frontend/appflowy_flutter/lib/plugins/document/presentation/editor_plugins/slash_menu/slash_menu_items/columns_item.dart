import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/selectable_svg_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/slash_menu/slash_menu_items/slash_menu_item_builder.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

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
  getName: () => '2 Columns',
  keywords: _twoColumnsKeywords,
  nodeBuilder: (_, __) => simpleColumnsNode(columnCount: 2),
  replace: (_, node) => node.delta?.isEmpty ?? false,
  nameBuilder: slashMenuItemNameBuilder,
  iconBuilder: (_, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_code_block_s,
    isSelected: isSelected,
    style: style,
  ),
);

// 3 columns menu item
SelectionMenuItem threeColumnsSlashMenuItem = SelectionMenuItem.node(
  getName: () => '3 Columns',
  keywords: _threeColumnsKeywords,
  nodeBuilder: (_, __) => simpleColumnsNode(columnCount: 3),
  replace: (_, node) => node.delta?.isEmpty ?? false,
  nameBuilder: slashMenuItemNameBuilder,
  iconBuilder: (_, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_code_block_s,
    isSelected: isSelected,
    style: style,
  ),
);

// 4 columns menu item
SelectionMenuItem fourColumnsSlashMenuItem = SelectionMenuItem.node(
  getName: () => '4 Columns',
  keywords: _fourColumnsKeywords,
  nodeBuilder: (_, __) => simpleColumnsNode(columnCount: 4),
  replace: (_, node) => node.delta?.isEmpty ?? false,
  nameBuilder: slashMenuItemNameBuilder,
  iconBuilder: (_, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_code_block_s,
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
