import 'package:appflowy/util/color_to_hex_string.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/dialog/styled_dialogs.dart';
import 'package:flutter/material.dart';

class DocumentColorSettingButton extends StatelessWidget {
  const DocumentColorSettingButton({
    super.key,
    required this.currentColor,
    required this.previewWidgetBuilder,
    required this.dialogTitle,
    required this.onApply,
  });

  /// current color from backend
  final Color currentColor;

  /// Build a preview widget with the given color
  /// It shows both on the [DocumentColorSettingButton] and [_DocumentColorSettingDialog]
  final Widget Function(Color? color) previewWidgetBuilder;

  final String dialogTitle;

  final void Function(Color selectedColorOnDialog) onApply;

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      text: previewWidgetBuilder.call(currentColor),
      hoverColor: Theme.of(context).colorScheme.secondaryContainer,
      expandText: false,
      onTap: () => Dialogs.show(
        context,
        child: _DocumentColorSettingDialog(
          currentColor: currentColor,
          previewWidgetBuilder: previewWidgetBuilder,
          dialogTitle: dialogTitle,
          onApply: onApply,
        ),
      ),
    );
  }
}

class _DocumentColorSettingDialog extends StatefulWidget {
  const _DocumentColorSettingDialog({
    required this.currentColor,
    required this.previewWidgetBuilder,
    required this.dialogTitle,
    required this.onApply,
  });

  final Color currentColor;

  final Widget Function(Color?) previewWidgetBuilder;

  final String dialogTitle;

  final void Function(Color selectedColorOnDialog) onApply;

  @override
  State<_DocumentColorSettingDialog> createState() =>
      DocumentColorSettingDialogState();
}

class DocumentColorSettingDialogState
    extends State<_DocumentColorSettingDialog> {
  /// The color displayed in the dialog.
  /// It is `null` when the user didn't enter a valid color value.
  late Color? selectedColorOnDialog;
  late String currentColorHexString;
  late TextEditingController hexController;
  late TextEditingController opacityController;
  @override
  void initState() {
    super.initState();
    selectedColorOnDialog = widget.currentColor;
    currentColorHexString = widget.currentColor.toHexString();
    hexController = TextEditingController(
      text: _extractColorHex(currentColorHexString),
    );
    opacityController = TextEditingController(
      text: _convertHexToOpacity(currentColorHexString),
    );
  }

  @override
  Widget build(BuildContext context) {
    void updateSelectedColor() {
      setState(() {
        final colorValue = int.tryParse(
          _combineColorHexAndOpacity(
            hexController.text,
            opacityController.text,
          ),
        );
        selectedColorOnDialog = colorValue != null ? Color(colorValue) : null;
      });
    }

    return FlowyDialog(
      constraints: const BoxConstraints(maxWidth: 250, maxHeight: 250),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
        child: Column(
          children: [
            const Spacer(),
            FlowyText(widget.dialogTitle),
            const VSpace(16),
            SizedBox(
              height: 108,
              child: Row(
                children: [
                  const Spacer(),
                  // set color
                  SizedBox(
                    width: 100,
                    child: Column(
                      children: [
                        _ColorSettingTextField(
                          controller: hexController,
                          labelText: 'Hex value',
                          hintText: '6fc9e7',
                          onChanged: (_) => updateSelectedColor(),
                        ),
                        const VSpace(8),
                        _ColorSettingTextField(
                          controller: opacityController,
                          labelText: 'Opacity',
                          hintText: '50',
                          onChanged: (_) => updateSelectedColor(),
                        ),
                      ],
                    ),
                  ),
                  const HSpace(8),
                  // preview color
                  SizedBox(
                    width: 100,
                    child: Center(
                      child: widget.previewWidgetBuilder(
                        selectedColorOnDialog,
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            const VSpace(16),
            ElevatedButton(
              onPressed: () {
                if (selectedColorOnDialog != null &&
                    selectedColorOnDialog != widget.currentColor) {
                  widget.onApply.call(selectedColorOnDialog!);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Apply'),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _ColorSettingTextField extends StatelessWidget {
  const _ColorSettingTextField({
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String labelText;
  final String hintText;

  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
      style: Theme.of(context).textTheme.bodyMedium,
      onChanged: onChanged,
    );
  }
}

// same convert functions as in appflowy_editor
String? _extractColorHex(String? colorHex) {
  if (colorHex == null) return null;
  return colorHex.substring(4);
}

String? _convertHexToOpacity(String? colorHex) {
  if (colorHex == null) return null;
  final opacityHex = colorHex.substring(2, 4);
  final opacity = int.parse(opacityHex, radix: 16) / 2.55;
  return opacity.toStringAsFixed(0);
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
  final RegExp regex = RegExp('[a-zA-Z]');
  if (regex.hasMatch(opacity) ||
      int.parse(opacity) > 100 ||
      int.parse(opacity) < 0) {
    return '100';
  }
  return opacity;
}
