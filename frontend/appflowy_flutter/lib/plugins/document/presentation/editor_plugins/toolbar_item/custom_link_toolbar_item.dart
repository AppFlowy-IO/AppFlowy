import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/desktop_toolbar/desktop_floating_toolbar.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/desktop_toolbar/link/create_link_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/material.dart';

import 'toolbar_id_enum.dart';

const kIsPageLink = 'is_page_link';

final customLinkItem = ToolbarItem(
  id: ToolbarId.link.id,
  group: 4,
  isActive: onlyShowInSingleSelectionAndTextType,
  builder: (context, editorState, highlightColor, iconColor, tooltipBuilder) {
    final selection = editorState.selection!;
    final nodes = editorState.getNodesInSelection(selection);
    final isHref = nodes.allSatisfyInSelection(selection, (delta) {
      return delta.everyAttributes(
        (attributes) => attributes[AppFlowyRichTextKeys.href] != null,
      );
    });

    final hoverColor = isHref
        ? highlightColor
        : EditorStyleCustomizer.toolbarHoverColor(context);
    final toolbarDismissController = InheritedToolbar.of(context)?.controller;

    final child = FlowyIconButton(
      width: 36,
      height: 32,
      hoverColor: hoverColor,
      isSelected: isHref,
      icon: FlowySvg(
        FlowySvgs.toolbar_link_m,
        size: Size.square(20.0),
        color: Theme.of(context).iconTheme.color,
      ),
      onPressed: () {
        toolbarDismissController?.dismiss();
        if (isHref) {
          removeLink(editorState, selection, isHref);
        } else {
          _showLinkMenu(context, editorState, selection, isHref);
        }
      },
    );

    if (tooltipBuilder != null) {
      return tooltipBuilder(
        context,
        ToolbarId.highlightColor.id,
        AppFlowyEditorL10n.current.link,
        child,
      );
    }

    return child;
  },
);

void removeLink(
  EditorState editorState,
  Selection selection,
  bool isHref,
) {
  if (!isHref) return;
  final node = editorState.getNodeAtPath(selection.end.path);
  if (node == null) {
    return;
  }
  final index = selection.normalized.startIndex;
  final length = selection.length;
  final transaction = editorState.transaction
    ..formatText(
      node,
      index,
      length,
      {
        BuiltInAttributeKey.href: null,
        kIsPageLink: null,
      },
    );
  editorState.apply(transaction);
}

void _showLinkMenu(
  BuildContext context,
  EditorState editorState,
  Selection selection,
  bool isHref,
) {
  final (left, top, right, bottom, alignment) = _getPosition(editorState);

  final node = editorState.getNodeAtPath(selection.end.path);
  if (node == null) {
    return;
  }

  OverlayEntry? overlay;

  void dismissOverlay() {
    keepEditorFocusNotifier.decrease();
    overlay?.remove();
    overlay = null;
  }

  keepEditorFocusNotifier.increase();
  overlay = FullScreenOverlayEntry(
    top: top,
    bottom: bottom,
    left: left,
    right: right,
    dismissCallback: () => keepEditorFocusNotifier.decrease(),
    builder: (context) {
      return CreateLinkMenu(
        alignment: alignment,
        editorState: editorState,
        onSubmitted: (link, isPage) async {
          await editorState.formatDelta(selection, {
            BuiltInAttributeKey.href: link,
            kIsPageLink: isPage,
          });
          dismissOverlay();
        },
        onDismiss: dismissOverlay,
      );
    },
  ).build();

  Overlay.of(context, rootOverlay: true).insert(overlay!);
}

extension AttributeExtension on Attributes {
  bool get isPage {
    if (this[kIsPageLink] is bool) {
      return this[kIsPageLink];
    }
    return false;
  }
}

// get a proper position for link menu
(
  double? left,
  double? top,
  double? right,
  double? bottom,
  LinkMenuAlignment alignment,
) _getPosition(
  EditorState editorState,
) {
  final rect = editorState.selectionRects().first;
  const menuHeight = 222.0, menuWidth = 320.0;

  double? left, right, top, bottom;
  LinkMenuAlignment alignment = LinkMenuAlignment.topLeft;
  final editorOffset = editorState.renderBox!.localToGlobal(Offset.zero),
      editorSize = editorState.renderBox!.size;
  final editorBottom = editorSize.height + editorOffset.dy,
      editorRight = editorSize.width + editorOffset.dx;
  final overflowBottom = rect.bottom + menuHeight > editorBottom,
      overflowTop = rect.top - menuHeight < 0,
      overflowLeft = rect.left - menuWidth < 0,
      overflowRight = rect.right + menuWidth > editorRight;

  if (overflowTop && !overflowBottom) {
    /// show at bottom
    top = rect.bottom;
  } else if (overflowBottom && !overflowTop) {
    /// show at top
    bottom = editorBottom - rect.top;
  } else if (!overflowTop && !overflowBottom) {
    /// show at bottom
    top = rect.bottom;
  } else {
    top = 0;
  }

  if (overflowLeft && !overflowRight) {
    /// show at right
    left = rect.left;
  } else if (overflowRight && !overflowLeft) {
    /// show at left
    right = editorRight - rect.right;
  } else if (!overflowLeft && !overflowRight) {
    /// show at right
    left = rect.left;
  } else {
    left = 0;
  }

  if (left != null && top != null) {
    alignment = LinkMenuAlignment.bottomRight;
  } else if (left != null && bottom != null) {
    alignment = LinkMenuAlignment.topRight;
  } else if (right != null && top != null) {
    alignment = LinkMenuAlignment.bottomLeft;
  } else if (right != null && bottom != null) {
    alignment = LinkMenuAlignment.topLeft;
  }

  return (left, top, right, bottom, alignment);
}

enum LinkMenuAlignment {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

extension LinkMenuAlignmentExtension on LinkMenuAlignment {
  bool get isTop =>
      this == LinkMenuAlignment.topLeft || this == LinkMenuAlignment.topRight;
}
