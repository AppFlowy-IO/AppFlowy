import 'package:appflowy/theme/component/button/base.dart';
import 'package:appflowy/theme/component/button/filled_button.dart';
import 'package:appflowy/theme/theme.dart';
import 'package:flutter/material.dart';

class AFFilledTextButton extends StatelessWidget {
  const AFFilledTextButton._({
    super.key,
    required this.text,
    required this.onTap,
    required this.backgroundColor,
    required this.hoverColor,
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
      backgroundColor: (context) =>
          AppFlowyTheme.of(context).fillColorScheme.themeThick,
      hoverColor: (context) =>
          AppFlowyTheme.of(context).fillColorScheme.themeThickHover,
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
      backgroundColor: (context) =>
          AppFlowyTheme.of(context).fillColorScheme.errorThick,
      hoverColor: (context) =>
          AppFlowyTheme.of(context).fillColorScheme.errorThickHover,
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
      backgroundColor: (context) =>
          AppFlowyTheme.of(context).fillColorScheme.primaryAlpha5,
      hoverColor: (context) =>
          AppFlowyTheme.of(context).fillColorScheme.primaryAlpha5,
    );
  }

  final String text;
  final VoidCallback onTap;
  final AFButtonSize size;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color Function(BuildContext) backgroundColor;
  final Color Function(BuildContext) hoverColor;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return AFFilledButton(
      textColor: theme.textColorScheme.onFill,
      backgroundColor: backgroundColor(context),
      hoverColor: hoverColor(context),
      padding: padding ?? size.buildPadding(context),
      borderRadius: borderRadius ?? size.buildBorderRadius(context),
      onTap: onTap,
      child: Text(
        text,
        style: size.buildTextStyle(context),
      ),
    );
  }
}
