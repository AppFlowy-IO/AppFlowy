import 'package:appflowy_ui/src/component/button/overlay_button/overlay_button_const.dart';
import 'package:appflowy_ui/src/component/component.dart';
import 'package:flutter/material.dart';

typedef AFOverlayButtonWidgetBuilder = Widget Function(
  BuildContext context,
  bool isHovering,
  bool disabled,
);

class AFOverlayButton extends StatelessWidget {
  const AFOverlayButton._({
    super.key,
    required this.onTap,
    required this.backgroundColor,
    required this.builder,
    this.size = AFButtonSize.m,
    this.padding,
    this.borderRadius,
    this.disabled = false,
  });

  /// Normal overlay button.
  factory AFOverlayButton.normal({
    Key? key,
    required VoidCallback onTap,
    required AFOverlayButtonWidgetBuilder builder,
    AFButtonSize size = AFButtonSize.m,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
    bool disabled = false,
  }) {
    return AFOverlayButton._(
      key: key,
      builder: builder,
      onTap: onTap,
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

  /// Disabled overlay button.
  factory AFOverlayButton.disabled({
    Key? key,
    required AFOverlayButtonWidgetBuilder builder,
    AFButtonSize size = AFButtonSize.m,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
  }) {
    return AFOverlayButton._(
      key: key,
      builder: builder,
      onTap: () {},
      size: size,
      padding: padding,
      borderRadius: borderRadius,
      disabled: true,
      backgroundColor: (context, isHovering, disabled) => Theme.of(context)
          .colorScheme
          .surface
          .withAlpha(overlayButtonDisableAlpha),
    );
  }

  final VoidCallback onTap;
  final bool disabled;
  final AFButtonSize size;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  final AFBaseButtonColorBuilder? backgroundColor;
  final AFGhostButtonWidgetBuilder builder;

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
