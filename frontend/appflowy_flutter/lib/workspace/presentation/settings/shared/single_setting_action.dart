import 'package:flutter/material.dart';

import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';

/// This is used to describe a single setting action
///
/// This will render a simple action that takes the title,
/// the button label, and the button action.
///
/// _Note: The label can overflow and will be ellipsized,
/// unless maxLines is overriden._
///
class SingleSettingAction extends StatelessWidget {
  const SingleSettingAction({
    super.key,
    required this.label,
    this.labelMaxLines,
    required this.buttonLabel,
    this.onPressed,
    this.isDangerous = false,
    this.fontSize = 14,
    this.fontWeight = FontWeight.normal,
  });

  final String label;
  final int? labelMaxLines;
  final String buttonLabel;

  /// The action to be performed when the button is pressed
  ///
  /// If null the button will be rendered as disabled.
  ///
  final VoidCallback? onPressed;

  /// If isDangerous is true, the button will be rendered as a dangerous
  /// action, with a red outline.
  ///
  final bool isDangerous;

  final double fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FlowyText(
            label,
            fontSize: fontSize,
            fontWeight: fontWeight,
            maxLines: labelMaxLines,
            overflow: TextOverflow.ellipsis,
            color: AFThemeExtension.of(context).secondaryTextColor,
          ),
        ),
        const HSpace(24),
        SizedBox(
          height: 32,
          child: FlowyTextButton(
            buttonLabel,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            fillColor:
                isDangerous ? null : Theme.of(context).colorScheme.primary,
            hoverColor: isDangerous ? null : const Color(0xFF005483),
            fontColor: isDangerous ? Theme.of(context).colorScheme.error : null,
            fontHoverColor: Colors.white,
            fontSize: 12,
            isDangerous: isDangerous,
            onPressed: onPressed,
          ),
        ),
      ],
    );
  }
}
