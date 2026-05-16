import 'package:appflowy_ui/src/component/component.dart';
import 'package:appflowy_ui/src/theme/appflowy_theme.dart';
import 'package:flutter/material.dart';

typedef AFFilledIconBuilder = Widget Function(
  BuildContext context,
  bool isHovering,
  bool disabled,
);

class AFFilledIconTextButton extends StatelessWidget {
  const AFFilledIconTextButton._({
    super.key,
    required this.text,
    required this.onTap,
    required this.iconBuilder,
    this.textColor,
    this.backgroundColor,
    this.size = AFButtonSize.m,
    this.padding,
    this.borderRadius,
  });

  /// Primary filled text button.
  factory AFFilledIconTextButton.primary({
    Key? key,
    required String text,
    required VoidCallback onTap,
    required AFFilledIconBuilder iconBuilder,
    AFButtonSize size = AFButtonSize.m,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
  }) {
    return AFFilledIconTextButton._(
      key: key,
      text: text,
      onTap: onTap,
      iconBuilder: iconBuilder,
      size: size,
      padding: padding,
      borderRadius: borderRadius,
      backgroundColor: (context, isHovering, disabled) {
        final theme = AppFlowyTheme.of(context);
        if (disabled) {
          return theme.fillColorScheme.tertiary;
        }
        if (isHovering) {
          return theme.fillColorScheme.themeThickHover;
        }
        return theme.fillColorScheme.themeThick;
      },
      textColor: (context, isHovering, disabled) {
        final theme = AppFlowyTheme.of(context);
        return theme.textColorScheme.onFill;
      },
    );
  }

  /// Destructive filled text button.
  factory AFFilledIconTextButton.destructive({
    Key? key,
    required String text,
    required VoidCallback onTap,
    required AFFilledIconBuilder iconBuilder,
    AFButtonSize size = AFButtonSize.m,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
  }) {
    return AFFilledIconTextButton._(
      key: key,
      text: text,
      iconBuilder: iconBuilder,
      onTap: onTap,
      size: size,
      padding: padding,
      borderRadius: borderRadius,
      backgroundColor: (context, isHovering, disabled) {
        final theme = AppFlowyTheme.of(context);
        if (disabled) {
          return theme.fillColorScheme.tertiary;
        }
        if (isHovering) {
          return theme.fillColorScheme.errorThickHover;
        }
        return theme.fillColorScheme.errorThick;
      },
      textColor: (context, isHovering, disabled) {
        final theme = AppFlowyTheme.of(context);
        return theme.textColorScheme.onFill;
      },
    );
  }

  /// Disabled filled text button.
  factory AFFilledIconTextButton.disabled({
    Key? key,
    required String text,
    required AFFilledIconBuilder iconBuilder,
    AFButtonSize size = AFButtonSize.m,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
  }) {
    return AFFilledIconTextButton._(
      key: key,
      text: text,
      iconBuilder: iconBuilder,
      onTap: () {},
      size: size,
      padding: padding,
      borderRadius: borderRadius,
      backgroundColor: (context, isHovering, disabled) {
        final theme = AppFlowyTheme.of(context);
        return theme.fillColorScheme.tertiary;
      },
      textColor: (context, isHovering, disabled) {
        final theme = AppFlowyTheme.of(context);
        return theme.textColorScheme.onFill;
      },
    );
  }

  /// Ghost filled text button with transparent background that shows color on hover.
  factory AFFilledIconTextButton.ghost({
    Key? key,
    required String text,
    required VoidCallback onTap,
    required AFFilledIconBuilder iconBuilder,
    AFButtonSize size = AFButtonSize.m,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
  }) {
    return AFFilledIconTextButton._(
      key: key,
      text: text,
      iconBuilder: iconBuilder,
      onTap: onTap,
      size: size,
      padding: padding,
      borderRadius: borderRadius,
      backgroundColor: (context, isHovering, disabled) {
        final theme = AppFlowyTheme.of(context);
        if (disabled) {
          return Colors.transparent;
        }
        if (isHovering) {
          return theme.fillColorScheme.themeThickHover;
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

  final String text;
  final VoidCallback onTap;
  final AFButtonSize size;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  final AFFilledIconBuilder iconBuilder;

  final AFBaseButtonColorBuilder? textColor;
  final AFBaseButtonColorBuilder? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return AFBaseButton(
      backgroundColor: backgroundColor,
      padding: padding ?? size.buildPadding(context),
      borderRadius: borderRadius ?? size.buildBorderRadius(context),
      onTap: onTap,
      builder: (context, isHovering, disabled) {
        final textColor = this.textColor?.call(context, isHovering, disabled) ??
            theme.textColorScheme.onFill;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconBuilder(context, isHovering, disabled),
            SizedBox(width: theme.spacing.s),
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
