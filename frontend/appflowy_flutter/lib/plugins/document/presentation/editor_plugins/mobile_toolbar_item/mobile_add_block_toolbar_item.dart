import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_item/mobile_blocks_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

// convert the current block to other block types
// only show in single selection and text type
final mobileAddBlockToolbarItem = MobileToolbarItem.withMenu(
  itemIconBuilder: (_, editorState, ___) {
    if (!onlyShowInSingleSelectionAndTextType(editorState)) {
      return null;
    }
    return const FlowySvg(
      FlowySvgs.add_m,
      size: Size.square(48),
    );
  },
  itemMenuBuilder: (_, editorState, service) {
    final selection = editorState.selection;
    if (selection == null) {
      return null;
    }
    return BlocksMenu(
      items: _addBlockMenuItems,
      editorState: editorState,
      service: service,
    );
  },
);

final _addBlockMenuItems = [
  // paragraph
  BlockMenuItem(
    blockType: ParagraphBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.m_text_decoration_m),
    label: LocaleKeys.editor_text.tr(),
    isSelected: _unSelectable,
    onTap: (editorState, selection, service) async {
      await editorState.insertBlockOrReplaceCurrentBlock(
        selection,
        paragraphNode(),
      );
      service.closeItemMenu();
    },
  ),

  // to-do list
  BlockMenuItem(
    blockType: TodoListBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.m_checkbox_m),
    label: LocaleKeys.editor_checkbox.tr(),
    isSelected: _unSelectable,
    onTap: (editorState, selection, service) async {
      await editorState.insertBlockOrReplaceCurrentBlock(
        selection,
        todoListNode(checked: false),
      );
      service.closeItemMenu();
    },
  ),

  // heading 1 - 3
  BlockMenuItem(
    blockType: HeadingBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.m_h1_m),
    label: LocaleKeys.editor_heading1.tr(),
    isSelected: _unSelectable,
    onTap: (editorState, selection, service) async {
      await editorState.insertBlockOrReplaceCurrentBlock(
        selection,
        headingNode(level: 1),
      );
      service.closeItemMenu();
    },
  ),
  BlockMenuItem(
    blockType: HeadingBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.m_h2_m),
    label: LocaleKeys.editor_heading2.tr(),
    isSelected: _unSelectable,
    onTap: (editorState, selection, service) async {
      await editorState.insertBlockOrReplaceCurrentBlock(
        selection,
        headingNode(level: 2),
      );
      service.closeItemMenu();
    },
  ),
  BlockMenuItem(
    blockType: HeadingBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.m_h3_m),
    label: LocaleKeys.editor_heading3.tr(),
    isSelected: _unSelectable,
    onTap: (editorState, selection, service) async {
      await editorState.insertBlockOrReplaceCurrentBlock(
        selection,
        headingNode(level: 3),
      );
      service.closeItemMenu();
    },
  ),

  // bulleted list
  BlockMenuItem(
    blockType: BulletedListBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.m_bulleted_list_m),
    label: LocaleKeys.editor_bulletedList.tr(),
    isSelected: _unSelectable,
    onTap: (editorState, selection, service) async {
      await editorState.insertBlockOrReplaceCurrentBlock(
        selection,
        bulletedListNode(),
      );
      service.closeItemMenu();
    },
  ),

  // numbered list
  BlockMenuItem(
    blockType: NumberedListBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.m_numbered_list_m),
    label: LocaleKeys.editor_numberedList.tr(),
    isSelected: _unSelectable,
    onTap: (editorState, selection, service) async {
      await editorState.insertBlockOrReplaceCurrentBlock(
        selection,
        numberedListNode(),
      );
      service.closeItemMenu();
    },
  ),

  // toggle list
  BlockMenuItem(
    blockType: ToggleListBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.m_toggle_list_m),
    label: LocaleKeys.document_plugins_toggleList.tr(),
    isSelected: _unSelectable,
    onTap: (editorState, selection, service) async {
      await editorState.insertBlockOrReplaceCurrentBlock(
        selection,
        toggleListBlockNode(),
      );
      service.closeItemMenu();
    },
  ),

  // quote
  BlockMenuItem(
    blockType: QuoteBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.m_quote_m),
    label: LocaleKeys.editor_quote.tr(),
    isSelected: _unSelectable,
    onTap: (editorState, selection, service) async {
      await editorState.insertBlockOrReplaceCurrentBlock(
        selection,
        quoteNode(),
      );
      service.closeItemMenu();
    },
  ),

  // callout
  BlockMenuItem(
    blockType: CalloutBlockKeys.type,
    // FIXME: update icon
    icon: const Icon(Icons.note_rounded),
    label: LocaleKeys.document_plugins_callout.tr(),
    isSelected: _unSelectable,
    onTap: (editorState, selection, service) async {
      await editorState.insertBlockOrReplaceCurrentBlock(
        selection,
        calloutNode(),
      );
      service.closeItemMenu();
    },
  ),

  // code
  BlockMenuItem(
    blockType: CodeBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.m_code_m),
    label: LocaleKeys.document_selectionMenu_codeBlock.tr(),
    isSelected: _unSelectable,
    onTap: (editorState, selection, service) async {
      await editorState.insertBlockOrReplaceCurrentBlock(
        selection,
        codeBlockNode(),
      );
      service.closeItemMenu();
    },
  ),

  // divider
  BlockMenuItem(
    blockType: DividerBlockKeys.type,
    icon: const FlowySvg(FlowySvgs.m_divider_m),
    label: LocaleKeys.editor_divider.tr(),
    isSelected: _unSelectable,
    onTap: (editorState, selection, service) async {
      await editorState.insertDivider(selection);
      service.closeItemMenu();
    },
  ),

  // math equation
  BlockMenuItem(
    blockType: MathEquationBlockKeys.type,
    icon: const FlowySvg(
      FlowySvgs.math_lg,
      size: Size.square(22),
    ),
    label: LocaleKeys.document_plugins_mathEquation_name.tr(),
    isSelected: _unSelectable,
    onTap: (editorState, selection, service) async {
      await editorState.insertMathEquation(selection);
      service.closeItemMenu();
    },
  ),
];

