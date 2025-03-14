import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

const _kHighlightColorItemId = 'editor.highlightColor';

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
    final child = FlowyIconButton(
      width: 36,
      height: 32,
      hoverColor: EditorStyleCustomizer.toolbarHoverColor(context),
      icon: FlowySvg(
        FlowySvgs.toolbar_text_highlight_m,
        size: Size.square(20.0),
        color: Theme.of(context).iconTheme.color,
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
          AppFlowyEditorL10n.current.textColor,
          child,
        ) ??
        child;
  }

  Widget buildPopoverContent() {
    String? highlightColorHex;

    final selection = editorState.selection!;
    final nodes = editorState.getNodesInSelection(selection);
    nodes.allSatisfyInSelection(selection, (delta) {
      if (delta.everyAttributes((attr) => attr.isEmpty)) {
        return false;
      }

      return delta.everyAttributes((attributes) {
        highlightColorHex = attributes[AppFlowyRichTextKeys.backgroundColor];
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
        selectedColorHex: highlightColorHex,
        colorOptions: generateHighlightColorOptions(),
        onSubmittedColorHex: (color) {
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
