import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/desktop_toolbar/color_picker.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide ColorPicker;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

const _kTextColorItemId = 'editor.textColor';
String? _customColorHex;

final customTextColorItem = ToolbarItem(
  id: _kTextColorItemId,
  group: 1,
  isActive: showInAnyTextType,
  builder: (context, editorState, highlightColor, iconColor, tooltipBuilder) =>
      TextColorPickerWidget(
    editorState: editorState,
    tooltipBuilder: tooltipBuilder,
    highlightColor: highlightColor,
  ),
);

class TextColorPickerWidget extends StatefulWidget {
  const TextColorPickerWidget({
    super.key,
    required this.editorState,
    this.tooltipBuilder,
    required this.highlightColor,
  });

  final EditorState editorState;
  final ToolbarTooltipBuilder? tooltipBuilder;
  final Color highlightColor;

  @override
  State<TextColorPickerWidget> createState() => _TextColorPickerWidgetState();
}

class _TextColorPickerWidgetState extends State<TextColorPickerWidget> {
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
              FlowySvgs.toolbar_text_color_m,
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
          _kTextColorItemId,
          AppFlowyEditorL10n.current.textColor,
          child,
        ) ??
        child;
  }

  Widget buildColorfulDivider(Color? iconColor) {
    final List<String> colors = [];
    final selection = editorState.selection!;
    final nodes = editorState.getNodesInSelection(selection);
    final isHighLight = nodes.allSatisfyInSelection(selection, (delta) {
      if (delta.everyAttributes((attr) => attr.isEmpty)) {
        return false;
      }

      return delta.everyAttributes((attr) {
        final textColorHex = attr[AppFlowyRichTextKeys.textColor];
        if (textColorHex != null) colors.add(textColorHex);
        return (textColorHex != null);
      });
    });

    final colorLength = colors.length;
    if (colors.isEmpty || !isHighLight) {
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
    bool showClearButton = false;
    final List<String> colors = [];
    final selection = editorState.selection!;
    final nodes = editorState.getNodesInSelection(selection);
    final isHighLight = nodes.allSatisfyInSelection(selection, (delta) {
      if (delta.everyAttributes((attr) => attr.isEmpty)) {
        return false;
      }

      return delta.everyAttributes((attr) {
        final textColorHex = attr[AppFlowyRichTextKeys.textColor];
        if (textColorHex != null) colors.add(textColorHex);
        return (textColorHex != null);
      });
    });
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
    return MouseRegion(
      child: ColorPicker(
        title: LocaleKeys.document_toolbar_textColor.tr(),
        showClearButton: showClearButton,
        selectedColorHex:
            (colors.length == 1 && isHighLight) ? colors.first : null,
        customColorHex: _customColorHex,
        colorOptions: generateTextColorOptions(),
        onSubmittedColorHex: (color, isCustomColor) {
          if (isCustomColor) {
            _customColorHex = color;
          }
          formatFontColor(
            editorState,
            editorState.selection,
            color,
            withUpdateSelection: true,
          );
          hidePopover();
        },
        resetText: AppFlowyEditorL10n.current.resetToDefaultColor,
        resetIconName: 'reset_text_color',
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
