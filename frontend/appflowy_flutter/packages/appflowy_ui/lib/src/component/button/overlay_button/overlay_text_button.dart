import 'package:appflowy_ui/src/component/button/overlay_button/overlay_button_const.dart';
import 'package:appflowy_ui/src/component/component.dart';
import 'package:appflowy_ui/src/theme/appflowy_theme.dart';
import 'package:flutter/material.dart';

class AFOverlayTextButton extends AFBaseTextButton {
  const AFOverlayTextButton({
    super.key,
    required super.text,
    required super.onTap,
    super.textColor,
    super.backgroundColor,
    super.size = AFButtonSize.m,
    super.padding,
    super.borderRadius,
    super.disabled = false,
    super.alignment,
    super.textStyle,
  });

  /// Normal overlay text button.
  factory AFOverlayTextButton.primary({
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
    return AFOverlayTextButton(
      key: key,
      text: text,
      onTap: onTap,
      size: size,
      padding: padding,
      borderRadius: borderRadius,
      disabled: disabled,
      alignment: alignment,
      textStyle: textStyle,
      backgroundColor: (context, isHovering, disabled) {
        final theme = Theme.of(context);
        if (disabled) {
          return theme.colorScheme.surface.withAlpha(overlayButtonDisableAlpha);
        }
        if (isHovering) {
          return theme.colorScheme.surface.withAlpha(overlayButtonHoverAlpha);
        }
        return theme.colorScheme.surface.withAlpha(overlayButtonAlpha);
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
        borderColor: (_, __, ___, ____) => Colors.transparent,
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
