import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
// ignore: implementation_imports
import 'package:appflowy_editor/src/editor/toolbar/desktop/items/utils/overlay_util.dart';
import 'package:flutter/material.dart';

class ColorPicker extends StatefulWidget {
  const ColorPicker({
    super.key,
    required this.title,
    required this.selectedColorHex,
    required this.onSubmittedColorHex,
    required this.colorOptions,
    this.resetText,
    this.customColorHex,
    this.resetIconName,
    this.showClearButton = false,
  });

  final String title;
  final String? selectedColorHex;
  final String? customColorHex;
  final void Function(String? color, bool isCustomColor) onSubmittedColorHex;
  final String? resetText;
  final String? resetIconName;
  final bool showClearButton;

  final List<ColorOption> colorOptions;

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  final TextEditingController _colorHexController = TextEditingController();
  final TextEditingController _colorOpacityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final selectedColorHex = widget.selectedColorHex,
        customColorHex = widget.customColorHex;
    _colorHexController.text =
        _extractColorHex(customColorHex ?? selectedColorHex) ?? 'FFFFFF';
    _colorOpacityController.text =
        _convertHexToOpacity(customColorHex ?? selectedColorHex) ?? '100';
  }

  @override
  Widget build(BuildContext context) {
    return basicOverlay(
      context,
      width: 300,
      height: 250,
      children: [
        EditorOverlayTitle(text: widget.title),
        const SizedBox(height: 6),
        widget.showClearButton &&
                widget.resetText != null &&
                widget.resetIconName != null
            ? ResetColorButton(
                resetText: widget.resetText!,
                resetIconName: widget.resetIconName!,
                onPressed: (color) =>
                    widget.onSubmittedColorHex.call(color, false),
              )
            : const SizedBox.shrink(),
        CustomColorItem(
          colorController: _colorHexController,
          opacityController: _colorOpacityController,
          onSubmittedColorHex: (color) =>
              widget.onSubmittedColorHex.call(color, true),
        ),
        _buildColorItems(
          widget.colorOptions,
          widget.selectedColorHex,
        ),
      ],
    );
  }

  Widget _buildColorItems(
    List<ColorOption> options,
    String? selectedColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: options
          .map((e) => _buildColorItem(e, e.colorHex == selectedColor))
          .toList(),
    );
  }

  Widget _buildColorItem(ColorOption option, bool isChecked) {
    return SizedBox(
      height: 36,
      child: TextButton.icon(
        onPressed: () {
          widget.onSubmittedColorHex(option.colorHex, false);
        },
        icon: SizedBox.square(
          dimension: 12,
          child: Container(
            decoration: BoxDecoration(
              color: option.colorHex.tryToColor(),
              shape: BoxShape.circle,
            ),
          ),
        ),
        style: buildOverlayButtonStyle(context),
        label: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                option.name,
                softWrap: false,
                maxLines: 1,
                overflow: TextOverflow.fade,
                style: TextStyle(
                  color: Theme.of(context).textTheme.labelLarge?.color,
                ),
              ),
            ),
            // checkbox
            if (isChecked) const FlowySvg(FlowySvgs.toolbar_check_m),
          ],
        ),
      ),
    );
  }

  String? _convertHexToOpacity(String? colorHex) {
    if (colorHex == null) return null;
    final opacityHex = colorHex.substring(2, 4);
    final opacity = int.parse(opacityHex, radix: 16) / 2.55;
    return opacity.toStringAsFixed(0);
  }

  String? _extractColorHex(String? colorHex) {
    if (colorHex == null) return null;
    return colorHex.substring(4);
  }
}

class ResetColorButton extends StatelessWidget {
  const ResetColorButton({
    super.key,
    required this.resetText,
    required this.resetIconName,
    required this.onPressed,
  });

  final Function(String? color) onPressed;
  final String resetText;
  final String resetIconName;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 32,
      child: TextButton.icon(
        onPressed: () => onPressed(null),
        icon: EditorSvg(
          name: resetIconName,
          width: 13,
          height: 13,
          color: Theme.of(context).iconTheme.color,
        ),
        label: Text(
          resetText,
          style: TextStyle(
            color: Theme.of(context).hintColor,
          ),
          textAlign: TextAlign.left,
        ),
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.hovered)) {
                return Theme.of(context).hoverColor;
              }
              return Colors.transparent;
            },
          ),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}

class CustomColorItem extends StatefulWidget {
  const CustomColorItem({
    super.key,
    required this.colorController,
    required this.opacityController,
    required this.onSubmittedColorHex,
  });

  final TextEditingController colorController;
  final TextEditingController opacityController;
  final void Function(String color) onSubmittedColorHex;

  @override
  State<CustomColorItem> createState() => _CustomColorItemState();
}

class _CustomColorItemState extends State<CustomColorItem> {
  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.only(left: 8),
      shape: Border.all(
        color: Colors.transparent,
      ), // remove the default border when it is expanded
      title: Row(
        children: [
          // color sample box
          SizedBox.square(
            dimension: 12,
            child: Container(
              decoration: BoxDecoration(
                color: Color(
                  int.tryParse(
                        _combineColorHexAndOpacity(
                          widget.colorController.text,
                          widget.opacityController.text,
                        ),
                      ) ??
                      0xFFFFFFFF,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppFlowyEditorL10n.current.customColor,
              style: Theme.of(context).textTheme.labelLarge,
              // same style as TextButton.icon
            ),
          ),
        ],
      ),
      children: [
        const SizedBox(height: 6),
        _customColorDetailsTextField(
          labelText: AppFlowyEditorL10n.current.hexValue,
          controller: widget.colorController,
          // update the color sample box when the text changes
          onChanged: (_) => setState(() {}),
          onSubmitted: _submitCustomColorHex,
        ),
        const SizedBox(height: 10),
        _customColorDetailsTextField(
          labelText: AppFlowyEditorL10n.current.opacity,
          controller: widget.opacityController,
          // update the color sample box when the text changes
          onChanged: (_) => setState(() {}),
          onSubmitted: _submitCustomColorHex,
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _customColorDetailsTextField({
    required String labelText,
    required TextEditingController controller,
    Function(String)? onChanged,
    Function(String)? onSubmitted,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 3),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
        style: Theme.of(context).textTheme.bodyMedium,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      ),
    );
  }

  String _combineColorHexAndOpacity(String colorHex, String opacity) {
    colorHex = _fixColorHex(colorHex);
    opacity = _fixOpacity(opacity);
    final opacityHex = (int.parse(opacity) * 2.55).round().toRadixString(16);
    return '0x$opacityHex$colorHex';
  }

  String _fixColorHex(String colorHex) {
    if (colorHex.length > 6) {
      colorHex = colorHex.substring(0, 6);
    }
    if (int.tryParse(colorHex, radix: 16) == null) {
      colorHex = 'FFFFFF';
    }
    return colorHex;
  }

  String _fixOpacity(String opacity) {
    // if opacity is 0 - 99, return it
    // otherwise return 100
    final RegExp regex = RegExp('^(0|[1-9][0-9]?)');
    if (regex.hasMatch(opacity)) {
      return opacity;
    } else {
      return '100';
    }
  }

  void _submitCustomColorHex(String value) {
    final String color = _combineColorHexAndOpacity(
      widget.colorController.text,
      widget.opacityController.text,
    );
    widget.onSubmittedColorHex(color);
  }
}
