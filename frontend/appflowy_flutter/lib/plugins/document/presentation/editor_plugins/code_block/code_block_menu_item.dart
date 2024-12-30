import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/selectable_svg_widget.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:easy_localization/easy_localization.dart';

final codeBlockSelectionMenuItem = SelectionMenuItem.node(
  getName: () => LocaleKeys.document_selectionMenu_codeBlock.tr(),
  iconBuilder: (editorState, onSelected, style) => SelectableSvgWidget(
    data: FlowySvgs.icon_code_block_s,
    isSelected: onSelected,
    style: style,
  ),
  keywords: ['code', 'codeblock'],
  nodeBuilder: (_, __) => codeBlockNode(),
  replace: (_, node) => node.delta?.isEmpty ?? false,
);
