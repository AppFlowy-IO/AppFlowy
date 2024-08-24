import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';

enum SingleSettingsButtonType {
  primary,
  danger,
  highlight;

  bool get isPrimary => this == primary;
  bool get isDangerous => this == danger;
  bool get isHighlight => this == highlight;
}

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
    this.description,
    this.labelMaxLines,
    required this.buttonLabel,
    this.onPressed,
    this.buttonType = SingleSettingsButtonType.primary,
    this.fontSize = 14,
    this.fontWeight = FontWeight.normal,
    this.minWidth,
  });

  final String label;
  final String? description;
  final int? labelMaxLines;
  final String buttonLabel;

  /// The action to be performed when the button is pressed
  ///
  /// If null the button will be rendered as disabled.
  ///
  final VoidCallback? onPressed;

  final SingleSettingsButtonType buttonType;

  final double fontSize;
  final FontWeight fontWeight;
  final double? minWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Row(
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
                ],
              ),
              if (description != null) ...[
                const VSpace(4),
                Row(
                  children: [
                    Expanded(
                      child: FlowyText.regular(
                        description!,
                        fontSize: 11,
                        color: AFThemeExtension.of(context).secondaryTextColor,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const HSpace(24),
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: minWidth ?? 0.0,
            maxHeight: 32,
            minHeight: 32,
          ),
          child: FlowyTextButton(
            buttonLabel,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            fillColor: fillColor(context),
            radius: Corners.s8Border,
            hoverColor: hoverColor(context),
            fontColor: fontColor(context),
            textColor: fontColor(context),
            fontHoverColor: fontHoverColor(context),
            borderColor: borderColor(context),
            fontSize: 12,
            isDangerous: buttonType.isDangerous,
            onPressed: onPressed,
            lineHeight: 1.0,
          ),
        ),
      ],
    );
  }

  Color? fillColor(BuildContext context) {
    if (buttonType.isPrimary) {
      return Theme.of(context).colorScheme.primary;
    }
    return Colors.transparent;
  }

  Color? hoverColor(BuildContext context) {
    if (buttonType.isDangerous) {
      return Theme.of(context).colorScheme.error.withOpacity(0.1);
    }

    if (buttonType.isPrimary) {
      return Theme.of(context).colorScheme.primary.withOpacity(0.9);
    }

    if (buttonType.isHighlight) {
      return const Color(0xFF5C3699);
    }
    return null;
  }

  Color? fontColor(BuildContext context) {
    if (buttonType.isDangerous) {
      return Theme.of(context).colorScheme.error;
    }

    if (buttonType.isHighlight) {
      return const Color(0xFF5C3699);
    }

    return Theme.of(context).colorScheme.onPrimary;
  }

  Color? fontHoverColor(BuildContext context) {
    return Colors.white;
  }

  Color? borderColor(BuildContext context) {
    if (buttonType.isHighlight) {
      return const Color(0xFF5C3699);
    }

    return null;
  }
}
