import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/util/color_to_hex_string.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_alert_dialog.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/utils/hex_opacity_string_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/dialog/styled_dialogs.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    selectedColorOnDialog = widget.currentColor;
    currentColorHexString = ColorExtension(widget.currentColor).toHexString();
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
                onChanged: (_) => _updateSelectedColor(),
                onFieldSubmitted: (_) => _updateSelectedColor(),
                validator: (v) => validateHexValue(v, opacityController.text),
                suffixIcon: GestureDetector(
                  onTap: () => _showColorPickerDialog(
                    context: context,
                    currentColor: widget.currentColor,
                    updateColor: _updateColor,
                  ),
                  child: const Icon(Icons.color_lens_rounded),
                ),
              ),
              const VSpace(8),
              _ColorSettingTextField(
                controller: opacityController,
                labelText: LocaleKeys.editor_opacity.tr(),
                hintText: '50',
                onChanged: (_) => _updateSelectedColor(),
                onFieldSubmitted: (_) => _updateSelectedColor(),
                validator: (value) => validateOpacityValue(value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _updateSelectedColor() {
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

  void _updateColor(Color color) {
    setState(() {
      hexController.text = ColorExtension(color).toHexString().extractHex();
      opacityController.text =
          ColorExtension(color).toHexString().extractOpacity();
    });
    _updateSelectedColor();
  }
}

class _ColorSettingTextField extends StatelessWidget {
  const _ColorSettingTextField({
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.onFieldSubmitted,
    this.suffixIcon,
    this.onChanged,
    this.validator,
  });

  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final void Function(String) onFieldSubmitted;
  final Widget? suffixIcon;
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
        suffixIcon: suffixIcon,
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

const _kColorCircleWidth = 46.0;
const _kColorCircleHeight = 46.0;
const _kColorCircleRadius = 23.0;
const _kColorOpacityThumbRadius = 23.0;
const _kDialogButtonPaddingHorizontal = 24.0;
const _kDialogButtonPaddingVertical = 12.0;
const _kColorsColumnSpacing = 3.0;

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({
    required this.selectedColor,
    required this.onColorChanged,
  });

  final Color selectedColor;
  final void Function(Color) onColorChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: ColorPicker(
        width: _kColorCircleWidth,
        height: _kColorCircleHeight,
        borderRadius: _kColorCircleRadius,
        enableOpacity: true,
        opacityThumbRadius: _kColorOpacityThumbRadius,
        columnSpacing: _kColorsColumnSpacing,
        enableTooltips: false,
        pickersEnabled: const {
          ColorPickerType.both: false,
          ColorPickerType.primary: true,
          ColorPickerType.accent: true,
          ColorPickerType.wheel: true,
        },
        subheading: Text(
          LocaleKeys.settings_appearance_documentSettings_colorShade.tr(),
          style: theme.textTheme.labelLarge,
        ),
        opacitySubheading: Text(
          LocaleKeys.settings_appearance_documentSettings_opacity.tr(),
          style: theme.textTheme.labelLarge,
        ),
        onColorChanged: onColorChanged,
      ),
    );
  }
}

class _ColorPickerActions extends StatelessWidget {
  const _ColorPickerActions({
    required this.onReset,
    required this.onUpdate,
  });

  final VoidCallback onReset;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 24,
          child: FlowyTextButton(
            LocaleKeys.button_cancel.tr(),
            padding: const EdgeInsets.symmetric(
              horizontal: _kDialogButtonPaddingHorizontal,
              vertical: _kDialogButtonPaddingVertical,
            ),
            fontColor: AFThemeExtension.of(context).textColor,
            fillColor: Colors.transparent,
            hoverColor: Colors.transparent,
            radius: Corners.s12Border,
            onPressed: onReset,
          ),
        ),
        const HSpace(8),
        SizedBox(
          height: 48,
          child: FlowyTextButton(
            LocaleKeys.button_done.tr(),
            padding: const EdgeInsets.symmetric(
              horizontal: _kDialogButtonPaddingHorizontal,
              vertical: _kDialogButtonPaddingVertical,
            ),
            radius: Corners.s12Border,
            fontHoverColor: Colors.white,
            fillColor: Theme.of(context).colorScheme.primary,
            hoverColor: const Color(0xFF005483),
            onPressed: onUpdate,
          ),
        ),
      ],
    );
  }
}

void _showColorPickerDialog({
  required BuildContext context,
  String? title,
  required Color currentColor,
  required void Function(Color) updateColor,
}) {
  final style = Theme.of(context);
  Color selectedColor = currentColor;

  showDialog(
    context: context,
    barrierColor: const Color.fromARGB(128, 0, 0, 0),
    builder: (context) {
      return AlertDialog(
        icon: const Icon(Icons.palette),
        title: Text(
          title ??
              LocaleKeys.settings_appearance_documentSettings_pickColor.tr(),
          style: style.textTheme.titleLarge,
        ),
        content: _ColorPicker(
          selectedColor: selectedColor,
          onColorChanged: (color) => selectedColor = color,
        ),
        actionsPadding: const EdgeInsets.all(8),
        actions: [
          _ColorPickerActions(
            onReset: () {
              updateColor(currentColor);
              Navigator.of(context).pop();
            },
            onUpdate: () {
              updateColor(selectedColor);
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
