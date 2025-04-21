import 'package:appflowy_ui/src/component/component.dart';
import 'package:appflowy_ui/src/theme/appflowy_theme.dart';
import 'package:flutter/material.dart';

typedef AFOutlinedIconBuilder = Widget Function(
  BuildContext context,
  bool isHovering,
  bool disabled,
);

class AFOutlinedIconTextButton extends StatelessWidget {
  const AFOutlinedIconTextButton._({
    super.key,
    required this.text,
    required this.onTap,
    required this.iconBuilder,
    this.borderColor,
    this.textColor,
    this.backgroundColor,
    this.size = AFButtonSize.m,
    this.padding,
    this.borderRadius,
    this.disabled = false,
    this.alignment = MainAxisAlignment.center,
  });

  /// Normal outlined text button.
  factory AFOutlinedIconTextButton.normal({
    Key? key,
    required String text,
    required VoidCallback onTap,
    required AFOutlinedIconBuilder iconBuilder,
    AFButtonSize size = AFButtonSize.m,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
    bool disabled = false,
    MainAxisAlignment alignment = MainAxisAlignment.center,
  }) {
    return AFOutlinedIconTextButton._(
      key: key,
      text: text,
      onTap: onTap,
      iconBuilder: iconBuilder,
      size: size,
      padding: padding,
      borderRadius: borderRadius,
      disabled: disabled,
      alignment: alignment,
      borderColor: (context, isHovering, disabled, isFocused) {
        final theme = AppFlowyTheme.of(context);
        if (disabled) {
          return theme.borderColorScheme.primary;
        }
        if (isHovering) {
          return theme.borderColorScheme.primaryHover;
        }
        return theme.borderColorScheme.primary;
      },
      backgroundColor: (context, isHovering, disabled) {
        final theme = AppFlowyTheme.of(context);
        if (disabled) {
          return theme.fillColorScheme.content;
        }
        if (isHovering) {
          return theme.fillColorScheme.contentHover;
        }
        return theme.fillColorScheme.content;
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

  /// Destructive outlined text button.
  factory AFOutlinedIconTextButton.destructive({
    Key? key,
    required String text,
    required VoidCallback onTap,
    required AFOutlinedIconBuilder iconBuilder,
    AFButtonSize size = AFButtonSize.m,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
    bool disabled = false,
    MainAxisAlignment alignment = MainAxisAlignment.center,
  }) {
    return AFOutlinedIconTextButton._(
      key: key,
      text: text,
      iconBuilder: iconBuilder,
      onTap: onTap,
      size: size,
      padding: padding,
      borderRadius: borderRadius,
      disabled: disabled,
      alignment: alignment,
      borderColor: (context, isHovering, disabled, isFocused) {
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
      textColor: (context, isHovering, disabled) {
        final theme = AppFlowyTheme.of(context);
        return disabled
            ? theme.textColorScheme.error
            : theme.textColorScheme.error;
      },
    );
  }

  /// Disabled outlined text button.
  factory AFOutlinedIconTextButton.disabled({
    Key? key,
    required String text,
    required AFOutlinedIconBuilder iconBuilder,
    AFButtonSize size = AFButtonSize.m,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
    MainAxisAlignment alignment = MainAxisAlignment.center,
  }) {
    return AFOutlinedIconTextButton._(
      key: key,
      text: text,
      iconBuilder: iconBuilder,
      onTap: () {},
      size: size,
      padding: padding,
      borderRadius: borderRadius,
      disabled: true,
      alignment: alignment,
      textColor: (context, isHovering, disabled) {
        final theme = AppFlowyTheme.of(context);
        return disabled
            ? theme.textColorScheme.tertiary
            : theme.textColorScheme.primary;
      },
      borderColor: (context, isHovering, disabled, isFocused) {
        final theme = AppFlowyTheme.of(context);
        if (disabled) {
          return theme.borderColorScheme.primary;
        }
        if (isHovering) {
          return theme.borderColorScheme.primaryHover;
        }
        return theme.borderColorScheme.primary;
      },
      backgroundColor: (context, isHovering, disabled) {
        final theme = AppFlowyTheme.of(context);
        if (disabled) {
          return theme.fillColorScheme.content;
        }
        if (isHovering) {
          return theme.fillColorScheme.contentHover;
        }
        return theme.fillColorScheme.content;
      },
    );
  }

  final String text;
  final bool disabled;
  final VoidCallback onTap;
  final AFButtonSize size;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final MainAxisAlignment alignment;

  final AFOutlinedIconBuilder iconBuilder;

  final AFBaseButtonColorBuilder? textColor;
  final AFBaseButtonBorderColorBuilder? borderColor;
  final AFBaseButtonColorBuilder? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return AFBaseButton(
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      padding: padding ?? size.buildPadding(context),
      borderRadius: borderRadius ?? size.buildBorderRadius(context),
      onTap: onTap,
      disabled: disabled,
      builder: (context, isHovering, disabled) {
        final textColor = this.textColor?.call(context, isHovering, disabled) ??
            theme.textColorScheme.primary;
        return Row(
          mainAxisAlignment: alignment,
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
