import 'package:appflowy_ui/src/component/component.dart';
import 'package:appflowy_ui/src/theme/appflowy_theme.dart';
import 'package:flutter/material.dart';

class AFOutlinedTextButton extends AFBaseTextButton {
  const AFOutlinedTextButton._({
    super.key,
    required super.text,
    required super.onTap,
    this.borderColor,
    super.textStyle,
    super.textColor,
    super.backgroundColor,
    super.size = AFButtonSize.m,
    super.padding,
    super.borderRadius,
    super.disabled = false,
    super.alignment,
  });

  /// Normal outlined text button.
  factory AFOutlinedTextButton.normal({
    Key? key,
    required String text,
    required VoidCallback onTap,
    AFButtonSize size = AFButtonSize.m,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
    bool disabled = false,
    Alignment? alignment,
    TextStyle? textStyle,
    AFBaseButtonColorBuilder? backgroundColor,
  }) {
    return AFOutlinedTextButton._(
      key: key,
      text: text,
      onTap: onTap,
      size: size,
      padding: padding,
      borderRadius: borderRadius,
      disabled: disabled,
      alignment: alignment,
      textStyle: textStyle,
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
      backgroundColor: backgroundColor ??
          (context, isHovering, disabled) {
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
  factory AFOutlinedTextButton.destructive({
    Key? key,
    required String text,
    required VoidCallback onTap,
    AFButtonSize size = AFButtonSize.m,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
    bool disabled = false,
    Alignment? alignment,
    TextStyle? textStyle,
  }) {
    return AFOutlinedTextButton._(
      key: key,
      text: text,
      onTap: onTap,
      size: size,
      padding: padding,
      borderRadius: borderRadius,
      disabled: disabled,
      alignment: alignment,
      textStyle: textStyle,
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
          return theme.fillColorScheme.errorSelect;
        }
        return theme.fillColorScheme.content;
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
  factory AFOutlinedTextButton.disabled({
    Key? key,
    required String text,
    AFButtonSize size = AFButtonSize.m,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
    Alignment? alignment,
    TextStyle? textStyle,
  }) {
    return AFOutlinedTextButton._(
      key: key,
      text: text,
      onTap: () {},
      size: size,
      padding: padding,
      borderRadius: borderRadius,
      disabled: true,
      alignment: alignment,
      textStyle: textStyle,
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

  final AFBaseButtonBorderColorBuilder? borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: 76,
      ),
      child: AFBaseButton(
        disabled: disabled,
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        padding: padding ?? size.buildPadding(context),
        borderRadius: borderRadius ?? size.buildBorderRadius(context),
        onTap: onTap,
        builder: (context, isHovering, disabled) {
          final textColor =
              this.textColor?.call(context, isHovering, disabled) ??
                  theme.textColorScheme.primary;

          Widget child = Text(
            text,
            style: textStyle ??
                size.buildTextStyle(context).copyWith(color: textColor),
            textAlign: TextAlign.center,
          );

          final alignment = this.alignment;

          if (alignment != null) {
            child = Align(
              alignment: alignment,
              child: child,
            );
          }

          return child;
        },
      ),
    );
  }
}
