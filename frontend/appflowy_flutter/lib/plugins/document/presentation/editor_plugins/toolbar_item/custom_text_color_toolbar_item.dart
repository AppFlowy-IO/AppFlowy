import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/material.dart';

const _kTextColorItemId = 'editor.textColor';

final customTextColorItem = ToolbarItem(
  id: _kTextColorItemId,
  group: 1,
  isActive: showInAnyTextType,
  builder: (context, editorState, highlightColor, iconColor, tooltipBuilder) {
    String? textColorHex;
    final selection = editorState.selection!;
    final nodes = editorState.getNodesInSelection(selection);
    final isHighlight = nodes.allSatisfyInSelection(selection, (delta) {
      if (delta.everyAttributes((attr) => attr.isEmpty)) {
        return false;
      }

      return delta.everyAttributes((attr) {
        textColorHex = attr[AppFlowyRichTextKeys.textColor];
        return (textColorHex != null);
      });
    });

    final child = FlowyIconButton(
      width: 36,
      height: 32,
      hoverColor: EditorStyleCustomizer.toolbarHoverColor(context),
      icon: FlowySvg(
        FlowySvgs.toolbar_text_color_m,
        size: Size.square(20.0),
        color: isHighlight ? highlightColor : Theme.of(context).iconTheme.color,
      ),
      onPressed: () {
        bool showClearButton = false;
        nodes.allSatisfyInSelection(
          selection,
          (delta) {
            if (!showClearButton) {
              showClearButton = delta.whereType<TextInsert>().any(
                (element) {
                  return element.attributes?[AppFlowyRichTextKeys.textColor] !=
                      null;
                },
              );
            }
            return true;
          },
        );
        showColorMenu(
          context,
          editorState,
          selection,
          currentColorHex: textColorHex,
          isTextColor: true,
          showClearButton: showClearButton,
        );
      },
    );

    if (tooltipBuilder != null) {
      return tooltipBuilder(
        context,
        _kTextColorItemId,
        AppFlowyEditorL10n.current.textColor,
        child,
      );
    }

    return child;
  },
);
