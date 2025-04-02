import 'package:appflowy/theme/component/button/base_button/base.dart';
import 'package:appflowy/theme/component/button/base_button/base_button.dart';
import 'package:appflowy/theme/theme.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
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
  }) {
    return AFOutlinedIconTextButton._(
      key: key,
      text: text,
      onTap: onTap,
      iconBuilder: iconBuilder,
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
  }) {
    return AFOutlinedIconTextButton._(
      key: key,
      text: text,
      iconBuilder: iconBuilder,
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
  }) {
    return AFOutlinedIconTextButton._(
      key: key,
      text: text,
      iconBuilder: iconBuilder,
      onTap: () {},
      size: size,
      padding: padding,
      borderRadius: borderRadius,
      textColor: (context, isHovering, disabled) {
        final theme = AppFlowyTheme.of(context);
        return disabled
            ? theme.textColorScheme.tertiary
            : theme.textColorScheme.primary;
      },
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
    );
  }

  final String text;
  final VoidCallback onTap;
  final AFButtonSize size;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  final AFOutlinedIconBuilder iconBuilder;

  final AFBaseButtonColorBuilder? textColor;
  final AFBaseButtonColorBuilder? borderColor;
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
      builder: (context, isHovering, disabled) {
        final textColor = this.textColor?.call(context, isHovering, disabled) ??
            theme.textColorScheme.primary;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconBuilder(context, isHovering, disabled),
            HSpace(theme.spacing.s),
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
