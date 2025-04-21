import 'package:appflowy_ui/src/component/component.dart';
import 'package:appflowy_ui/src/theme/appflowy_theme.dart';
import 'package:flutter/material.dart';

typedef AFFilledButtonWidgetBuilder = Widget Function(
  BuildContext context,
  bool isHovering,
  bool disabled,
);

class AFFilledButton extends StatelessWidget {
  const AFFilledButton._({
    super.key,
    required this.builder,
    required this.onTap,
    required this.backgroundColor,
    this.size = AFButtonSize.m,
    this.padding,
    this.borderRadius,
    this.disabled = false,
  });

  /// Primary text button.
  factory AFFilledButton.primary({
    Key? key,
    required AFFilledButtonWidgetBuilder builder,
    required VoidCallback onTap,
    AFButtonSize size = AFButtonSize.m,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
    bool disabled = false,
  }) {
    return AFFilledButton._(
      key: key,
      builder: builder,
      onTap: onTap,
      size: size,
      padding: padding,
      borderRadius: borderRadius,
      disabled: disabled,
      backgroundColor: (context, isHovering, disabled) {
        if (disabled) {
          return AppFlowyTheme.of(context).fillColorScheme.contentHover;
        }
        if (isHovering) {
          return AppFlowyTheme.of(context).fillColorScheme.themeThickHover;
        }
        return AppFlowyTheme.of(context).fillColorScheme.themeThick;
      },
    );
  }

  /// Destructive text button.
  factory AFFilledButton.destructive({
    Key? key,
    required AFFilledButtonWidgetBuilder builder,
    required VoidCallback onTap,
    AFButtonSize size = AFButtonSize.m,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
    bool disabled = false,
  }) {
    return AFFilledButton._(
      key: key,
      builder: builder,
      onTap: onTap,
      size: size,
      padding: padding,
      borderRadius: borderRadius,
      disabled: disabled,
      backgroundColor: (context, isHovering, disabled) {
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
  factory AFFilledButton.disabled({
    Key? key,
    required AFFilledButtonWidgetBuilder builder,
    AFButtonSize size = AFButtonSize.m,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
    Color? backgroundColor,
  }) {
    return AFFilledButton._(
      key: key,
      builder: builder,
      onTap: () {},
      size: size,
      disabled: true,
      padding: padding,
      borderRadius: borderRadius,
      backgroundColor: (context, isHovering, disabled) =>
          backgroundColor ??
          AppFlowyTheme.of(context).fillColorScheme.contentHover,
    );
  }

  final VoidCallback onTap;
  final bool disabled;
  final AFButtonSize size;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  final AFBaseButtonColorBuilder? backgroundColor;
  final AFFilledButtonWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return AFBaseButton(
      disabled: disabled,
      backgroundColor: backgroundColor,
      borderColor: (_, __, ___, ____) => Colors.transparent,
      padding: padding ?? size.buildPadding(context),
      borderRadius: borderRadius ?? size.buildBorderRadius(context),
      onTap: onTap,
      builder: builder,
    );
  }
}
