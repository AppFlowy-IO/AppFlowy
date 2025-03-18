import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/material.dart';

const _kLinkItemId = 'editor.link';

final customLinkItem = ToolbarItem(
  id: _kLinkItemId,
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
      onPressed: () => showLinkMenu(context, editorState, selection, isHref),
    );

    if (tooltipBuilder != null) {
      return tooltipBuilder(
        context,
        _kLinkItemId,
        AppFlowyEditorL10n.current.link,
        child,
      );
    }

    return child;
  },
);
