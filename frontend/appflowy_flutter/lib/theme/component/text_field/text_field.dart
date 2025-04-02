import 'package:appflowy/theme/theme.dart';
import 'package:flutter/material.dart';

class AFTextField extends StatefulWidget {
  const AFTextField({
    super.key,
    this.hintText,
    this.initialText,
    this.keyboardType,
    this.radius,
  });

  final String? hintText;
  final String? initialText;
  final TextInputType? keyboardType;
  final double? radius;

  @override
  State<AFTextField> createState() => _AFTextFieldState();
}

class _AFTextFieldState extends State<AFTextField> {
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    final initialText = widget.initialText;
    if (initialText != null) {
      controller.text = initialText;
    }
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final borderRadius = BorderRadius.circular(
      widget.radius ?? theme.borderRadius.l,
    );

    return TextField(
      controller: controller,
      keyboardType: widget.keyboardType,
      style: theme.textStyle.body.standard(
        color: theme.textColorScheme.primary,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: theme.textStyle.body.standard(
          color: theme.textColorScheme.tertiary,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: theme.spacing.m,
          vertical: 10, // why?
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: theme.borderColorScheme.greyTertiary,
          ),
          borderRadius: borderRadius,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: theme.borderColorScheme.greyTertiary,
          ),
          borderRadius: borderRadius,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: theme.borderColorScheme.themeThick,
          ),
          borderRadius: borderRadius,
        ),
        hoverColor: theme.borderColorScheme.greyTertiaryHover,
      ),
    );
  }
}
