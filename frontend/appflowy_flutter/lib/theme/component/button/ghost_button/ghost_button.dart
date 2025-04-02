import 'package:appflowy/theme/component/button/base_button/base.dart';
import 'package:appflowy/theme/component/button/base_button/base_button.dart';
import 'package:appflowy/theme/theme.dart';
import 'package:flutter/material.dart';

typedef AFGhostButtonWidgetBuilder = Widget Function(
  BuildContext context,
  bool isHovering,
  bool disabled,
);

class AFGhostButton extends StatelessWidget {
  const AFGhostButton._({
    super.key,
    required this.onTap,
    required this.backgroundColor,
    required this.builder,
    this.size = AFButtonSize.m,
    this.padding,
    this.borderRadius,
  });

  /// Normal ghost button.
  factory AFGhostButton.normal({
    Key? key,
    required VoidCallback onTap,
    required AFGhostButtonWidgetBuilder builder,
    AFButtonSize size = AFButtonSize.m,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
  }) {
    return AFGhostButton._(
      key: key,
      builder: builder,
      onTap: onTap,
      size: size,
      padding: padding,
      borderRadius: borderRadius,
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
    );
  }

  /// Disabled ghost button.
  factory AFGhostButton.disabled({
    Key? key,
    required AFGhostButtonWidgetBuilder builder,
    AFButtonSize size = AFButtonSize.m,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
  }) {
    return AFGhostButton._(
      key: key,
      builder: builder,
      onTap: () {},
      size: size,
      padding: padding,
      borderRadius: borderRadius,
      backgroundColor: (context, isHovering, disabled) =>
          AppFlowyTheme.of(context).fillColorScheme.transparent,
    );
  }

  final VoidCallback onTap;
  final AFButtonSize size;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  final AFBaseButtonColorBuilder? backgroundColor;
  final AFGhostButtonWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return AFBaseButton(
      backgroundColor: backgroundColor,
      borderColor: (_, __, ___) => Colors.transparent,
      padding: padding ?? size.buildPadding(context),
      borderRadius: borderRadius ?? size.buildBorderRadius(context),
      onTap: onTap,
      builder: builder,
    );
  }
}
