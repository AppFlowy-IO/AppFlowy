import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/dialog/styled_dialogs.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/util/color_to_hex_string.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_alert_dialog.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/utils/hex_opacity_string_extension.dart';

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

  void updateColor(Color color) {
    setState(() {
      hexController.text = ColorExtension(color).toHexString().extractHex();
      opacityController.text =
          ColorExtension(color).toHexString().extractOpacity();
    });
    updateSelectedColor();
  }

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
                onChanged: (_) => updateSelectedColor(),
                onFieldSubmitted: (_) => updateSelectedColor(),
                validator: (v) => validateHexValue(v, opacityController.text),
                suffixIcon: GestureDetector(
                  onTap: () => _showColorPickerDialog(
                    context: context,
                    currentColor: widget.currentColor,
                    updateColor: updateColor,
                  ),
                  child: const Icon(Icons.color_lens_rounded),
                ),
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

void _showColorPickerDialog({
  required BuildContext context,
  String? title,
  required Color currentColor,
  required void Function(Color) updateColor,
}) {
  const kColorCircleWidth = 46.0;
  const kColorCircleHeight = 46.0;
  const kColorCircleRadius = 23.0;
  const kColorOpacityThumbRadius = 23.0;
  const kDialogButtonPaddingHorizontal = 24.0;
  const kDialogButtonPaddingVertical = 12.0;
  const kColorsColumnSpacing = 3.0;
  final style = Theme.of(context);
  Color selectedColor = currentColor;

  void updated(Color color) {
    updateColor(color);
    Navigator.of(context).pop();
  }

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
        content: SingleChildScrollView(
          child: ColorPicker(
            width: kColorCircleWidth,
            height: kColorCircleHeight,
            borderRadius: kColorCircleRadius,
            enableOpacity: true,
            opacityThumbRadius: kColorOpacityThumbRadius,
            columnSpacing: kColorsColumnSpacing,
            enableTooltips: false,
            pickersEnabled: const {
              ColorPickerType.both: false,
              ColorPickerType.primary: true,
              ColorPickerType.accent: true,
              ColorPickerType.wheel: true,
            },
            subheading: Text(
              LocaleKeys.settings_appearance_documentSettings_colorShade.tr(),
              style: style.textTheme.labelLarge,
            ),
            opacitySubheading: Text(
              LocaleKeys.settings_appearance_documentSettings_opacity.tr(),
              style: style.textTheme.labelLarge,
            ),
            onColorChanged: (color) {
              selectedColor = color;
            },
          ),
        ),
        actionsPadding: const EdgeInsets.all(8),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 24,
                child: FlowyTextButton(
                  LocaleKeys.button_cancel.tr(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: kDialogButtonPaddingHorizontal,
                    vertical: kDialogButtonPaddingVertical,
                  ),
                  fontColor: AFThemeExtension.of(context).textColor,
                  fillColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  radius: Corners.s12Border,
                  onPressed: () => updated(currentColor),
                ),
              ),
              const HSpace(8),
              SizedBox(
                height: 48,
                child: FlowyTextButton(
                  LocaleKeys.button_done.tr(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: kDialogButtonPaddingHorizontal,
                    vertical: kDialogButtonPaddingVertical,
                  ),
                  radius: Corners.s12Border,
                  fontHoverColor: Colors.white,
                  fillColor: Theme.of(context).colorScheme.primary,
                  hoverColor: const Color(0xFF005483),
                  onPressed: () => updated(selectedColor),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}
