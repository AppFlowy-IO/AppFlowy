import 'package:appflowy_ui/src/theme/appflowy_theme.dart';
import 'package:flutter/material.dart';

typedef AFBaseButtonColorBuilder = Color Function(
  BuildContext context,
  bool isHovering,
  bool disabled,
);

typedef AFBaseButtonBorderColorBuilder = Color Function(
  BuildContext context,
  bool isHovering,
  bool disabled,
  bool isFocused,
);

class AFBaseButton extends StatefulWidget {
  const AFBaseButton({
    super.key,
    required this.onTap,
    required this.builder,
    required this.padding,
    required this.borderRadius,
    this.borderColor,
    this.backgroundColor,
    this.ringColor,
    this.disabled = false,
  });

  final VoidCallback? onTap;

  final AFBaseButtonBorderColorBuilder? borderColor;
  final AFBaseButtonBorderColorBuilder? ringColor;
  final AFBaseButtonColorBuilder? backgroundColor;

  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool disabled;

  final Widget Function(
    BuildContext context,
    bool isHovering,
    bool disabled,
  ) builder;

  @override
  State<AFBaseButton> createState() => _AFBaseButtonState();
}

class _AFBaseButtonState extends State<AFBaseButton> {
  final FocusNode focusNode = FocusNode();

  bool isHovering = false;
  bool isFocused = false;

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color borderColor = _buildBorderColor(context);
    final Color backgroundColor = _buildBackgroundColor(context);
    final Color ringColor = _buildRingColor(context);

    return Actions(
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (!widget.disabled) {
              widget.onTap?.call();
            }
            return;
          },
        ),
      },
      child: Focus(
        focusNode: focusNode,
        onFocusChange: (isFocused) {
          setState(() => this.isFocused = isFocused);
        },
        child: MouseRegion(
          cursor: widget.disabled
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          onEnter: (_) => setState(() => isHovering = true),
          onExit: (_) => setState(() => isHovering = false),
          child: GestureDetector(
            onTap: widget.disabled ? null : widget.onTap,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: isFocused
                    ? Border.all(
                        color: ringColor,
                        width: 2,
                        strokeAlign: BorderSide.strokeAlignOutside,
                      )
                    : null,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
                child: Padding(
                  padding: widget.padding,
                  child: widget.builder(
                    context,
                    isHovering,
                    widget.disabled,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _buildBorderColor(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return widget.borderColor
            ?.call(context, isHovering, widget.disabled, isFocused) ??
        theme.borderColorScheme.greyTertiary;
  }

  Color _buildBackgroundColor(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return widget.backgroundColor?.call(context, isHovering, widget.disabled) ??
        theme.fillColorScheme.transparent;
  }

  Color _buildRingColor(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    if (widget.ringColor != null) {
      return widget.ringColor!
          .call(context, isHovering, widget.disabled, isFocused);
    }

    if (isFocused) {
      return theme.borderColorScheme.themeThick.withAlpha(128);
    }

    return theme.borderColorScheme.transparent;
  }
}
