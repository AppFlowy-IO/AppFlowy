import 'package:flutter/material.dart';

import 'package:flowy_infra_ui/style_widget/text.dart';

class FlowyGradientButton extends StatefulWidget {
  const FlowyGradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.fontWeight = FontWeight.w600,
    this.textColor = Colors.white,
    this.backgroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final FontWeight fontWeight;

  /// Used to provide a custom foreground color for the button, used in cases
  /// where a custom [backgroundColor] is provided and the default text color
  /// does not have enough contrast.
  ///
  final Color textColor;

  /// Used to provide a custom background color for the button, this will
  /// override the gradient behavior, and is mostly used in rare cases
  /// where the gradient doesn't have contrast with the background.
  ///
  final Color? backgroundColor;

  @override
  State<FlowyGradientButton> createState() => _FlowyGradientButtonState();
}

class _FlowyGradientButtonState extends State<FlowyGradientButton> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => widget.onPressed?.call(),
      child: MouseRegion(
        onEnter: (_) => setState(() => isHovering = true),
        onExit: (_) => setState(() => isHovering = false),
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                blurRadius: 4,
                color: Colors.black.withOpacity(0.25),
                offset: const Offset(0, 2),
              ),
            ],
            borderRadius: BorderRadius.circular(16),
            color: widget.backgroundColor,
            gradient: widget.backgroundColor != null
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      isHovering
                          ? const Color.fromARGB(255, 57, 40, 92)
                          : const Color(0xFF44326B),
                      isHovering
                          ? const Color.fromARGB(255, 96, 53, 164)
                          : const Color(0xFF7547C0),
                    ],
                  ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
            child: FlowyText(
              widget.label,
              fontSize: 16,
              fontWeight: widget.fontWeight,
              color: widget.textColor,
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
