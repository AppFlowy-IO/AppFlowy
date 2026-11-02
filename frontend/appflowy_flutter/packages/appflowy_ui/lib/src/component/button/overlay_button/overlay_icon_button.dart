import 'package:appflowy_ui/src/component/button/overlay_button/overlay_button_const.dart';
import 'package:appflowy_ui/src/component/component.dart';
import 'package:appflowy_ui/src/theme/appflowy_theme.dart';
import 'package:flutter/material.dart';

typedef AFOverlayIconBuilder = Widget Function(
  BuildContext context,
  bool isHovering,
  bool disabled,
);

class AFOverlayIconButton extends StatelessWidget {
  const AFOverlayIconButton({
    super.key,
    required this.onTap,
    required this.iconBuilder,
    this.backgroundColor,
    this.size = AFButtonSize.m,
    this.padding,
    this.borderRadius,
    this.disabled = false,
  });

  /// Primary overlay text button.
  factory AFOverlayIconButton.primary({
    Key? key,
    required VoidCallback onTap,
    required AFOverlayIconBuilder iconBuilder,
    AFButtonSize size = AFButtonSize.m,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
    bool disabled = false,
  }) {
    return AFOverlayIconButton(
      key: key,
      onTap: onTap,
      iconBuilder: iconBuilder,
      size: size,
      padding: padding,
      borderRadius: borderRadius,
      disabled: disabled,
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
    );
  }

  /// Disabled overlay text button.
  factory AFOverlayIconButton.disabled({
    Key? key,
    required AFOverlayIconBuilder iconBuilder,
    AFButtonSize size = AFButtonSize.m,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
  }) {
    return AFOverlayIconButton(
      key: key,
      iconBuilder: iconBuilder,
      onTap: () {},
      size: size,
      padding: padding,
      borderRadius: borderRadius,
      disabled: true,
      backgroundColor: (context, isHovering, disabled) {
        return Theme.of(context).colorScheme.surface.withAlpha(overlayButtonDisableAlpha);
      },
    );
  }

  final bool disabled;
  final VoidCallback onTap;
  final AFButtonSize size;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  final AFOverlayIconBuilder iconBuilder;

  final AFBaseButtonColorBuilder? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return AFBaseButton(
      disabled: disabled,
      backgroundColor: backgroundColor,
      borderColor: (context, isHovering, disabled, isFocused) {
        return Colors.transparent;
      },
      padding: padding ?? EdgeInsets.all(theme.spacing.m),
      borderRadius: borderRadius ?? size.buildBorderRadius(context),
      onTap: onTap,
      builder: (context, isHovering, disabled) {
        return iconBuilder(
          context,
          isHovering,
          disabled,
        );
      },
    );
  }
}
