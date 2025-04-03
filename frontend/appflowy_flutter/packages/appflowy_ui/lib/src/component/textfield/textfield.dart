import 'package:appflowy_ui/src/theme/appflowy_theme.dart';
import 'package:flutter/material.dart';

typedef AFTextFieldValidator = (bool result, String errorText) Function(
  TextEditingController controller,
);

class AFTextField extends StatefulWidget {
  const AFTextField({
    super.key,
    this.hintText,
    this.initialText,
    this.keyboardType,
    this.radius,
    this.validator,
  });

  final String? hintText;
  final String? initialText;
  final TextInputType? keyboardType;
  final double? radius;
  final AFTextFieldValidator? validator;

  @override
  State<AFTextField> createState() => _AFTextFieldState();
}

class _AFTextFieldState extends State<AFTextField> {
  final controller = TextEditingController();

  bool hasError = false;
  String errorText = '';

  @override
  void initState() {
    super.initState();

    final initialText = widget.initialText;
    if (initialText != null) {
      controller.text = initialText;
    }

    controller.addListener(_validate);
  }

  @override
  void dispose() {
    controller.removeListener(_validate);
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final borderRadius = BorderRadius.circular(
      widget.radius ?? theme.borderRadius.l,
    );

    final errorBorderColor = theme.borderColorScheme.errorThick;
    final defaultBorderColor = theme.borderColorScheme.greyTertiary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
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
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: hasError ? errorBorderColor : defaultBorderColor,
              ),
              borderRadius: borderRadius,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: hasError ? errorBorderColor : defaultBorderColor,
              ),
              borderRadius: borderRadius,
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: hasError
                    ? errorBorderColor
                    : theme.borderColorScheme.themeThick,
              ),
              borderRadius: borderRadius,
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: errorBorderColor,
              ),
              borderRadius: borderRadius,
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: errorBorderColor,
              ),
              borderRadius: borderRadius,
            ),
            hoverColor: theme.borderColorScheme.greyTertiaryHover,
          ),
        ),
        if (hasError && errorText.isNotEmpty) ...[
          SizedBox(height: theme.spacing.xs),
          Text(
            errorText,
            style: theme.textStyle.caption.standard(
              color: theme.textColorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  void _validate() {
    final validator = widget.validator;
    if (validator != null) {
      final result = validator(controller);
      setState(() {
        hasError = result.$1;
        errorText = result.$2;
      });
    }
  }
}
