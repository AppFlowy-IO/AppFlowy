import 'package:appflowy/theme/component/button/base.dart';
import 'package:appflowy/theme/theme.dart';
import 'package:flutter/material.dart';

class AFFilledPrimaryTextButton extends StatelessWidget {
  const AFFilledPrimaryTextButton({
    super.key,
    required this.text,
    required this.onTap,
    this.size = AFButtonSize.m,
  });

  final String text;
  final AFButtonSize size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return AFFilledButton(
      textColor: theme.textColorScheme.onFill,
      backgroundColor: theme.fillColorScheme.themeThick,
      hoverColor: theme.fillColorScheme.themeThickHover,
      padding: size.buildPadding(context),
      borderRadius: size.buildBorderRadius(context),
      onTap: onTap,
      child: Text(
        text,
        style: size.buildTextStyle(context),
      ),
    );
  }
}

class AFFilledDestructiveTextButton extends StatelessWidget {
  const AFFilledDestructiveTextButton({
    super.key,
    required this.text,
    required this.onTap,
    this.size = AFButtonSize.m,
  });

  final String text;
  final VoidCallback onTap;
  final AFButtonSize size;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return AFFilledButton(
      textColor: theme.textColorScheme.onFill,
      backgroundColor: theme.fillColorScheme.errorThick,
      hoverColor: theme.fillColorScheme.errorThickHover,
      padding: size.buildPadding(context),
      borderRadius: size.buildBorderRadius(context),
      onTap: onTap,
      child: Text(
        text,
        style: size.buildTextStyle(context),
      ),
    );
  }
}

class AFFilledButton extends StatelessWidget {
  const AFFilledButton({
    super.key,
    required this.onTap,
    required this.child,
    required this.padding,
    required this.borderRadius,
    this.backgroundColor,
    this.foregroundColor,
    this.disabledColor,
    this.textColor,
    this.textDisabledColor,
    this.hoverColor,
    this.disabled = false,
  });

  final VoidCallback? onTap;

  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? disabledColor;
  final Color? textColor;
  final Color? textDisabledColor;
  final Color? hoverColor;

  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool disabled;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: disabled ? disabledColor : backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: InkWell(
        onTap: disabled ? null : onTap,
        hoverColor: disabled ? null : hoverColor,
        child: Padding(
          padding: padding,
          child: Center(
            child: child,
          ),
        ),
      ),
    );
  }
}
