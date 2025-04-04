import 'package:appflowy_ui/src/component/component.dart';
import 'package:appflowy_ui/src/theme/appflowy_theme.dart';
import 'package:flutter/material.dart';

typedef AFGhostIconBuilder = Widget Function(
  BuildContext context,
  bool isHovering,
  bool disabled,
);

class AFGhostIconTextButton extends StatelessWidget {
  const AFGhostIconTextButton({
    super.key,
    required this.text,
    required this.onTap,
    required this.iconBuilder,
    this.textColor,
    this.backgroundColor,
    this.size = AFButtonSize.m,
    this.padding,
    this.borderRadius,
    this.disabled = false,
  });

  /// Primary ghost text button.
  factory AFGhostIconTextButton.primary({
    Key? key,
    required String text,
    required VoidCallback onTap,
    required AFGhostIconBuilder iconBuilder,
    AFButtonSize size = AFButtonSize.m,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
    bool disabled = false,
  }) {
    return AFGhostIconTextButton(
      key: key,
      text: text,
      onTap: onTap,
      iconBuilder: iconBuilder,
      size: size,
      padding: padding,
      borderRadius: borderRadius,
      disabled: disabled,
      backgroundColor: (context, isHovering, disabled) {
        final theme = AppFlowyTheme.of(context);
        if (disabled) {
          return Colors.transparent;
        }
        if (isHovering) {
          return theme.fillColorScheme.primaryAlpha5;
        }
        return Colors.transparent;
      },
      textColor: (context, isHovering, disabled) {
        final theme = AppFlowyTheme.of(context);
        if (disabled) {
          return theme.textColorScheme.tertiary;
        }
        return theme.textColorScheme.primary;
      },
    );
  }

  /// Disabled ghost text button.
  factory AFGhostIconTextButton.disabled({
    Key? key,
    required String text,
    required AFGhostIconBuilder iconBuilder,
    AFButtonSize size = AFButtonSize.m,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
  }) {
    return AFGhostIconTextButton(
      key: key,
      text: text,
      iconBuilder: iconBuilder,
      onTap: () {},
      size: size,
      padding: padding,
      borderRadius: borderRadius,
      disabled: true,
      backgroundColor: (context, isHovering, disabled) {
        return Colors.transparent;
      },
      textColor: (context, isHovering, disabled) {
        final theme = AppFlowyTheme.of(context);
        return theme.textColorScheme.tertiary;
      },
    );
  }

  final String text;
  final bool disabled;
  final VoidCallback onTap;
  final AFButtonSize size;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  final AFGhostIconBuilder iconBuilder;

  final AFBaseButtonColorBuilder? textColor;
  final AFBaseButtonColorBuilder? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return AFBaseButton(
      disabled: disabled,
      backgroundColor: backgroundColor,
      borderColor: (context, isHovering, disabled) {
        return Colors.transparent;
      },
      padding: padding ?? size.buildPadding(context),
      borderRadius: borderRadius ?? size.buildBorderRadius(context),
      onTap: onTap,
      builder: (context, isHovering, disabled) {
        final textColor = this.textColor?.call(context, isHovering, disabled) ??
            theme.textColorScheme.primary;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconBuilder(
              context,
              isHovering,
              disabled,
            ),
            SizedBox(width: theme.spacing.m),
            Text(
              text,
              style: size.buildTextStyle(context).copyWith(
                    color: textColor,
                  ),
            ),
          ],
        );
      },
    );
  }
}
