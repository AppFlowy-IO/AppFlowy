import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/material.dart';

const _kHighlightColorItemId = 'editor.highlightColor';

final customHighlightColorItem = ToolbarItem(
  id: _kHighlightColorItemId,
  group: 1,
  isActive: onlyShowInTextType,
  builder: (context, editorState, highlightColor, iconColor, tooltipBuilder) {
    String? highlightColorHex;

    final selection = editorState.selection!;
    final nodes = editorState.getNodesInSelection(selection);
    final isHighlight = nodes.allSatisfyInSelection(selection, (delta) {
      if (delta.everyAttributes((attr) => attr.isEmpty)) {
        return false;
      }

      return delta.everyAttributes((attributes) {
        highlightColorHex = attributes[AppFlowyRichTextKeys.backgroundColor];
        return highlightColorHex != null;
      });
    });

    final child = FlowyIconButton(
      width: 36,
      height: 32,
      hoverColor: AFThemeExtension.of(context).toolbarHoverColor,
      icon: FlowySvg(
        FlowySvgs.toolbar_text_highlight_m,
        size: Size.square(20.0),
        color: isHighlight ? highlightColor : Theme.of(context).iconTheme.color,
      ),
      onPressed: () {
        bool showClearButton = false;
        nodes.allSatisfyInSelection(selection, (delta) {
          if (!showClearButton) {
            showClearButton = delta.whereType<TextInsert>().any(
              (element) {
                return element
                        .attributes?[AppFlowyRichTextKeys.backgroundColor] !=
                    null;
              },
            );
          }
          return true;
        });
        showColorMenu(
          context,
          editorState,
          selection,
          currentColorHex: highlightColorHex,
          isTextColor: false,
          showClearButton: showClearButton,
        );
      },
    );

    if (tooltipBuilder != null) {
      return tooltipBuilder(
        context,
        _kHighlightColorItemId,
        AppFlowyEditorL10n.current.highlightColor,
        child,
      );
    }

    return child;
  },
);
