import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/commands/text/text_commands.dart';
import 'package:appflowy_editor/src/extensions/url_launcher_extension.dart';
import 'package:appflowy_editor/src/flutter/overlay.dart';
import 'package:appflowy_editor/src/infra/flowy_svg.dart';
import 'package:appflowy_editor/src/render/link_menu/link_menu.dart';
import 'package:appflowy_editor/src/extensions/text_node_extensions.dart';
import 'package:appflowy_editor/src/extensions/editor_state_extensions.dart';
import 'package:appflowy_editor/src/service/default_text_operations/format_rich_text_style.dart';

import 'package:flutter/material.dart' hide Overlay, OverlayEntry;
import 'package:rich_clipboard/rich_clipboard.dart';

typedef ToolbarItemEventHandler = void Function(
    EditorState editorState, BuildContext context);
typedef ToolbarItemValidator = bool Function(EditorState editorState);
typedef ToolbarItemHighlightCallback = bool Function(EditorState editorState);

class ToolbarItem {
  ToolbarItem({
    required this.id,
    required this.type,
    required this.iconBuilder,
    this.tooltipsMessage = '',
    required this.validator,
    required this.highlightCallback,
    required this.handler,
  });

  final String id;
  final int type;
  final Widget Function(bool isHighlight) iconBuilder;
  final String tooltipsMessage;
  final ToolbarItemValidator validator;
  final ToolbarItemEventHandler handler;
  final ToolbarItemHighlightCallback highlightCallback;

