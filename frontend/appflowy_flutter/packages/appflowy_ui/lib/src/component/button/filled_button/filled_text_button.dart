import 'package:appflowy_ui/src/component/component.dart';
import 'package:appflowy_ui/src/theme/appflowy_theme.dart';
import 'package:flutter/material.dart';

class AFFilledTextButton extends AFBaseTextButton {
  const AFFilledTextButton({
    super.key,
    required super.text,
    required super.onTap,
    super.showFocusRing,
    super.backgroundFocusColor,
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
    bool showFocusRing = false,
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
      showFocusRing: showFocusRing,
      alignment: alignment,
      textStyle: textStyle,
      textColor: (context, isHovering, disabled) {
        if (disabled) {
          return AppFlowyTheme.of(context).textColorScheme.tertiary;
        }
        return AppFlowyTheme.of(context).textColorScheme.onFill;
      },
      backgroundFocusColor: (context, isHovering, isFocused, disabled) {
        if (disabled) {
          return AppFlowyTheme.of(context).fillColorScheme.contentHover;
        }
        if (isHovering || isFocused) {
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
    bool showFocusRing = false,
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
      showFocusRing: showFocusRing,
      alignment: alignment,
      textStyle: textStyle,
      textColor: (context, isHovering, disabled) {
        if (disabled) {
          return AppFlowyTheme.of(context).textColorScheme.tertiary;
        }
        return AppFlowyTheme.of(context).textColorScheme.onFill;
      },
      backgroundFocusColor: (context, isHovering, _, disabled) {
        if (disabled) {
          return AppFlowyTheme.of(context).fillColorScheme.contentHover;
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
      backgroundFocusColor: (context, isHovering, _, disabled) =>
          AppFlowyTheme.of(context).fillColorScheme.contentHover,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: 76,
      ),
      child: AFBaseButton(
        disabled: disabled,
        showFocusRing: showFocusRing,
        backgroundFocusColor: backgroundFocusColor,
        borderColor: (_, __, ___, ____) => Colors.transparent,
        padding: padding ?? size.buildPadding(context),
        borderRadius: borderRadius ?? size.buildBorderRadius(context),
        onTap: onTap,
        builder: (context, isHovering, disabled) {
          final textColor =
              this.textColor?.call(context, isHovering, disabled) ??
                  AppFlowyTheme.of(context).textColorScheme.onFill;
          Widget child = Text(
            text,
            style: textStyle ??
                size.buildTextStyle(context).copyWith(color: textColor),
            textAlign: TextAlign.center,
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
      ),
    );
  }
}
