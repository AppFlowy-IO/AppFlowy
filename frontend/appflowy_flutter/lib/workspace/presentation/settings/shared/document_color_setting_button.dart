import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/util/color_to_hex_string.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_alert_dialog.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/utils/hex_opacity_string_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/dialog/styled_dialogs.dart';

class DocumentColorSettingButton extends StatefulWidget {
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
  State<DocumentColorSettingButton> createState() =>
      _DocumentColorSettingButtonState();
}

class _DocumentColorSettingButtonState
    extends State<DocumentColorSettingButton> {
  late Color newColor = widget.currentColor;

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      margin: const EdgeInsets.all(8),
      text: widget.previewWidgetBuilder.call(widget.currentColor),
      hoverColor: Theme.of(context).colorScheme.secondaryContainer,
      expandText: false,
      onTap: () => SettingsAlertDialog(
        title: widget.dialogTitle,
        confirm: () {
          widget.onApply(newColor);
          Navigator.of(context).pop();
        },
        children: [
          _DocumentColorSettingDialog(
            formKey: GlobalKey<FormState>(),
            currentColor: widget.currentColor,
            previewWidgetBuilder: widget.previewWidgetBuilder,
            onChanged: (color) => newColor = color,
          ),
        ],
      ).show(context),
    );
  }
}

class _DocumentColorSettingDialog extends StatefulWidget {
  const _DocumentColorSettingDialog({
    required this.formKey,
    required this.currentColor,
    required this.previewWidgetBuilder,
    required this.onChanged,
  });

  final GlobalKey<FormState> formKey;
  final Color currentColor;
  final Widget Function(Color?) previewWidgetBuilder;
  final void Function(Color selectedColor) onChanged;

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

  void updateSelectedColor() {
    if (widget.formKey.currentState!.validate()) {
      setState(() {
        final colorValue = int.tryParse(
          hexController.text.combineHexWithOpacity(opacityController.text),
        );
        // colorValue has been validated in the _ColorSettingTextField for hex value and it won't be null as this point
        selectedColorOnDialog = Color(colorValue!);
        widget.onChanged(selectedColorOnDialog!);
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
    return Column(
      children: [
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
        Form(
          key: widget.formKey,
          child: Column(
            children: [
              _ColorSettingTextField(
                controller: hexController,
                labelText: LocaleKeys.editor_hexValue.tr(),
                hintText: '6fc9e7',
                onChanged: (_) => updateSelectedColor(),
                onFieldSubmitted: (_) => updateSelectedColor(),
                validator: (v) => validateHexValue(v, opacityController.text),
              ),
              const VSpace(8),
              _ColorSettingTextField(
                controller: opacityController,
                labelText: LocaleKeys.editor_opacity.tr(),
                hintText: '50',
                onChanged: (_) => updateSelectedColor(),
                onFieldSubmitted: (_) => updateSelectedColor(),
                validator: (value) => validateOpacityValue(value),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ColorSettingTextField extends StatelessWidget {
  const _ColorSettingTextField({
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.onFieldSubmitted,
    this.onChanged,
    this.validator,
  });

  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final void Function(String) onFieldSubmitted;
  final void Function(String)? onChanged;
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
          borderSide: BorderSide(color: style.colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: style.colorScheme.outline),
        ),
      ),
      style: style.textTheme.bodyMedium,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }
}

String? validateHexValue(String? hexValue, String opacityValue) {
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
