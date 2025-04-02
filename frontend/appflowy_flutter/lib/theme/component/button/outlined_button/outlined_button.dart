import 'package:appflowy/theme/component/button/base_button/base.dart';
import 'package:appflowy/theme/component/button/base_button/base_button.dart';
import 'package:appflowy/theme/theme.dart';
import 'package:flutter/material.dart';

typedef AFOutlinedButtonWidgetBuilder = Widget Function(
  BuildContext context,
  bool isHovering,
  bool disabled,
);

class AFOutlinedButton extends StatelessWidget {
  const AFOutlinedButton._({
    super.key,
    required this.onTap,
    required this.builder,
    this.borderColor,
    this.backgroundColor,
    this.size = AFButtonSize.m,
    this.padding,
    this.borderRadius,
  });

  /// Normal outlined text button.
  factory AFOutlinedButton.normal({
    Key? key,
    required AFOutlinedButtonWidgetBuilder builder,
    required VoidCallback onTap,
    AFButtonSize size = AFButtonSize.m,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
  }) {
    return AFOutlinedButton._(
      key: key,
      onTap: onTap,
      size: size,
      padding: padding,
      borderRadius: borderRadius,
      borderColor: (context, isHovering, disabled) {
        final theme = AppFlowyTheme.of(context);
        if (disabled) {
          return theme.borderColorScheme.greyTertiary;
        }
        if (isHovering) {
          return theme.borderColorScheme.greyTertiaryHover;
        }
        return theme.borderColorScheme.greyTertiary;
      },
      backgroundColor: (context, isHovering, disabled) {
        final theme = AppFlowyTheme.of(context);
        if (disabled) {
          return theme.fillColorScheme.transparent;
        }
        if (isHovering) {
          return theme.fillColorScheme.primaryAlpha5;
        }
        return theme.fillColorScheme.transparent;
      },
      builder: builder,
    );
  }

  /// Destructive outlined text button.
  factory AFOutlinedButton.destructive({
    Key? key,
    required AFOutlinedButtonWidgetBuilder builder,
    required VoidCallback onTap,
    AFButtonSize size = AFButtonSize.m,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
  }) {
    return AFOutlinedButton._(
      key: key,
      onTap: onTap,
      size: size,
      padding: padding,
      borderRadius: borderRadius,
      borderColor: (context, isHovering, disabled) {
        final theme = AppFlowyTheme.of(context);
        if (disabled) {
          return theme.fillColorScheme.errorThick;
        }
        if (isHovering) {
          return theme.fillColorScheme.errorThickHover;
        }
        return theme.fillColorScheme.errorThick;
      },
      backgroundColor: (context, isHovering, disabled) {
        final theme = AppFlowyTheme.of(context);
        if (disabled) {
          return theme.fillColorScheme.errorThick;
        }
        if (isHovering) {
          return theme.fillColorScheme.errorThickHover;
        }
        return theme.fillColorScheme.errorThick;
      },
      builder: builder,
    );
  }

  /// Disabled outlined text button.
  factory AFOutlinedButton.disabled({
    Key? key,
    required AFOutlinedButtonWidgetBuilder builder,
    AFButtonSize size = AFButtonSize.m,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
  }) {
    return AFOutlinedButton._(
      key: key,
      onTap: () {},
      size: size,
      padding: padding,
      borderRadius: borderRadius,
      borderColor: (context, isHovering, disabled) {
        final theme = AppFlowyTheme.of(context);
        if (disabled) {
          return theme.borderColorScheme.greyTertiary;
        }
        if (isHovering) {
          return theme.borderColorScheme.greyTertiaryHover;
        }
        return theme.borderColorScheme.greyTertiary;
      },
      backgroundColor: (context, isHovering, disabled) {
        final theme = AppFlowyTheme.of(context);
        if (disabled) {
          return theme.fillColorScheme.transparent;
        }
        if (isHovering) {
          return theme.fillColorScheme.primaryAlpha5;
        }
        return theme.fillColorScheme.transparent;
      },
      builder: builder,
    );
  }

  final VoidCallback onTap;
  final AFButtonSize size;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  final AFBaseButtonColorBuilder? borderColor;
  final AFBaseButtonColorBuilder? backgroundColor;

  final AFOutlinedButtonWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return AFBaseButton(
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      padding: padding ?? size.buildPadding(context),
      borderRadius: borderRadius ?? size.buildBorderRadius(context),
      onTap: onTap,
      builder: builder,
    );
  }
}
