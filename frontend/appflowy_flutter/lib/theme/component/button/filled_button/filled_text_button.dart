import 'package:appflowy/theme/component/button/base_button/base.dart';
import 'package:appflowy/theme/component/button/base_button/base_button.dart';
import 'package:appflowy/theme/theme.dart';
import 'package:flutter/material.dart';

class AFFilledTextButton extends StatelessWidget {
  const AFFilledTextButton._({
    super.key,
    required this.text,
    required this.onTap,
    required this.backgroundColor,
    required this.textColor,
    this.size = AFButtonSize.m,
    this.padding,
    this.borderRadius,
  });

  /// Primary text button.
  factory AFFilledTextButton.primary({
    Key? key,
    required String text,
    required VoidCallback onTap,
    AFButtonSize size = AFButtonSize.m,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
  }) {
    return AFFilledTextButton._(
      key: key,
      text: text,
      onTap: onTap,
      size: size,
      padding: padding,
      borderRadius: borderRadius,
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
  }) {
    return AFFilledTextButton._(
      key: key,
      text: text,
      onTap: onTap,
      size: size,
      padding: padding,
      borderRadius: borderRadius,
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
  }) {
    return AFFilledTextButton._(
      key: key,
      text: text,
      onTap: () {},
      size: size,
      padding: padding,
      borderRadius: borderRadius,
      textColor: (context, isHovering, disabled) =>
          AppFlowyTheme.of(context).textColorScheme.tertiary,
      backgroundColor: (context, isHovering, disabled) =>
          AppFlowyTheme.of(context).fillColorScheme.primaryAlpha5,
    );
  }

  final String text;
  final VoidCallback onTap;
  final AFButtonSize size;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  final AFBaseButtonColorBuilder? textColor;
  final AFBaseButtonColorBuilder? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return AFBaseButton(
      backgroundColor: backgroundColor,
      borderColor: (_, __, ___) => Colors.transparent,
      padding: padding ?? size.buildPadding(context),
      borderRadius: borderRadius ?? size.buildBorderRadius(context),
      onTap: onTap,
      builder: (context, isHovering, disabled) {
        final textColor = this.textColor?.call(context, isHovering, disabled) ??
            AppFlowyTheme.of(context).textColorScheme.onFill;
        return Text(
          text,
          style: size.buildTextStyle(context).copyWith(
                color: textColor,
              ),
        );
      },
    );
  }
}
