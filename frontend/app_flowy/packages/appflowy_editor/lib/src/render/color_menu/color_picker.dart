import 'package:appflowy_editor/src/infra/flowy_svg.dart';
import 'package:flutter/material.dart';

class ColorOption {
  const ColorOption({
    required this.colorHex,
    required this.name,
  });

  final String colorHex;
  final String name;
}

enum _ColorType {
  font,
  background,
}

class ColorPicker extends StatefulWidget {
  const ColorPicker({
    super.key,
    this.selectedFontColorHex,
    this.selectedBackgroundColorHex,
    required this.pickerBackgroundColor,
    required this.fontColorOptions,
    required this.backgroundColorOptions,
    required this.pickerItemHoverColor,
    required this.pickerItemTextColor,
    required this.onSubmittedbackgroundColorHex,
    required this.onSubmittedFontColorHex,
  });

  final String? selectedFontColorHex;
  final String? selectedBackgroundColorHex;
  final Color pickerBackgroundColor;
  final Color pickerItemHoverColor;
  final Color pickerItemTextColor;
  final void Function(String color) onSubmittedbackgroundColorHex;
  final void Function(String color) onSubmittedFontColorHex;

  final List<ColorOption> fontColorOptions;
  final List<ColorOption> backgroundColorOptions;

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.pickerBackgroundColor,
        boxShadow: [
          BoxShadow(
            blurRadius: 5,
            spreadRadius: 1,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
        borderRadius: BorderRadius.circular(6.0),
      ),
      height: 250,
      width: 220,
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // font color
              _buildHeader('font color'),
              // padding
              const SizedBox(height: 6),
              _buildColorItems(
                _ColorType.font,
                widget.fontColorOptions,
                widget.selectedFontColorHex,
              ),
              // background color
              const SizedBox(height: 6),
              _buildHeader('background color'),
              const SizedBox(height: 6),
              _buildColorItems(
                _ColorType.background,
                widget.backgroundColorOptions,
                widget.selectedBackgroundColorHex,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.grey,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildColorItems(
      _ColorType type, List<ColorOption> options, String? selectedColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: options
          .map((e) => _buildColorItem(type, e, e.colorHex == selectedColor))
          .toList(),
    );
  }

  Widget _buildColorItem(_ColorType type, ColorOption option, bool isChecked) {
    return SizedBox(
      height: 36,
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        hoverColor: widget.pickerItemHoverColor,
        onTap: () {
          if (type == _ColorType.font) {
            widget.onSubmittedFontColorHex(option.colorHex);
          } else if (type == _ColorType.background) {
            widget.onSubmittedbackgroundColorHex(option.colorHex);
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // padding
            const SizedBox(width: 6),
            // icon
            SizedBox.square(
              dimension: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: Color(int.tryParse(option.colorHex) ?? 0xFFFFFFFF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // padding
            const SizedBox(width: 10),
            // text
            Expanded(
              child: Text(
                option.name,
                style:
                    TextStyle(fontSize: 12, color: widget.pickerItemTextColor),
              ),
            ),
            // checkbox
            if (isChecked) const FlowySvg(name: 'checkmark'),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}
