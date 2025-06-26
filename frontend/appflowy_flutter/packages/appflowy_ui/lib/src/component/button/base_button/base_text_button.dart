import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

class AFBaseTextButton extends StatelessWidget {
  const AFBaseTextButton({
    super.key,
    required this.text,
    required this.onTap,
    this.disabled = false,
    this.showFocusRing = false,
    this.size = AFButtonSize.m,
    this.padding,
    this.borderRadius,
    this.textColor,
    this.backgroundColor,
    this.backgroundFocusColor,
    this.alignment,
    this.textStyle,
  });

  /// The text of the button.
  final String text;

  /// Whether the button is disabled.
  final bool disabled;

  /// Whether to show the focus ring.
  final bool showFocusRing;

  /// The callback when the button is tapped.
  final VoidCallback onTap;

  /// The size of the button.
  final AFButtonSize size;

  /// The padding of the button.
  final EdgeInsetsGeometry? padding;

  /// The border radius of the button.
  final double? borderRadius;

  /// The text color of the button.
  final AFBaseButtonColorBuilder? textColor;

  /// The background color of the button.
  final AFBaseButtonColorBuilder? backgroundColor;

  /// The background color of the button.
  /// The [backgroundFocusColor] and [backgroundColor] cannot exist at the same time.
  final AFBaseButtonFocusColorBuilder? backgroundFocusColor;

  /// The alignment of the button.
  ///
  /// If it's null, the button size will be the size of the text with padding.
  final Alignment? alignment;

  /// The text style of the button.
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }
}
