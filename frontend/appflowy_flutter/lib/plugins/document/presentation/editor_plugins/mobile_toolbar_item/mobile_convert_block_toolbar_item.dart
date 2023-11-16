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
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 4,
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      children: [
        // bulleted list, numbered list
        _buildBlockButton(
          context,
          BulletedListBlockKeys.type,
          const AFMobileIcon(afMobileIcons: AFMobileIcons.bulletedList),
          LocaleKeys.document_plugins_bulletedList.tr(),
        ),
        _buildBlockButton(
          context,
          NumberedListBlockKeys.type,
          const AFMobileIcon(afMobileIcons: AFMobileIcons.numberedList),
          LocaleKeys.document_plugins_numberedList.tr(),
        ),

        // todo list, quote list
        _buildBlockButton(
          context,
          TodoListBlockKeys.type,
          const AFMobileIcon(afMobileIcons: AFMobileIcons.checkbox),
          LocaleKeys.document_plugins_todoList.tr(),
        ),
        _buildBlockButton(
          context,
          QuoteBlockKeys.type,
          const AFMobileIcon(afMobileIcons: AFMobileIcons.quote),
          LocaleKeys.document_plugins_quoteList.tr(),
        ),

        // toggle list, callout
        _buildBlockButton(
          context,
          ToggleListBlockKeys.type,
          const FlowySvg(
            FlowySvgs.toggle_list_s,
            size: Size.square(24),
          ),
          LocaleKeys.document_plugins_toggleList.tr(),
        ),
        _buildBlockButton(
          context,
          CalloutBlockKeys.type,
          const Icon(Icons.note_rounded),
          LocaleKeys.document_plugins_callout.tr(),
        ),
        _buildBlockButton(
          context,
          CodeBlockKeys.type,
          const Icon(Icons.abc),
          LocaleKeys.document_selectionMenu_codeBlock.tr(),
        ),
        // code block
        _buildBlockButton(
          context,
          CodeBlockKeys.type,
          const Icon(Icons.abc),
          LocaleKeys.document_selectionMenu_codeBlock.tr(),
        ),
        // outline
        _buildBlockButton(
          context,
          OutlineBlockKeys.type,
          const Icon(Icons.list_alt),
          LocaleKeys.document_selectionMenu_outline.tr(),
        ),
      ],
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
    icon: const FlowySvg(FlowySvgs.text_s),
    label: LocaleKeys.editor_text.tr(),
    isSelected: _unSelectable,
    onTap: (editorState, selection) {},
  ),

  // to-do list
  BlockMenuItem(
    blockType: TodoListBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.to_do_s),
    label: LocaleKeys.editor_checkbox.tr(),
    isSelected: _unSelectable,
    onTap: (editorState, selection) {},
  ),

  // heading 1 - 3
  BlockMenuItem(
    blockType: HeadingBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.h1_s),
    label: LocaleKeys.editor_heading1.tr(),
    isSelected: _unSelectable,
    onTap: (editorState, selection) {},
  ),

  BlockMenuItem(
    blockType: HeadingBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.h2_s),
    label: LocaleKeys.editor_heading2.tr(),
    isSelected: _unSelectable,
    onTap: (editorState, selection) {},
  ),

  BlockMenuItem(
    blockType: HeadingBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.h3_s),
    label: LocaleKeys.editor_heading3.tr(),
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
