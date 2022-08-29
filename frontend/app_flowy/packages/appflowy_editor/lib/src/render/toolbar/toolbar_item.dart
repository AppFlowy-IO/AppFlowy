import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/extensions/url_launcher_extension.dart';
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
    required this.type,
    required this.icon,
    this.tooltipsMessage = '',
    required this.validator,
    required this.handler,
  });

  final String id;
  final int type;
  final Widget icon;
  final String tooltipsMessage;
  final ToolbarShowValidator validator;
  final ToolbarEventHandler handler;

  factory ToolbarItem.divider() {
    return ToolbarItem(
      id: 'divider',
      type: -1,
      icon: const FlowySvg(name: 'toolbar/divider'),
      validator: (editorState) => true,
      handler: (editorState, context) {},
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! ToolbarItem) {
      return false;
    }
    if (identical(this, other)) {
      return true;
    }
    return id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}

List<ToolbarItem> defaultToolbarItems = [
  ToolbarItem(
    id: 'appflowy.toolbar.h1',
    type: 1,
    tooltipsMessage: 'Heading 1',
    icon: const FlowySvg(name: 'toolbar/h1'),
    validator: _onlyShowInSingleTextSelection,
    handler: (editorState, context) => formatHeading(editorState, StyleKey.h1),
  ),
  ToolbarItem(
    id: 'appflowy.toolbar.h2',
    type: 1,
    tooltipsMessage: 'Heading 2',
    icon: const FlowySvg(name: 'toolbar/h2'),
    validator: _onlyShowInSingleTextSelection,
    handler: (editorState, context) => formatHeading(editorState, StyleKey.h2),
  ),
  ToolbarItem(
    id: 'appflowy.toolbar.h3',
    type: 1,
    tooltipsMessage: 'Heading 3',
    icon: const FlowySvg(name: 'toolbar/h3'),
    validator: _onlyShowInSingleTextSelection,
    handler: (editorState, context) => formatHeading(editorState, StyleKey.h3),
  ),
  ToolbarItem(
    id: 'appflowy.toolbar.bold',
    type: 2,
    tooltipsMessage: 'Bold',
    icon: const FlowySvg(name: 'toolbar/bold'),
    validator: _showInTextSelection,
    handler: (editorState, context) => formatBold(editorState),
  ),
  ToolbarItem(
    id: 'appflowy.toolbar.italic',
    type: 2,
    tooltipsMessage: 'Italic',
    icon: const FlowySvg(name: 'toolbar/italic'),
    validator: _showInTextSelection,
    handler: (editorState, context) => formatItalic(editorState),
  ),
  ToolbarItem(
    id: 'appflowy.toolbar.underline',
    type: 2,
    tooltipsMessage: 'Underline',
    icon: const FlowySvg(name: 'toolbar/underline'),
    validator: _showInTextSelection,
    handler: (editorState, context) => formatUnderline(editorState),
  ),
  ToolbarItem(
    id: 'appflowy.toolbar.strikethrough',
    type: 2,
    tooltipsMessage: 'Strikethrough',
    icon: const FlowySvg(name: 'toolbar/strikethrough'),
    validator: _showInTextSelection,
    handler: (editorState, context) => formatStrikethrough(editorState),
  ),
  ToolbarItem(
    id: 'appflowy.toolbar.quote',
    type: 3,
    tooltipsMessage: 'Quote',
    icon: const FlowySvg(name: 'toolbar/quote'),
    validator: _onlyShowInSingleTextSelection,
    handler: (editorState, context) => formatQuote(editorState),
  ),
  ToolbarItem(
    id: 'appflowy.toolbar.bulleted_list',
    type: 3,
    tooltipsMessage: 'Bulleted list',
    icon: const FlowySvg(name: 'toolbar/bulleted_list'),
    validator: _onlyShowInSingleTextSelection,
    handler: (editorState, context) => formatBulletedList(editorState),
  ),
  ToolbarItem(
    id: 'appflowy.toolbar.link',
    type: 4,
    tooltipsMessage: 'Link',
    icon: const FlowySvg(name: 'toolbar/link'),
    validator: _onlyShowInSingleTextSelection,
    handler: (editorState, context) => showLinkMenu(context, editorState),
  ),
  ToolbarItem(
    id: 'appflowy.toolbar.highlight',
    type: 4,
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
bool _changeSelectionInner = false;
void showLinkMenu(
  BuildContext context,
  EditorState editorState, {
  Selection? customSelection,
}) {
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
  _editorState = editorState;

  // Since the link menu will only show in single text selection,
  // We get the text node directly instead of judging details again.
  final selection = customSelection ??
      editorState.service.selectionService.currentSelection.value;
  final node = editorState.service.selectionService.currentSelectedNodes;
  if (selection == null || node.isEmpty || node.first is! TextNode) {
    return;
  }
  final index =
      selection.isBackward ? selection.start.offset : selection.end.offset;
  final length = (selection.start.offset - selection.end.offset).abs();
  final textNode = node.first as TextNode;
  String? linkText;
  if (textNode.allSatisfyLinkInSelection(selection)) {
    linkText = textNode.getAttributeInSelection(selection, StyleKey.href);
  }
  _linkMenuOverlay = OverlayEntry(builder: (context) {
    return Positioned(
      top: matchRect.bottom + 5.0,
      left: matchRect.left,
      child: Material(
        child: LinkMenu(
          linkText: linkText,
          onOpenLink: () async {
            await safeLaunchUrl(linkText);
          },
          onSubmitted: (text) {
            TransactionBuilder(editorState)
              ..formatText(textNode, index, length, {StyleKey.href: text})
              ..commit();
            _dismissLinkMenu();
          },
          onCopyLink: () {
            RichClipboard.setData(RichClipboardData(text: linkText));
            _dismissLinkMenu();
          },
          onRemoveLink: () {
            TransactionBuilder(editorState)
              ..formatText(textNode, index, length, {StyleKey.href: null})
              ..commit();
            _dismissLinkMenu();
          },
          onFocusChange: (value) {
            if (value && customSelection != null) {
              _changeSelectionInner = true;
              editorState.service.selectionService
                  .updateSelection(customSelection);
            }
          },
        ),
      ),
    );
  });
  Overlay.of(context)?.insert(_linkMenuOverlay!);

  editorState.service.scrollService?.disable();
  editorState.service.selectionService.currentSelection
      .addListener(_dismissLinkMenu);
}

void _dismissLinkMenu() {
  if (_editorState?.service.selectionService.currentSelection.value == null) {
    return;
  }
  if (_changeSelectionInner) {
    _changeSelectionInner = false;
    return;
  }
  _linkMenuOverlay?.remove();
  _linkMenuOverlay = null;

  _editorState?.service.scrollService?.enable();
  _editorState?.service.keyboardService?.enable();
  _editorState?.service.selectionService.currentSelection
      .removeListener(_dismissLinkMenu);
  _editorState = null;
}
