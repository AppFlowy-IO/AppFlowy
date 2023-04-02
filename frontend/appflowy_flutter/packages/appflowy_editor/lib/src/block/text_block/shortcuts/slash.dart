import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/block/base_component/shortcuts/block_shortcut.dart';
import 'package:appflowy_editor/src/block/base_component/widget/full_screen_overlay.dart';
import 'package:appflowy_editor/src/infra/flowy_svg.dart';
import 'package:appflowy_editor/src/service/default_text_operations/format_rich_text_style.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

TextBlockShortcutHandler slashHandler = (context, textBlockState) {
  final editorState = Provider.of<EditorState>(context, listen: false);
  final selection = editorState.service.selectionServiceV2.selection;
  if (selection == null || !selection.isSingle) {
    return KeyEventResult.ignored;
  }
  final node = editorState.getNodesInSelection(selection).first;
  final tr = editorState.transaction;
  tr.replaceTextV2(node, selection.start.offset, selection.length, '/');
  editorState.apply(tr).then((_) {
    // show slash menu.
    // TOO COMPLICATED TO READ. OPTIMIZE IT.
    final textPosition =
        textBlockState.textSelectionFromEditorSelection(selection);
    if (textPosition == null || !textPosition.isCollapsed) {
      return;
    }
    final caretRect = textBlockState.selectionState.getCaretRect(
      textPosition.base,
    );
    final renderParagraph = textBlockState.selectionState.renderParagraph;
    final rect =
        renderParagraph.localToGlobal(Offset.zero) & renderParagraph.size;
    final normalizedRect = caretRect.translate(rect.left, rect.top);
    late OverlayEntry slashMenu;
    slashMenu = FullScreenOverlayEntry.build(
      onDismiss: () => slashMenu.remove(),
      offset: normalizedRect.bottomLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectionMenuWidget(
          items: [
            ..._defaultSelectionMenuItems,
            ...editorState.selectionMenuItems,
          ],
          maxItemInRow: 5,
          editorState: editorState,
          menuService: null,
          onExit: () {},
          onSelectionUpdate: () {},
        ),
      ),
    );
    Overlay.of(context)?.insert(slashMenu);
  });
  return KeyEventResult.handled;
};

final List<SelectionMenuItem> _defaultSelectionMenuItems = [
  SelectionMenuItem(
    name: AppFlowyEditorLocalizations.current.text,
    icon: (editorState, onSelected) =>
        _selectionMenuIcon('text', editorState, onSelected),
    keywords: ['text'],
    handler: (editorState, _, __) {
      insertTextNodeAfterSelection(editorState, {});
    },
  ),
  SelectionMenuItem(
    name: AppFlowyEditorLocalizations.current.heading1,
    icon: (editorState, onSelected) =>
        _selectionMenuIcon('h1', editorState, onSelected),
    keywords: ['heading 1, h1'],
    handler: (editorState, _, __) {
      insertHeadingAfterSelection(editorState, BuiltInAttributeKey.h1);
    },
  ),
  SelectionMenuItem(
    name: AppFlowyEditorLocalizations.current.heading2,
    icon: (editorState, onSelected) =>
        _selectionMenuIcon('h2', editorState, onSelected),
    keywords: ['heading 2, h2'],
    handler: (editorState, _, __) {
      insertHeadingAfterSelection(editorState, BuiltInAttributeKey.h2);
    },
  ),
  SelectionMenuItem(
    name: AppFlowyEditorLocalizations.current.heading3,
    icon: (editorState, onSelected) =>
        _selectionMenuIcon('h3', editorState, onSelected),
    keywords: ['heading 3, h3'],
    handler: (editorState, _, __) {
      insertHeadingAfterSelection(editorState, BuiltInAttributeKey.h3);
    },
  ),
  SelectionMenuItem(
    name: AppFlowyEditorLocalizations.current.bulletedList,
    icon: (editorState, onSelected) =>
        _selectionMenuIcon('bulleted_list', editorState, onSelected),
    keywords: ['bulleted list', 'list', 'unordered list'],
    handler: (editorState, _, __) {
      insertBulletedListAfterSelection(editorState);
    },
  ),
  SelectionMenuItem(
    name: AppFlowyEditorLocalizations.current.numberedList,
    icon: (editorState, onSelected) =>
        _selectionMenuIcon('number', editorState, onSelected),
    keywords: ['numbered list', 'list', 'ordered list'],
    handler: (editorState, _, __) {
      insertNumberedListAfterSelection(editorState);
    },
  ),
  SelectionMenuItem(
    name: AppFlowyEditorLocalizations.current.checkbox,
    icon: (editorState, onSelected) =>
        _selectionMenuIcon('checkbox', editorState, onSelected),
    keywords: ['todo list', 'list', 'checkbox list'],
    handler: (editorState, _, __) {
      insertCheckboxAfterSelection(editorState);
    },
  ),
  SelectionMenuItem(
    name: AppFlowyEditorLocalizations.current.quote,
    icon: (editorState, onSelected) =>
        _selectionMenuIcon('quote', editorState, onSelected),
    keywords: ['quote', 'refer'],
    handler: (editorState, _, __) {
      insertQuoteAfterSelection(editorState);
    },
  ),
];

Widget _selectionMenuIcon(
    String name, EditorState editorState, bool onSelected) {
  return FlowySvg(
    name: 'selection_menu/$name',
    color: onSelected
        ? editorState.editorStyle.selectionMenuItemSelectedIconColor
        : editorState.editorStyle.selectionMenuItemIconColor,
    width: 18.0,
    height: 18.0,
  );
}
