import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

Future<void> showTextColorAndBackgroundColorPicker(
  BuildContext context, {
  required EditorState editorState,
  required Selection selection,
}) async {
  await showMobileBottomSheet(
    context,
    showHeader: true,
    showCloseButton: true,
    showDivider: false,
    showDragHandle: true,
    barrierColor: Colors.transparent,
    backgroundColor: Colors.white,
    elevation: 20,
    title: LocaleKeys.grid_selectOption_colorPanelTitle.tr(),
    padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
    builder: (context) {
      return _TextColorAndBackgroundColor(
        editorState: editorState,
        selection: selection,
      );
    },
  );
  await editorState.updateSelectionWithReason(
    null,
    extraInfo: null,
  );
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
        widget.editorState.getDeltaAttributeValueInSelection(
      AppFlowyRichTextKeys.textColor,
      widget.selection,
    );
    final String? selectedBackgroundColor =
        widget.editorState.getDeltaAttributeValueInSelection(
      AppFlowyRichTextKeys.highlightColor,
      widget.selection,
    );
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
        _TextColors(
          selectedColor: selectedTextColor?.tryToColor(),
          onSelectedColor: (textColor) async {
            final hex = textColor.alpha == 0 ? null : textColor.toHex();
            await widget.editorState.formatDelta(
              widget.selection,
              {
                AppFlowyRichTextKeys.textColor: hex,
              },
              selectionExtraInfo: {
                disableFloatingToolbar: true,
                disableMobileToolbarKey: true,
              },
            );
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
        _BackgroundColors(
          selectedColor: selectedBackgroundColor?.tryToColor(),
          onSelectedColor: (backgroundColor) async {
            final hex =
                backgroundColor.alpha == 0 ? null : backgroundColor.toHex();
            await widget.editorState.formatDelta(
              widget.selection,
              {
                AppFlowyRichTextKeys.highlightColor: hex,
              },
              selectionExtraInfo: {
                disableFloatingToolbar: true,
                disableMobileToolbarKey: true,
              },
            );
            setState(() {});
          },
        ),
      ],
    );
  }
}

class _BackgroundColors extends StatelessWidget {
  _BackgroundColors({
    this.selectedColor,
    required this.onSelectedColor,
  });

  final Color? selectedColor;
  final void Function(Color color) onSelectedColor;

  final colors = [
    const Color(0x00FFFFFF),
    const Color(0xFFE8E0FF),
    const Color(0xFFFFE6FD),
    const Color(0xFFFFDAE6),
    const Color(0xFFFFEFE3),
    const Color(0xFFF5FFDC),
    const Color(0xFFDDFFD6),
    const Color(0xFFDEFFF1),
    const Color(0xFFE1FBFF),
    const Color(0xFFFFADAD),
    const Color(0xFFFFE088),
    const Color(0xFFA7DF4A),
    const Color(0xFFD4C0FF),
    const Color(0xFFFDB2FE),
    const Color(0xFFFFD18B),
    const Color(0xFFFFF176),
    const Color(0xFF71E6B4),
    const Color(0xFF80F1FF),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 6,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(
          6.0,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: Corners.s12Border,
          border: Border.all(
            color: isSelected
                ? const Color(0xff00C6F1)
                : Theme.of(context).dividerColor,
          ),
        ),
        alignment: Alignment.center,
        child: isSelected
            ? const FlowySvg(
                FlowySvgs.blue_check_s,
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
      crossAxisCount: 6,
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
        margin: const EdgeInsets.all(
          6.0,
        ),
        decoration: BoxDecoration(
          borderRadius: Corners.s12Border,
          border: Border.all(
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
