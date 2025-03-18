import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
// ignore: implementation_imports
import 'package:appflowy_editor/src/editor/toolbar/desktop/items/utils/tooltip_util.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/material.dart';

import 'custom_placeholder_toolbar_item.dart';

final List<ToolbarItem> customMarkdownFormatItems = [
  _FormatToolbarItem(
    id: 'bold',
    name: 'bold',
    svg: FlowySvgs.toolbar_bold_m,
  ),
  group1PaddingItem,
  _FormatToolbarItem(
    id: 'underline',
    name: 'underline',
    svg: FlowySvgs.toolbar_underline_m,
  ),
  group1PaddingItem,
  _FormatToolbarItem(
    id: 'italic',
    name: 'italic',
    svg: FlowySvgs.toolbar_inline_italic_m,
  ),
];

final ToolbarItem customInlineCodeItem = _FormatToolbarItem(
  id: 'code',
  name: 'code',
  svg: FlowySvgs.toolbar_inline_code_m,
  group: 2,
);

class _FormatToolbarItem extends ToolbarItem {
  _FormatToolbarItem({
    required String id,
    required String name,
    required FlowySvgData svg,
    super.group = 1,
  }) : super(
          id: 'editor.$id',
          isActive: showInAnyTextType,
          builder: (
            context,
            editorState,
            highlightColor,
            iconColor,
            tooltipBuilder,
          ) {
            final selection = editorState.selection!;
            final nodes = editorState.getNodesInSelection(selection);
            final isHighlight = nodes.allSatisfyInSelection(
              selection,
              (delta) =>
                  delta.isNotEmpty &&
                  delta.everyAttributes((attr) => attr[name] == true),
            );

            final hoverColor = isHighlight
                ? highlightColor
                : EditorStyleCustomizer.toolbarHoverColor(context);
            final isDark = Theme.of(context).brightness == Brightness.dark;

            final child = FlowyIconButton(
              width: 36,
              height: 32,
              hoverColor: hoverColor,
              isSelected: isHighlight,
              icon: FlowySvg(
                svg,
                size: Size.square(20.0),
                color: (isDark && isHighlight)
                    ? Color(0xFF282E3A)
                    : Theme.of(context).iconTheme.color,
              ),
              onPressed: () => editorState.toggleAttribute(name),
            );

            if (tooltipBuilder != null) {
              return tooltipBuilder(
                context,
                id,
                getTooltipText(id),
                child,
              );
            }
            return child;
          },
        );
}

String getTooltipText(String id) {
  switch (id) {
    case 'underline':
      return '${LocaleKeys.toolbar_underline.tr()}${shortcutTooltips('⌘ + U', 'CTRL + U', 'CTRL + U')}';
    case 'bold':
      return '${LocaleKeys.toolbar_bold.tr()}${shortcutTooltips('⌘ + B', 'CTRL + B', 'CTRL + B')}';
    case 'italic':
      return '${LocaleKeys.toolbar_italic.tr()}${shortcutTooltips('⌘ + I', 'CTRL + I', 'CTRL + I')}';
    case 'strikethrough':
      return '${LocaleKeys.toolbar_strike.tr()}${shortcutTooltips('⌘ + SHIFT + S', 'CTRL + SHIFT + S', 'CTRL + SHIFT + S')}';
    case 'code':
      return '${LocaleKeys.document_toolbar_inlineCode.tr()}${shortcutTooltips('⌘ + E', 'CTRL + E', 'CTRL + E')}';
    case 'align_left':
      return LocaleKeys.document_toolbar_alignLeft.tr();
    case 'align_center':
      return LocaleKeys.document_toolbar_alignCenter.tr();
    case 'align_right':
      return LocaleKeys.document_toolbar_alignRight.tr();
    default:
      return '';
  }
}
