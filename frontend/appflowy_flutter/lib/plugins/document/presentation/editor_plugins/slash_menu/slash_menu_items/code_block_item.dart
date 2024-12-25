import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/selectable_svg_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/slash_menu/slash_menu_items/slash_menu_item_builder.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:easy_localization/easy_localization.dart';

final _keywords = [
  'code',
  'code block',
  'codeblock',
];

// code block menu item
SelectionMenuItem codeBlockSlashMenuItem = SelectionMenuItem.node(
  getName: () => LocaleKeys.document_slashMenu_name_code.tr(),
  keywords: _keywords,
  nodeBuilder: (_, __) => codeBlockNode(),
  replace: (_, node) => node.delta?.isEmpty ?? false,
  nameBuilder: slashMenuItemNameBuilder,
  iconBuilder: (_, isSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.slash_menu_icon_code_block_s,
    isSelected: isSelected,
    style: style,
  ),
);
