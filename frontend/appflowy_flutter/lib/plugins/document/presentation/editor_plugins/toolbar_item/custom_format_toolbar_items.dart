import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
// ignore: implementation_imports
import 'package:appflowy_editor/src/editor/toolbar/desktop/items/utils/tooltip_util.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/material.dart';

final List<ToolbarItem> customMarkdownFormatItems = [
  _FormatToolbarItem(
    id: 'bold',
    name: 'bold',
    svg: FlowySvgs.toolbar_bold_m,
  ),
  _FormatToolbarItem(
    id: 'underline',
    name: 'underline',
    svg: FlowySvgs.toolbar_underline_m,
  ),
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

            final child = FlowyIconButton(
              width: 36,
              height: 32,
              hoverColor: hoverColor,
              isSelected: isHighlight,
              icon: FlowySvg(
                svg,
                size: Size.square(20.0),
                color: Theme.of(context).iconTheme.color,
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
