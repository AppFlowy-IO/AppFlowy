import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

const _kHighlightColorItemId = 'editor.highlightColor';
String? _customHighlightColorHex;

final customHighlightColorItem = ToolbarItem(
  id: _kHighlightColorItemId,
  group: 1,
  isActive: showInAnyTextType,
  builder: (context, editorState, highlightColor, iconColor, tooltipBuilder) =>
      HighlightColorPickerWidget(
    editorState: editorState,
    tooltipBuilder: tooltipBuilder,
    highlightColor: highlightColor,
  ),
);

class HighlightColorPickerWidget extends StatefulWidget {
  const HighlightColorPickerWidget({
    super.key,
    required this.editorState,
    this.tooltipBuilder,
    required this.highlightColor,
  });

  final EditorState editorState;
  final ToolbarTooltipBuilder? tooltipBuilder;
  final Color highlightColor;

  @override
  State<HighlightColorPickerWidget> createState() =>
      _HighlightColorPickerWidgetState();
}

class _HighlightColorPickerWidgetState
    extends State<HighlightColorPickerWidget> {
  final popoverController = PopoverController();

  bool isSelected = false;

  EditorState get editorState => widget.editorState;

  Color get highlightColor => widget.highlightColor;

  @override
  void dispose() {
    super.dispose();
    popoverController.close();
  }

  @override
  Widget build(BuildContext context) {
    final selectionRectList = editorState.selectionRects();
    final top =
        selectionRectList.isEmpty ? 0.0 : selectionRectList.first.height;
    return AppFlowyPopover(
      controller: popoverController,
      direction: PopoverDirection.bottomWithLeftAligned,
      offset: Offset(0, top),
      onOpen: () => keepEditorFocusNotifier.increase(),
      onClose: () {
        setState(() {
          isSelected = false;
        });
        keepEditorFocusNotifier.decrease();
      },
      margin: EdgeInsets.zero,
      popupBuilder: (context) => buildPopoverContent(),
      child: buildChild(context),
    );
  }

  Widget buildChild(BuildContext context) {
    final iconColor = Theme.of(context).iconTheme.color;

    final child = FlowyIconButton(
      width: 36,
      height: 32,
      hoverColor: EditorStyleCustomizer.toolbarHoverColor(context),
      icon: SizedBox(
        width: 20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FlowySvg(
              FlowySvgs.toolbar_text_highlight_m,
              size: Size(20, 16),
              color: iconColor,
            ),
            buildColorfulDivider(iconColor),
          ],
        ),
      ),
      onPressed: () {
        setState(() {
          isSelected = true;
        });
        showPopover();
      },
    );

    return widget.tooltipBuilder?.call(
          context,
          _kHighlightColorItemId,
          AppFlowyEditorL10n.current.highlightColor,
          child,
        ) ??
        child;
  }

  Widget buildColorfulDivider(Color? iconColor) {
    final List<String> colors = [];
    final selection = editorState.selection!;
    final nodes = editorState.getNodesInSelection(selection);
    nodes.allSatisfyInSelection(selection, (delta) {
      if (delta.everyAttributes((attr) => attr.isEmpty)) {
        return false;
      }

      return delta.everyAttributes((attr) {
        final textColorHex = attr[AppFlowyRichTextKeys.backgroundColor];
        if (textColorHex != null) colors.add(textColorHex);
        return (textColorHex != null);
      });
    });

    final colorLength = colors.length;
    if (colors.isEmpty) {
      return Container(
        width: 20,
        height: 4,
        color: iconColor,
      );
    }
    return SizedBox(
      width: 20,
      height: 4,
      child: Row(
        children: List.generate(colorLength, (index) {
          final currentColor = int.tryParse(colors[index]);
          return Container(
            width: 20 / colorLength,
            height: 4,
            color: currentColor == null ? iconColor : Color(currentColor),
          );
        }),
      ),
    );
  }

  Widget buildPopoverContent() {
    final List<String> colors = [];

    final selection = editorState.selection!;
    final nodes = editorState.getNodesInSelection(selection);
    nodes.allSatisfyInSelection(selection, (delta) {
      if (delta.everyAttributes((attr) => attr.isEmpty)) {
        return false;
      }

      return delta.everyAttributes((attributes) {
        final highlightColorHex =
            attributes[AppFlowyRichTextKeys.backgroundColor];
        if (highlightColorHex != null) colors.add(highlightColorHex);
        return highlightColorHex != null;
      });
    });
    bool showClearButton = false;
    nodes.allSatisfyInSelection(selection, (delta) {
      if (!showClearButton) {
        showClearButton = delta.whereType<TextInsert>().any(
          (element) {
            return element.attributes?[AppFlowyRichTextKeys.backgroundColor] !=
                null;
          },
        );
      }
      return true;
    });
    return MouseRegion(
      child: ColorPicker(
        title: AppFlowyEditorL10n.current.highlightColor,
        showClearButton: showClearButton,
        selectedColorHex: colors.length == 1 ? colors.first : null,
        customColorHex: _customHighlightColorHex,
        colorOptions: generateHighlightColorOptions(),
        onSubmittedColorHex: (color, isCustomColor) {
          if (isCustomColor) {
            _customHighlightColorHex = color;
          }
          formatHighlightColor(
            editorState,
            editorState.selection,
            color,
            withUpdateSelection: true,
          );
          hidePopover();
        },
        resetText: AppFlowyEditorL10n.current.clearHighlightColor,
        resetIconName: 'clear_highlight_color',
      ),
    );
  }

  void showPopover() {
    keepEditorFocusNotifier.increase();
    popoverController.show();
  }

  void hidePopover() {
    popoverController.close();
    keepEditorFocusNotifier.decrease();
  }
}
