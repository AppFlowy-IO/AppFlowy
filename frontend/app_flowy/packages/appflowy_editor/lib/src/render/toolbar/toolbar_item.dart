import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/infra/flowy_svg.dart';
import 'package:appflowy_editor/src/render/link_menu/link_menu.dart';
import 'package:appflowy_editor/src/render/rich_text/rich_text_style.dart';
import 'package:appflowy_editor/src/extensions/text_node_extensions.dart';
import 'package:appflowy_editor/src/service/default_text_operations/format_rich_text_style.dart';
import 'package:flutter/material.dart';
import 'package:rich_clipboard/rich_clipboard.dart';

typedef ToolbarEventHandler = void Function(
    EditorState editorState, BuildContext context);
typedef ToolbarShowValidator = bool Function(EditorState editorState);

class ToolbarItem {
  ToolbarItem({
    required this.id,
    required this.icon,
    this.tooltipsMessage = '',
    required this.validator,
    required this.handler,
  });

  final String id;
  final Widget icon;
  final String tooltipsMessage;
  final ToolbarShowValidator validator;
  final ToolbarEventHandler handler;

  factory ToolbarItem.divider() {
    return ToolbarItem(
      id: 'divider',
      icon: const FlowySvg(name: 'toolbar/divider'),
      validator: (editorState) => true,
      handler: (editorState, context) {},
    );
  }
}

List<ToolbarItem> defaultToolbarItems = [
  ToolbarItem(
    id: 'appflowy.toolbar.h1',
    tooltipsMessage: 'Heading 1',
    icon: const FlowySvg(name: 'toolbar/h1'),
    validator: _onlyShowInSingleTextSelection,
    handler: (editorState, context) => formatHeading(editorState, StyleKey.h1),
  ),
  ToolbarItem(
    id: 'appflowy.toolbar.h2',
    tooltipsMessage: 'Heading 2',
    icon: const FlowySvg(name: 'toolbar/h2'),
    validator: _onlyShowInSingleTextSelection,
    handler: (editorState, context) => formatHeading(editorState, StyleKey.h2),
  ),
  ToolbarItem(
    id: 'appflowy.toolbar.h3',
    tooltipsMessage: 'Heading 3',
    icon: const FlowySvg(name: 'toolbar/h3'),
    validator: _onlyShowInSingleTextSelection,
    handler: (editorState, context) => formatHeading(editorState, StyleKey.h3),
  ),
  ToolbarItem.divider(),
  ToolbarItem(
    id: 'appflowy.toolbar.bold',
    tooltipsMessage: 'Bold',
    icon: const FlowySvg(name: 'toolbar/bold'),
    validator: _showInTextSelection,
    handler: (editorState, context) => formatBold(editorState),
  ),
  ToolbarItem(
    id: 'appflowy.toolbar.italic',
    tooltipsMessage: 'Italic',
    icon: const FlowySvg(name: 'toolbar/italic'),
    validator: _showInTextSelection,
    handler: (editorState, context) => formatItalic(editorState),
  ),
  ToolbarItem(
    id: 'appflowy.toolbar.underline',
    tooltipsMessage: 'Underline',
    icon: const FlowySvg(name: 'toolbar/underline'),
    validator: _showInTextSelection,
    handler: (editorState, context) => formatUnderline(editorState),
  ),
  ToolbarItem(
    id: 'appflowy.toolbar.strikethrough',
    tooltipsMessage: 'Strikethrough',
    icon: const FlowySvg(name: 'toolbar/strikethrough'),
    validator: _showInTextSelection,
    handler: (editorState, context) => formatStrikethrough(editorState),
  ),
  ToolbarItem.divider(),
  ToolbarItem(
    id: 'appflowy.toolbar.quote',
    tooltipsMessage: 'Quote',
    icon: const FlowySvg(name: 'toolbar/quote'),
    validator: _onlyShowInSingleTextSelection,
    handler: (editorState, context) => formatQuote(editorState),
  ),
  ToolbarItem(
    id: 'appflowy.toolbar.bulleted_list',
    tooltipsMessage: 'Bulleted list',
    icon: const FlowySvg(name: 'toolbar/bulleted_list'),
    validator: _onlyShowInSingleTextSelection,
    handler: (editorState, context) => formatBulletedList(editorState),
  ),
  ToolbarItem.divider(),
  ToolbarItem(
    id: 'appflowy.toolbar.link',
    tooltipsMessage: 'Link',
    icon: const FlowySvg(name: 'toolbar/link'),
    validator: _onlyShowInSingleTextSelection,
    handler: (editorState, context) => _showLinkMenu(editorState, context),
  ),
  ToolbarItem(
    id: 'appflowy.toolbar.highlight',
    tooltipsMessage: 'Highlight',
    icon: const FlowySvg(name: 'toolbar/highlight'),
    validator: _showInTextSelection,
    handler: (editorState, context) => formatHighlight(editorState),
  ),
];

ToolbarShowValidator _onlyShowInSingleTextSelection = (editorState) {
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  return (nodes.length == 1 && nodes.first is TextNode);
};

ToolbarShowValidator _showInTextSelection = (editorState) {
  final nodes = editorState.service.selectionService.currentSelectedNodes
      .whereType<TextNode>();
  return nodes.isNotEmpty;
};

OverlayEntry? _linkMenuOverlay;
EditorState? _editorState;
void _showLinkMenu(EditorState editorState, BuildContext context) {
  _editorState = editorState;

  final rects = editorState.service.selectionService.selectionRects;
  var maxBottom = 0.0;
  late Rect matchRect;
  for (final rect in rects) {
    if (rect.bottom > maxBottom) {
      maxBottom = rect.bottom;
      matchRect = rect;
    }
  }

  _dismissLinkMenu();

  // Since the link menu will only show in single text selection,
  // We get the text node directly instead of judging details again.
  final selection =
      editorState.service.selectionService.currentSelection.value!;
  final index =
      selection.isBackward ? selection.start.offset : selection.end.offset;
  final length = (selection.start.offset - selection.end.offset).abs();
  final node = editorState.service.selectionService.currentSelectedNodes.first
      as TextNode;
  final linkText = node.getAttributeInSelection(selection, StyleKey.href);
  _linkMenuOverlay = OverlayEntry(builder: (context) {
    return Positioned(
      top: matchRect.bottom,
      left: matchRect.left,
      child: Material(
        child: LinkMenu(
          linkText: linkText,
          onSubmitted: (text) {
            TransactionBuilder(editorState)
              ..formatText(node, index, length, {StyleKey.href: text})
              ..commit();
            _dismissLinkMenu();
          },
          onCopyLink: () {
            RichClipboard.setData(RichClipboardData(text: linkText));
            _dismissLinkMenu();
          },
          onRemoveLink: () {
            TransactionBuilder(editorState)
              ..formatText(node, index, length, {StyleKey.href: null})
              ..commit();
            _dismissLinkMenu();
          },
        ),
      ),
    );
  });
  Overlay.of(context)?.insert(_linkMenuOverlay!);

  editorState.service.scrollService?.disable();
  editorState.service.keyboardService?.disable();
  editorState.service.selectionService.currentSelection
      .addListener(_dismissLinkMenu);
}

void _dismissLinkMenu() {
  _linkMenuOverlay?.remove();
  _linkMenuOverlay = null;

  _editorState?.service.scrollService?.enable();
  _editorState?.service.keyboardService?.enable();
  _editorState?.service.selectionService.currentSelection
      .removeListener(_dismissLinkMenu);
  _editorState = null;
}
