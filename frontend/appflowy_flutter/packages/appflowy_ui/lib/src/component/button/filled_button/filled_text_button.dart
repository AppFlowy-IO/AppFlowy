import 'package:appflowy_ui/src/component/component.dart';
import 'package:appflowy_ui/src/theme/appflowy_theme.dart';
import 'package:flutter/material.dart';

class AFFilledTextButton extends AFBaseTextButton {
  const AFFilledTextButton({
    super.key,
    required super.text,
    required super.onTap,
    required super.backgroundColor,
    required super.textColor,
    super.size = AFButtonSize.m,
    super.padding,
    super.borderRadius,
    super.disabled = false,
    super.alignment,
    super.textStyle,
  });

  /// Primary text button.
  factory AFFilledTextButton.primary({
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
    return AFFilledTextButton(
      key: key,
      text: text,
      onTap: onTap,
      size: size,
      padding: padding,
      borderRadius: borderRadius,
      disabled: disabled,
      alignment: alignment,
      textStyle: textStyle,
      textColor: (context, isHovering, disabled) =>
          AppFlowyTheme.of(context).textColorScheme.onFill,
      backgroundColor: (context, isHovering, disabled) {
        if (disabled) {
          return AppFlowyTheme.of(context).fillColorScheme.primaryAlpha5;
        }
        if (isHovering) {
          return AppFlowyTheme.of(context).fillColorScheme.themeThickHover;
        }
        return AppFlowyTheme.of(context).fillColorScheme.themeThick;
      },
    );
  }

  /// Destructive text button.
  factory AFFilledTextButton.destructive({
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
    return AFFilledTextButton(
      key: key,
      text: text,
      onTap: onTap,
      size: size,
      padding: padding,
      borderRadius: borderRadius,
      disabled: disabled,
      alignment: alignment,
      textStyle: textStyle,
      textColor: (context, isHovering, disabled) =>
          AppFlowyTheme.of(context).textColorScheme.onFill,
      backgroundColor: (context, isHovering, disabled) {
        if (disabled) {
          return AppFlowyTheme.of(context).fillColorScheme.primaryAlpha5;
        }
        if (isHovering) {
          return AppFlowyTheme.of(context).fillColorScheme.errorThickHover;
        }
        return AppFlowyTheme.of(context).fillColorScheme.errorThick;
      },
    );
  }

  /// Disabled text button.
  factory AFFilledTextButton.disabled({
    Key? key,
    required String text,
    AFButtonSize size = AFButtonSize.m,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
    Alignment? alignment,
    TextStyle? textStyle,
  }) {
    return AFFilledTextButton(
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
          AppFlowyTheme.of(context).fillColorScheme.primaryAlpha5,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AFBaseButton(
      disabled: disabled,
      backgroundColor: backgroundColor,
      borderColor: (_, __, ___) => Colors.transparent,
      padding: padding ?? size.buildPadding(context),
      borderRadius: borderRadius ?? size.buildBorderRadius(context),
      onTap: onTap,
      builder: (context, isHovering, disabled) {
        final textColor = this.textColor?.call(context, isHovering, disabled) ??
            AppFlowyTheme.of(context).textColorScheme.onFill;
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
