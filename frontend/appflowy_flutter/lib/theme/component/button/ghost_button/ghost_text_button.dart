import 'package:appflowy/theme/component/button/base_button/base.dart';
import 'package:appflowy/theme/component/button/base_button/base_button.dart';
import 'package:appflowy/theme/theme.dart';
import 'package:flutter/material.dart';

class AFGhostTextButton extends StatelessWidget {
  const AFGhostTextButton._({
    super.key,
    required this.text,
    required this.onTap,
    this.textColor,
    this.backgroundColor,
    this.size = AFButtonSize.m,
    this.padding,
    this.borderRadius,
  });

  /// Normal ghost text button.
  factory AFGhostTextButton.normal({
    Key? key,
    required String text,
    required VoidCallback onTap,
    AFButtonSize size = AFButtonSize.m,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
  }) {
    return AFGhostTextButton._(
      key: key,
      text: text,
      onTap: onTap,
      size: size,
      padding: padding,
      borderRadius: borderRadius,
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
  }) {
    return AFGhostTextButton._(
      key: key,
      text: text,
      onTap: () {},
      size: size,
      padding: padding,
      borderRadius: borderRadius,
      textColor: (context, isHovering, disabled) =>
          AppFlowyTheme.of(context).textColorScheme.tertiary,
      backgroundColor: (context, isHovering, disabled) =>
          AppFlowyTheme.of(context).fillColorScheme.transparent,
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
    final theme = AppFlowyTheme.of(context);

    return AFBaseButton(
      backgroundColor: backgroundColor,
      borderColor: (_, __, ___) => Colors.transparent,
      padding: padding ?? size.buildPadding(context),
      borderRadius: borderRadius ?? size.buildBorderRadius(context),
      onTap: onTap,
      builder: (context, isHovering, disabled) {
        final textColor = this.textColor?.call(context, isHovering, disabled) ??
            theme.textColorScheme.primary;
        return Center(
          child: Text(
            text,
            style: size.buildTextStyle(context).copyWith(
                  color: textColor,
                ),
          ),
        );
      },
    );
  }
}
