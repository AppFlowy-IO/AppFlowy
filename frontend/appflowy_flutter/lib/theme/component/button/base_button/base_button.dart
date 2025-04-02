import 'package:appflowy/theme/theme.dart';
import 'package:flutter/material.dart';

typedef AFBaseButtonColorBuilder = Color Function(
  BuildContext context,
  bool isHovering,
  bool disabled,
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
    this.disabled = false,
  });

  final VoidCallback? onTap;

  final AFBaseButtonColorBuilder? borderColor;
  final AFBaseButtonColorBuilder? backgroundColor;

  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool disabled;

  final Widget Function(BuildContext context, bool isHovering, bool disabled)
      builder;

  @override
  State<AFBaseButton> createState() => _AFBaseButtonState();
}

class _AFBaseButtonState extends State<AFBaseButton> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = _buildBorderColor(context);
    final Color backgroundColor = _buildBackgroundColor(context);

    return InkWell(
      onTap: widget.disabled ? null : widget.onTap,
      hoverColor: Colors.transparent,
      onHover: (value) => setState(() => isHovering = value),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: Padding(
          padding: widget.padding,
          child: widget.builder(context, isHovering, widget.disabled),
        ),
      ),
    );
  }

  Color _buildBorderColor(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return widget.borderColor?.call(context, isHovering, widget.disabled) ??
        theme.borderColorScheme.greyTertiary;
  }

  Color _buildBackgroundColor(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return widget.backgroundColor?.call(context, isHovering, widget.disabled) ??
        theme.fillColorScheme.transparent;
  }
}