bool _unSelectable(
  EditorState editorState,
  Selection selection,
) {
  return false;
}

extension on EditorState {
  Future<void> insertBlockOrReplaceCurrentBlock(
    Selection selection,
    Node insertedNode,
  ) async {
    // If the current block is not an empty paragraph block,
    // then insert a new block below the current block.
    final node = getNodeAtPath(selection.start.path);
    if (node == null) {
      return;
    }
    final transaction = this.transaction;
    if (node.type != ParagraphBlockKeys.type ||
        (node.delta?.isNotEmpty ?? true)) {
      final path = node.path.next;
      // insert the block below the current empty paragraph block
      transaction
        ..insertNode(path, insertedNode)
        ..afterSelection = Selection.collapsed(
          Position(path: path, offset: 0),
        );
    } else {
      final path = node.path;
      // replace the current empty paragraph block with the inserted block
      transaction
        ..insertNode(path, insertedNode)
        ..deleteNode(node)
        ..afterSelection = Selection.collapsed(
          Position(path: path, offset: 0),
        );
    }
    await apply(transaction);
  }

  Future<void> insertMathEquation(
    Selection selection,
  ) async {
    final path = selection.start.path;
    final node = getNodeAtPath(path);
    final delta = node?.delta;
    if (node == null || delta == null) {
      return;
    }
    final transaction = this.transaction;
    final insertedNode = mathEquationNode();
    if (delta.isEmpty) {
      transaction
        ..insertNode(path, insertedNode)
        ..deleteNode(node);
    } else {
      transaction.insertNode(
        path.next,
        insertedNode,
      );
    }

    await apply(transaction);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final mathEquationState = getNodeAtPath(path)?.key.currentState;
      if (mathEquationState != null &&
          mathEquationState is MathEquationBlockComponentWidgetState) {
        mathEquationState.showEditingDialog();
      }
    });
  }

  Future<void> insertDivider(Selection selection) async {
    // same as the [handler] of [dividerMenuItem] in Desktop

    final path = selection.end.path;
    final node = getNodeAtPath(path);
    final delta = node?.delta;
    if (node == null || delta == null) {
      return;
    }
    final insertedPath = delta.isEmpty ? path : path.next;
    final transaction = this.transaction;
    transaction.insertNode(insertedPath, dividerNode());
    // only insert a new paragraph node when the next node is not a paragraph node
    //  and its delta is not empty.
    final next = node.next;
    if (next == null ||
        next.type != ParagraphBlockKeys.type ||
        next.delta?.isNotEmpty == true) {
      transaction.insertNode(
        insertedPath,
        paragraphNode(),
      );
    }
    transaction.afterSelection = Selection.collapsed(
      Position(path: insertedPath.next),
    );
    await apply(transaction);
  }
}
