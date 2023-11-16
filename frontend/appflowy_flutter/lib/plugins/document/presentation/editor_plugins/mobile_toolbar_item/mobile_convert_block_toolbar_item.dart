import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_item/mobile_blocks_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
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
}

final _convertToBlockMenus = [
  // paragraph
  BlockMenuItem(
    blockType: ParagraphBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.m_text_decoration_m),
    label: LocaleKeys.editor_text.tr(),
    onTap: (editorState, selection) => editorState.convertBlockType(
      selection,
      ParagraphBlockKeys.type,
    ),
  ),

  // to-do list
  BlockMenuItem(
    blockType: TodoListBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.m_checkbox_m),
    label: LocaleKeys.editor_checkbox.tr(),
    onTap: (editorState, selection) => editorState.convertBlockType(
      selection,
      TodoListBlockKeys.type,
      extraAttributes: {
        TodoListBlockKeys.checked: false,
      },
    ),
  ),

  // heading 1 - 3
  BlockMenuItem(
    blockType: HeadingBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.m_h1_m),
    label: LocaleKeys.editor_heading1.tr(),
    isSelected: (editorState, selection) => _isHeadingSelected(
      editorState,
      selection,
      1,
    ),
    onTap: (editorState, selection) {
      final isSelected = _isHeadingSelected(
        editorState,
        selection,
        1,
      );
      editorState.convertBlockType(
        selection,
        HeadingBlockKeys.type,
        isSelected: isSelected,
        extraAttributes: {
          HeadingBlockKeys.level: 1,
        },
      );
    },
  ),
  BlockMenuItem(
    blockType: HeadingBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.m_h2_m),
    label: LocaleKeys.editor_heading2.tr(),
    isSelected: (editorState, selection) => _isHeadingSelected(
      editorState,
      selection,
      2,
    ),
    onTap: (editorState, selection) {
      final isSelected = _isHeadingSelected(
        editorState,
        selection,
        2,
      );
      editorState.convertBlockType(
        selection,
        HeadingBlockKeys.type,
        isSelected: isSelected,
        extraAttributes: {
          HeadingBlockKeys.level: 2,
        },
      );
    },
  ),
  BlockMenuItem(
    blockType: HeadingBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.m_h3_m),
    label: LocaleKeys.editor_heading3.tr(),
    isSelected: (editorState, selection) => _isHeadingSelected(
      editorState,
      selection,
      3,
    ),
    onTap: (editorState, selection) {
      final isSelected = _isHeadingSelected(
        editorState,
        selection,
        3,
      );
      editorState.convertBlockType(
        selection,
        HeadingBlockKeys.type,
        isSelected: isSelected,
        extraAttributes: {
          HeadingBlockKeys.level: 3,
        },
      );
    },
  ),

  // bulleted list
  BlockMenuItem(
    blockType: BulletedListBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.m_bulleted_list_m),
    label: LocaleKeys.editor_bulletedList.tr(),
    onTap: (editorState, selection) => editorState.convertBlockType(
      selection,
      BulletedListBlockKeys.type,
    ),
  ),

  // numbered list
  BlockMenuItem(
    blockType: NumberedListBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.m_numbered_list_m),
    label: LocaleKeys.editor_numberedList.tr(),
    onTap: (editorState, selection) => editorState.convertBlockType(
      selection,
      NumberedListBlockKeys.type,
    ),
  ),

  // toggle list
  BlockMenuItem(
    blockType: ToggleListBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.m_toggle_list_m),
    label: LocaleKeys.document_plugins_toggleList.tr(),
    onTap: (editorState, selection) => editorState.convertBlockType(
      selection,
      ToggleListBlockKeys.type,
    ),
  ),

  // quote
  BlockMenuItem(
    blockType: QuoteBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.m_quote_m),
    label: LocaleKeys.editor_quote.tr(),
    onTap: (editorState, selection) => editorState.convertBlockType(
      selection,
      QuoteBlockKeys.type,
    ),
  ),

  // callout
  BlockMenuItem(
    blockType: CalloutBlockKeys.type,
    // FIXME: update icon
    icon: const Icon(Icons.note_rounded),
    label: LocaleKeys.document_plugins_callout.tr(),
    onTap: (editorState, selection) => editorState.convertBlockType(
      selection,
      CalloutBlockKeys.type,
      extraAttributes: {
        CalloutBlockKeys.icon: '📌',
      },
    ),
  ),

  // code
  BlockMenuItem(
    blockType: CodeBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.m_code_m),
    label: LocaleKeys.document_selectionMenu_codeBlock.tr(),
    onTap: (editorState, selection) => editorState.convertBlockType(
      selection,
      CodeBlockKeys.type,
    ),
  ),
];

extension on EditorState {
  Future<void> convertBlockType(
    Selection selection,
    String newBlockType, {
    Attributes? extraAttributes,
    bool? isSelected,
  }) async {
    final node = getNodeAtPath(selection.start.path);
    final type = node?.type;
    if (node == null || type == null) {
      assert(false, 'node or type is null');
      return;
    }
    final selected = isSelected ?? type == newBlockType;
    await formatNode(
      selection,
      (node) {
        final attributes = {
          ParagraphBlockKeys.delta: (node.delta ?? Delta()).toJson(),
          // for some block types, they have extra attributes, like todo list has checked attribute, callout has icon attribute, etc.
          if (!selected && extraAttributes != null) ...extraAttributes,
        };
        return node.copyWith(
          type: selected ? ParagraphBlockKeys.type : newBlockType,
          attributes: attributes,
        );
      },
    );
  }
}

bool _isHeadingSelected(
  EditorState editorState,
  Selection selection,
  int level,
) {
  final node = editorState.getNodeAtPath(selection.start.path);
  final type = node?.type;
  if (node == null || type == null) {
    return false;
  }
  return type == HeadingBlockKeys.type &&
      node.attributes[HeadingBlockKeys.level] == level;
}
