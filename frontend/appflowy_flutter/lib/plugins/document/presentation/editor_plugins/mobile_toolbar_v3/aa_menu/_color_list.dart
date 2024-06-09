import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/font_colors.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/_get_selection_color.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/aa_menu/_toolbar_theme.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

const _count = 6;

Future<void> showTextColorAndBackgroundColorPicker(
  BuildContext context, {
  required EditorState editorState,
  required Selection selection,
}) async {
  final theme = ToolbarColorExtension.of(context);
  await showMobileBottomSheet(
    context,
    showHeader: true,
    showDragHandle: true,
    showDoneButton: true,
    barrierColor: Colors.transparent,
    backgroundColor: theme.toolbarMenuBackgroundColor,
    elevation: 20,
    title: LocaleKeys.grid_selectOption_colorPanelTitle.tr(),
    padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
    builder: (context) {
      return _TextColorAndBackgroundColor(
        editorState: editorState,
        selection: selection,
      );
    },
  );
  Future.delayed(const Duration(milliseconds: 100), () {
    // highlight the selected text again.
    editorState.updateSelectionWithReason(
      selection,
      extraInfo: {
        selectionExtraInfoDisableFloatingToolbar: true,
      },
    );
  });
}

class _TextColorAndBackgroundColor extends StatefulWidget {
  const _TextColorAndBackgroundColor({
    required this.editorState,
    required this.selection,
  });

  final EditorState editorState;
  final Selection selection;

  @override
  State<_TextColorAndBackgroundColor> createState() =>
      _TextColorAndBackgroundColorState();
}

class _TextColorAndBackgroundColorState
    extends State<_TextColorAndBackgroundColor> {
  @override
  Widget build(BuildContext context) {
    final String? selectedTextColor =
        widget.editorState.getSelectionColor(AppFlowyRichTextKeys.textColor);
    final String? selectedBackgroundColor = widget.editorState
        .getSelectionColor(AppFlowyRichTextKeys.backgroundColor);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: 20,
            left: 6.0,
          ),
          child: FlowyText(
            LocaleKeys.editor_textColor.tr(),
            fontSize: 14.0,
          ),
        ),
        const VSpace(6.0),
        _TextColors(
          selectedColor: selectedTextColor?.tryToColor(),
          onSelectedColor: (textColor) async {
            final hex = textColor.alpha == 0 ? null : textColor.toHex();
            final selection = widget.selection;
            if (selection.isCollapsed) {
              widget.editorState.updateToggledStyle(
                AppFlowyRichTextKeys.textColor,
                hex ?? '',
              );
            } else {
              await widget.editorState.formatDelta(
                widget.selection,
                {
                  AppFlowyRichTextKeys.textColor: hex,
                },
                selectionExtraInfo: {
                  selectionExtraInfoDisableFloatingToolbar: true,
                  selectionExtraInfoDisableMobileToolbarKey: true,
                  selectionExtraInfoDoNotAttachTextService: true,
                },
              );
            }
            setState(() {});
          },
        ),
        Padding(
          padding: const EdgeInsets.only(
            top: 18.0,
            left: 6.0,
          ),
          child: FlowyText(
            LocaleKeys.editor_backgroundColor.tr(),
            fontSize: 14.0,
          ),
        ),
        const VSpace(6.0),
        _BackgroundColors(
          selectedColor: selectedBackgroundColor?.tryToColor(),
          onSelectedColor: (backgroundColor) async {
            final hex =
                backgroundColor.alpha == 0 ? null : backgroundColor.toHex();
            final selection = widget.selection;
            if (selection.isCollapsed) {
              widget.editorState.updateToggledStyle(
                AppFlowyRichTextKeys.backgroundColor,
                hex ?? '',
              );
            } else {
              await widget.editorState.formatDelta(
                widget.selection,
                {
                  AppFlowyRichTextKeys.backgroundColor: hex,
                },
                selectionExtraInfo: {
                  selectionExtraInfoDisableFloatingToolbar: true,
                  selectionExtraInfoDisableMobileToolbarKey: true,
                  selectionExtraInfoDoNotAttachTextService: true,
                },
              );
            }
            setState(() {});
          },
        ),
      ],
    );
  }
}

class _BackgroundColors extends StatelessWidget {
  const _BackgroundColors({
    this.selectedColor,
    required this.onSelectedColor,
  });

  final Color? selectedColor;
  final void Function(Color color) onSelectedColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).brightness == Brightness.light
        ? EditorFontColors.lightColors
        : EditorFontColors.darkColors;
    return GridView.count(
      crossAxisCount: _count,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: colors.mapIndexed(
        (index, color) {
          return _BackgroundColorItem(
            color: color,
            isSelected:
                selectedColor == null ? index == 0 : selectedColor == color,
            onTap: () => onSelectedColor(color),
          );
        },
      ).toList(),
    );
  }
}

class _BackgroundColorItem extends StatelessWidget {
  const _BackgroundColorItem({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final VoidCallback onTap;
  final Color color;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = ToolbarColorExtension.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(6.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: Corners.s12Border,
          border: Border.all(
            width: isSelected ? 2.0 : 1.0,
            color: isSelected
                ? theme.toolbarMenuItemSelectedBackgroundColor
                : Theme.of(context).dividerColor,
          ),
        ),
        alignment: Alignment.center,
        child: isSelected
            ? const FlowySvg(
                FlowySvgs.m_blue_check_s,
                size: Size.square(28.0),
                blendMode: null,
              )
            : null,
      ),
    );
  }
}

class _TextColors extends StatelessWidget {
  _TextColors({
    this.selectedColor,
    required this.onSelectedColor,
  });

  final Color? selectedColor;
  final void Function(Color color) onSelectedColor;

  final colors = [
    const Color(0x00FFFFFF),
    const Color(0xFFDB3636),
    const Color(0xFFEA8F06),
    const Color(0xFF18A166),
    const Color(0xFF205EEE),
    const Color(0xFFC619C9),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: _count,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      children: colors.mapIndexed(
        (index, color) {
          return _TextColorItem(
            color: color,
            isSelected:
                selectedColor == null ? index == 0 : selectedColor == color,
            onTap: () => onSelectedColor(color),
          );
        },
      ).toList(),
    );
  }
}

class _TextColorItem extends StatelessWidget {
  const _TextColorItem({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final VoidCallback onTap;
  final Color color;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(6.0),
        decoration: BoxDecoration(
          borderRadius: Corners.s12Border,
          border: Border.all(
            width: isSelected ? 2.0 : 1.0,
            color: isSelected
                ? const Color(0xff00C6F1)
                : Theme.of(context).dividerColor,
          ),
        ),
        alignment: Alignment.center,
        child: FlowyText(
          'A',
          fontSize: 24,
          color: color.alpha == 0 ? null : color,
        ),
      ),
    );
  }
}