  factory ToolbarItem.divider() {
    return ToolbarItem(
      id: 'divider',
      type: -1,
      iconBuilder: (_) => const FlowySvg(name: 'toolbar/divider'),
      validator: (editorState) => true,
      handler: (editorState, context) {},
      highlightCallback: (editorState) => false,
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
    tooltipsMessage: AppFlowyEditorLocalizations.current.heading1,
    iconBuilder: (isHighlight) => FlowySvg(
      name: 'toolbar/h1',
      color: isHighlight ? Colors.lightBlue : null,
    ),
    validator: _onlyShowInSingleTextSelection,
    highlightCallback: (editorState) => _allSatisfy(
      editorState,
      BuiltInAttributeKey.heading,
      (value) => value == BuiltInAttributeKey.h1,
    ),
    handler: (editorState, context) =>
        formatHeading(editorState, BuiltInAttributeKey.h1),
  ),
  ToolbarItem(
    id: 'appflowy.toolbar.h2',
    type: 1,
    tooltipsMessage: AppFlowyEditorLocalizations.current.heading2,
    iconBuilder: (isHighlight) => FlowySvg(
      name: 'toolbar/h2',
      color: isHighlight ? Colors.lightBlue : null,
    ),
    validator: _onlyShowInSingleTextSelection,
    highlightCallback: (editorState) => _allSatisfy(
      editorState,
      BuiltInAttributeKey.heading,
      (value) => value == BuiltInAttributeKey.h2,
    ),
    handler: (editorState, context) =>
        formatHeading(editorState, BuiltInAttributeKey.h2),
  ),
  ToolbarItem(
    id: 'appflowy.toolbar.h3',
    type: 1,
    tooltipsMessage: AppFlowyEditorLocalizations.current.heading3,
    iconBuilder: (isHighlight) => FlowySvg(
      name: 'toolbar/h3',
      color: isHighlight ? Colors.lightBlue : null,
    ),
    validator: _onlyShowInSingleTextSelection,
    highlightCallback: (editorState) => _allSatisfy(
      editorState,
      BuiltInAttributeKey.heading,
      (value) => value == BuiltInAttributeKey.h3,
    ),
    handler: (editorState, context) =>
        formatHeading(editorState, BuiltInAttributeKey.h3),
  ),
  ToolbarItem(
    id: 'appflowy.toolbar.bold',
    type: 2,
    tooltipsMessage: AppFlowyEditorLocalizations.current.bold,
    iconBuilder: (isHighlight) => FlowySvg(
      name: 'toolbar/bold',
      color: isHighlight ? Colors.lightBlue : null,
    ),
    validator: _showInBuiltInTextSelection,
    highlightCallback: (editorState) => _allSatisfy(
      editorState,
      BuiltInAttributeKey.bold,
      (value) => value == true,
    ),
    handler: (editorState, context) => formatBold(editorState),
  ),
  ToolbarItem(
    id: 'appflowy.toolbar.italic',
    type: 2,
    tooltipsMessage: AppFlowyEditorLocalizations.current.italic,
    iconBuilder: (isHighlight) => FlowySvg(
      name: 'toolbar/italic',
      color: isHighlight ? Colors.lightBlue : null,
    ),
    validator: _showInBuiltInTextSelection,
    highlightCallback: (editorState) => _allSatisfy(
      editorState,
      BuiltInAttributeKey.italic,
      (value) => value == true,
    ),
    handler: (editorState, context) => formatItalic(editorState),
  ),
  ToolbarItem(
    id: 'appflowy.toolbar.underline',
    type: 2,
    tooltipsMessage: AppFlowyEditorLocalizations.current.underline,
    iconBuilder: (isHighlight) => FlowySvg(
      name: 'toolbar/underline',
      color: isHighlight ? Colors.lightBlue : null,
    ),
    validator: _showInBuiltInTextSelection,
    highlightCallback: (editorState) => _allSatisfy(
      editorState,
      BuiltInAttributeKey.underline,
      (value) => value == true,
    ),
    handler: (editorState, context) => formatUnderline(editorState),
  ),
  ToolbarItem(
    id: 'appflowy.toolbar.strikethrough',
    type: 2,
    tooltipsMessage: AppFlowyEditorLocalizations.current.strikethrough,
    iconBuilder: (isHighlight) => FlowySvg(
      name: 'toolbar/strikethrough',
      color: isHighlight ? Colors.lightBlue : null,
    ),
    validator: _showInBuiltInTextSelection,
    highlightCallback: (editorState) => _allSatisfy(
      editorState,
      BuiltInAttributeKey.strikethrough,
      (value) => value == true,
    ),
    handler: (editorState, context) => formatStrikethrough(editorState),
  ),
  ToolbarItem(
    id: 'appflowy.toolbar.code',
    type: 2,
    tooltipsMessage: AppFlowyEditorLocalizations.current.embedCode,
    iconBuilder: (isHighlight) => FlowySvg(
      name: 'toolbar/code',
      color: isHighlight ? Colors.lightBlue : null,
    ),
    validator: _showInBuiltInTextSelection,
    highlightCallback: (editorState) => _allSatisfy(
      editorState,
      BuiltInAttributeKey.code,
      (value) => value == true,
    ),
    handler: (editorState, context) => formatEmbedCode(editorState),
  ),
  ToolbarItem(
    id: 'appflowy.toolbar.quote',
    type: 3,
    tooltipsMessage: AppFlowyEditorLocalizations.current.quote,
    iconBuilder: (isHighlight) => FlowySvg(
      name: 'toolbar/quote',
      color: isHighlight ? Colors.lightBlue : null,
    ),
    validator: _onlyShowInSingleTextSelection,
    highlightCallback: (editorState) => _allSatisfy(
      editorState,
      BuiltInAttributeKey.subtype,
      (value) => value == BuiltInAttributeKey.quote,
    ),
    handler: (editorState, context) => formatQuote(editorState),
  ),
  ToolbarItem(
    id: 'appflowy.toolbar.bulleted_list',
    type: 3,
    tooltipsMessage: AppFlowyEditorLocalizations.current.bulletedList,
    iconBuilder: (isHighlight) => FlowySvg(
      name: 'toolbar/bulleted_list',
      color: isHighlight ? Colors.lightBlue : null,
    ),
    validator: _onlyShowInSingleTextSelection,
    highlightCallback: (editorState) => _allSatisfy(
      editorState,
      BuiltInAttributeKey.subtype,
      (value) => value == BuiltInAttributeKey.bulletedList,
    ),
    handler: (editorState, context) => formatBulletedList(editorState),
  ),
  ToolbarItem(
    id: 'appflowy.toolbar.link',
    type: 4,
    tooltipsMessage: AppFlowyEditorLocalizations.current.link,
    iconBuilder: (isHighlight) => FlowySvg(
      name: 'toolbar/link',
      color: isHighlight ? Colors.lightBlue : null,
    ),
    validator: _onlyShowInSingleTextSelection,
    highlightCallback: (editorState) => _allSatisfy(
      editorState,
      BuiltInAttributeKey.href,
      (value) => value != null,
    ),
    handler: (editorState, context) => showLinkMenu(context, editorState),
  ),
  ToolbarItem(
    id: 'appflowy.toolbar.highlight',
    type: 4,
    tooltipsMessage: AppFlowyEditorLocalizations.current.highlight,
    iconBuilder: (isHighlight) => FlowySvg(
      name: 'toolbar/highlight',
      color: isHighlight ? Colors.lightBlue : null,
    ),
    validator: _showInBuiltInTextSelection,
    highlightCallback: (editorState) => _allSatisfy(
      editorState,
      BuiltInAttributeKey.backgroundColor,
      (value) => value != null,
    ),
    handler: (editorState, context) => formatHighlight(
      editorState,
      editorState.editorStyle.textStyle.highlightColorHex,
    ),
  ),
];

ToolbarItemValidator _onlyShowInSingleTextSelection = (editorState) {
  final result = _showInBuiltInTextSelection(editorState);
  if (!result) {
    return false;
  }
  final nodes = editorState.service.selectionService.currentSelectedNodes;
  return (nodes.length == 1 && nodes.first is TextNode);
};

ToolbarItemValidator _showInBuiltInTextSelection = (editorState) {
  final nodes = editorState.service.selectionService.currentSelectedNodes
      .whereType<TextNode>()
      .where(
        (textNode) =>
            BuiltInAttributeKey.globalStyleKeys.contains(textNode.subtype) ||
            textNode.subtype == null,
      );
  return nodes.isNotEmpty;
};

bool _allSatisfy(
  EditorState editorState,
  String styleKey,
  bool Function(dynamic value) test,
) {
  final selection = editorState.service.selectionService.currentSelection.value;
  return selection != null &&
      editorState.selectedTextNodes.allSatisfyInSelection(
        selection,
        styleKey,
        test,
      );
}

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
  final baseOffset =
      editorState.renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
  matchRect = matchRect.shift(-baseOffset);

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
    linkText = textNode.getAttributeInSelection<String>(
      selection,
      BuiltInAttributeKey.href,
    );
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
          onSubmitted: (text) async {
            await editorState.formatLinkInText(
              editorState,
              text,
              textNode: textNode,
            );
            _dismissLinkMenu();
          },
          onCopyLink: () {
            RichClipboard.setData(RichClipboardData(text: linkText));
            _dismissLinkMenu();
          },
          onRemoveLink: () {
            final transaction = editorState.transaction
              ..formatText(
                textNode,
                index,
                length,
                {BuiltInAttributeKey.href: null},
              );
            editorState.apply(transaction);
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
  editorState.service.keyboardService?.disable();
  editorState.service.selectionService.currentSelection
      .addListener(_dismissLinkMenu);
}

void _dismissLinkMenu() {
  // workaround: SelectionService has been released after hot reload.
  final isSelectionDisposed =
      _editorState?.service.selectionServiceKey.currentState == null;
  if (isSelectionDisposed) {
    return;
  }
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
