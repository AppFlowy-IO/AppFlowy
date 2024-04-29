import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/util/color_to_hex_string.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/utils/hex_opacity_string_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/dialog/styled_dialogs.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';

// TODO(Mathias/Lucas): Do we need to find a place for this in settings=
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
      margin: const EdgeInsets.all(8),
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
  final _formKey = GlobalKey<FormState>(debugLabel: 'colorSettingForm');

  void updateSelectedColor() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        final colorValue = int.tryParse(
          hexController.text.combineHexWithOpacity(opacityController.text),
        );
        // colorValue has been validated in the _ColorSettingTextField for hex value and it won't be null as this point
        selectedColorOnDialog = Color(colorValue!);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    selectedColorOnDialog = widget.currentColor;
    currentColorHexString = widget.currentColor.toHexString();
    hexController = TextEditingController(
      text: currentColorHexString.extractHex(),
    );
    opacityController = TextEditingController(
      text: currentColorHexString.extractOpacity(),
    );
  }

  @override
  void dispose() {
    hexController.dispose();
    opacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlowyDialog(
      constraints: const BoxConstraints(maxWidth: 360, maxHeight: 320),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            FlowyText(widget.dialogTitle),
            const VSpace(8),
            SizedBox(
              width: 100,
              height: 40,
              child: Center(
                child: widget.previewWidgetBuilder(
                  selectedColorOnDialog,
                ),
              ),
            ),
            const VSpace(8),
            SizedBox(
              height: 160,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _ColorSettingTextField(
                      controller: hexController,
                      labelText: LocaleKeys.editor_hexValue.tr(),
                      hintText: '6fc9e7',
                      onFieldSubmitted: (_) => updateSelectedColor(),
                      validator: (hexValue) => validateHexValue(
                        hexValue,
                        opacityController.text,
                      ),
                    ),
                    const VSpace(8),
                    _ColorSettingTextField(
                      controller: opacityController,
                      labelText: LocaleKeys.editor_opacity.tr(),
                      hintText: '50',
                      onFieldSubmitted: (_) => updateSelectedColor(),
                      validator: (value) => validateOpacityValue(value),
                    ),
                  ],
                ),
              ),
            ),
            const VSpace(8),
            RoundedTextButton(
              title: LocaleKeys.settings_appearance_documentSettings_apply.tr(),
              width: 100,
              height: 30,
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  if (selectedColorOnDialog != null &&
                      selectedColorOnDialog != widget.currentColor) {
                    widget.onApply.call(selectedColorOnDialog!);
                  }
                } else {
                  // error message will be shown below the text field
                  return;
                }
                Navigator.of(context).pop();
              },
            ),
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
    required this.onFieldSubmitted,
    required this.validator,
  });

  final TextEditingController controller;
  final String labelText;
  final String hintText;

  final void Function(String) onFieldSubmitted;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context);
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: style.colorScheme.outline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: style.colorScheme.outline,
          ),
        ),
      ),
      style: style.textTheme.bodyMedium,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }
}

String? validateHexValue(
  String? hexValue,
  String opacityValue,
) {
  if (hexValue == null || hexValue.isEmpty) {
    return LocaleKeys.settings_appearance_documentSettings_hexEmptyError.tr();
  }
  if (hexValue.length != 6) {
    return LocaleKeys.settings_appearance_documentSettings_hexLengthError.tr();
  }

  if (validateOpacityValue(opacityValue) == null) {
    final colorValue =
        int.tryParse(hexValue.combineHexWithOpacity(opacityValue));

    if (colorValue == null) {
      return LocaleKeys.settings_appearance_documentSettings_hexInvalidError
          .tr();
    }
  }

  return null;
}

String? validateOpacityValue(String? value) {
  if (value == null || value.isEmpty) {
    return LocaleKeys.settings_appearance_documentSettings_opacityEmptyError
        .tr();
  }

  final opacityInt = int.tryParse(value);
  if (opacityInt == null || opacityInt > 100 || opacityInt <= 0) {
    return LocaleKeys.settings_appearance_documentSettings_opacityRangeError
        .tr();
  }
  return null;
}
