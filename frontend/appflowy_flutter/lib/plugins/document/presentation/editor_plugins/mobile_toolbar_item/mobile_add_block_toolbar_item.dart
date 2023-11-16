import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_item/mobile_blocks_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

// convert the current block to other block types
// only show in single selection and text type
final mobileConvertBlockToolbarItem = MobileToolbarItem.withMenu(
  itemIconBuilder: (_, editorState, ___) {
    if (!onlyShowInSingleSelectionAndTextType(editorState)) {
      return null;
    }
    return const FlowySvg(
      FlowySvgs.convert_s,
      size: Size.square(22),
    );
  },
  itemMenuBuilder: (_, editorState, __) {
    final selection = editorState.selection;
    if (selection == null) {
      return null;
    }
    return _ConvertToMenu(
      editorState: editorState,
      selection: selection,
    );
  },
);

class _ConvertToMenu extends StatelessWidget {
  const _ConvertToMenu({
    required this.editorState,
    required this.selection,
  });

  final Selection selection;
  final EditorState editorState;

  @override
  Widget build(BuildContext context) {
    return BlocksMenu(
      editorState: editorState,
      items: _convertToBlockMenus,
    );
  }

  Widget _buildBlockButton(
    BuildContext context,
    String blockType,
    Widget icon,
    String label,
  ) {
    final node = editorState.getNodeAtPath(selection.start.path);
    final type = node?.type;
    if (node == null || type == null) {
      const SizedBox.shrink();
    }
    final isSelected = type == blockType;
    return MobileToolbarItemMenuBtn(
      icon: icon,
      label: FlowyText(label),
      isSelected: isSelected,
      onPressed: () async {
        await editorState.formatNode(
          selection,
          (node) {
            final attributes = {
              ParagraphBlockKeys.delta: (node.delta ?? Delta()).toJson(),
              if (blockType == TodoListBlockKeys.type)
                TodoListBlockKeys.checked: false,
              if (blockType == CalloutBlockKeys.type)
                CalloutBlockKeys.icon: '📌',
            };
            return node.copyWith(
              type: isSelected ? ParagraphBlockKeys.type : blockType,
              attributes: attributes,
            );
          },
        );
      },
    );
  }
}

final _convertToBlockMenus = [
  // paragraph
  BlockMenuItem(
    blockType: PageBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.m_text_decoration_m),
    label: LocaleKeys.editor_text.tr(),
    isSelected: _unSelectable,
    onTap: (editorState, selection) {},
  ),

  // to-do list
  BlockMenuItem(
    blockType: TodoListBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.m_checkbox_m),
    label: LocaleKeys.editor_checkbox.tr(),
    isSelected: _unSelectable,
    onTap: (editorState, selection) {},
  ),

  // heading 1 - 3
  BlockMenuItem(
    blockType: HeadingBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.m_h1_m),
    label: LocaleKeys.editor_heading1.tr(),
    isSelected: _unSelectable,
    onTap: (editorState, selection) {},
  ),
  BlockMenuItem(
    blockType: HeadingBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.m_h2_m),
    label: LocaleKeys.editor_heading2.tr(),
    isSelected: _unSelectable,
    onTap: (editorState, selection) {},
  ),
  BlockMenuItem(
    blockType: HeadingBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.m_h3_m),
    label: LocaleKeys.editor_heading3.tr(),
    isSelected: _unSelectable,
    onTap: (editorState, selection) {},
  ),

  // bulleted list
  BlockMenuItem(
    blockType: BulletedListBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.m_bulleted_list_m),
    label: LocaleKeys.editor_bulletedList.tr(),
    isSelected: _unSelectable,
    onTap: (editorState, selection) {},
  ),

  // numbered list
  BlockMenuItem(
    blockType: NumberedListBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.m_numbered_list_m),
    label: LocaleKeys.editor_numberedList.tr(),
    isSelected: _unSelectable,
    onTap: (editorState, selection) {},
  ),

  // toggle list
  BlockMenuItem(
    blockType: ToggleListBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.m_toggle_list_m),
    label: LocaleKeys.document_plugins_toggleList.tr(),
    isSelected: _unSelectable,
    onTap: (editorState, selection) {},
  ),

  // quote
  BlockMenuItem(
    blockType: QuoteBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.m_quote_m),
    label: LocaleKeys.editor_quote.tr(),
    isSelected: _unSelectable,
    onTap: (editorState, selection) {},
  ),

  // callout
  BlockMenuItem(
    blockType: CalloutBlockKeys.type,
    // FIXME: update icon
    icon: const Icon(Icons.note_rounded),
    label: LocaleKeys.document_plugins_callout.tr(),
    isSelected: _unSelectable,
    onTap: (editorState, selection) {},
  ),

  // code
  BlockMenuItem(
    blockType: CodeBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.m_code_m),
    label: LocaleKeys.document_selectionMenu_codeBlock.tr(),
    isSelected: _unSelectable,
    onTap: (editorState, selection) {},
  ),
];

bool _unSelectable(
  EditorState editorState,
  Selection selection,
) {
  return false;
}
