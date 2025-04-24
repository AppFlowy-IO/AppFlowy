import 'package:appflowy_ui/src/component/component.dart';
import 'package:appflowy_ui/src/theme/appflowy_theme.dart';
import 'package:flutter/material.dart';

class AFGhostTextButton extends AFBaseTextButton {
  const AFGhostTextButton({
    super.key,
    required super.text,
    required super.onTap,
    super.textColor,
    super.backgroundColor,
    super.size = AFButtonSize.m,
    super.padding,
    super.borderRadius,
    super.disabled = false,
    super.alignment,
    super.textStyle,
  });

  /// Normal ghost text button.
  factory AFGhostTextButton.primary({
    Key? key,
    required String text,
    required VoidCallback onTap,
    AFButtonSize size = AFButtonSize.m,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
    bool disabled = false,
    Alignment? alignment,
    TextStyle? textStyle,
  }) {
    return AFGhostTextButton(
      key: key,
      text: text,
      onTap: onTap,
      size: size,
      padding: padding,
      borderRadius: borderRadius,
      disabled: disabled,
      alignment: alignment,
      textStyle: textStyle,
      backgroundColor: (context, isHovering, disabled) {
        final theme = AppFlowyTheme.of(context);
        if (isHovering) {
          return theme.fillColorScheme.primaryAlpha5;
        }
        return theme.fillColorScheme.transparent;
      },
      textColor: (context, isHovering, disabled) {
        final theme = AppFlowyTheme.of(context);
        if (disabled) {
          return theme.textColorScheme.tertiary;
        }
        if (isHovering) {
          return theme.textColorScheme.primary;
        }
        return theme.textColorScheme.primary;
      },
    );
  }

  /// Disabled ghost text button.
  factory AFGhostTextButton.disabled({
    Key? key,
    required String text,
    AFButtonSize size = AFButtonSize.m,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
    Alignment? alignment,
    TextStyle? textStyle,
  }) {
    return AFGhostTextButton(
      key: key,
      text: text,
      onTap: () {},
      size: size,
      padding: padding,
      borderRadius: borderRadius,
      disabled: true,
      alignment: alignment,
      textStyle: textStyle,
      textColor: (context, isHovering, disabled) =>
          AppFlowyTheme.of(context).textColorScheme.tertiary,
      backgroundColor: (context, isHovering, disabled) =>
          AppFlowyTheme.of(context).fillColorScheme.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return AFBaseButton(
      disabled: disabled,
      backgroundColor: backgroundColor,
      borderColor: (_, __, ___, ____) => Colors.transparent,
      padding: padding ?? size.buildPadding(context),
      borderRadius: borderRadius ?? size.buildBorderRadius(context),
      onTap: onTap,
      builder: (context, isHovering, disabled) {
        final textColor = this.textColor?.call(context, isHovering, disabled) ??
            theme.textColorScheme.primary;

        Widget child = Text(
          text,
          style: textStyle ??
              size.buildTextStyle(context).copyWith(color: textColor),
        );

        final alignment = this.alignment;
        if (alignment != null) {
          child = Align(
            alignment: alignment,
            child: child,
          );
        }

        return child;
      },
    );
  }
}
