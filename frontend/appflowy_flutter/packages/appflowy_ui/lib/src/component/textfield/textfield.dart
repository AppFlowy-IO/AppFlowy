import 'package:appflowy_ui/src/theme/theme.dart';
import 'package:flutter/material.dart';

typedef AFTextFieldValidator = (bool result, String errorText) Function(
  TextEditingController controller,
);

abstract class AFTextFieldState extends State<AFTextField> {
  void syncError({required String errorText}) {}
  void clearError() {}
}

class AFTextField extends StatefulWidget {
  const AFTextField({
    super.key,
    this.hintText,
    this.initialText,
    this.keyboardType,
    this.size = AFTextFieldSize.l,
    this.validator,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.autoFocus,
    this.height = 40.0,
  });

  /// The height of the text field.
  final double height;

  /// The hint text to display when the text field is empty.
  final String? hintText;

  /// The initial text to display in the text field.
  final String? initialText;

  /// The type of keyboard to display.
  final TextInputType? keyboardType;

  /// The size variant of the text field.
  final AFTextFieldSize size;

  /// The validator to use for the text field.
  final AFTextFieldValidator? validator;

  /// The controller to use for the text field.
  ///
  /// If it's not provided, the text field will use a new controller.
  final TextEditingController? controller;

  /// The callback to call when the text field changes.
  final void Function(String)? onChanged;

  /// The callback to call when the text field is submitted.
  final void Function(String)? onSubmitted;

  /// Enable auto focus.
  final bool? autoFocus;

  @override
  State<AFTextField> createState() => _AFTextFieldState();
}

class _AFTextFieldState extends AFTextFieldState {
  late final TextEditingController effectiveController;

  bool hasError = false;
  String errorText = '';

  @override
  void initState() {
    super.initState();

    effectiveController = widget.controller ?? TextEditingController();

    final initialText = widget.initialText;
    if (initialText != null) {
      effectiveController.text = initialText;
    }

    effectiveController.addListener(_validate);
  }

  @override
  void dispose() {
    effectiveController.removeListener(_validate);
    if (widget.controller == null) {
      effectiveController.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final borderRadius = widget.size.borderRadius(theme);
    final contentPadding = widget.size.contentPadding(theme);

    final errorBorderColor = theme.borderColorScheme.errorThick;
    final defaultBorderColor = theme.borderColorScheme.greyTertiary;

    Widget child = TextField(
      controller: effectiveController,
      keyboardType: widget.keyboardType,
      style: theme.textStyle.body.standard(
        color: theme.textColorScheme.primary,
      ),
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      autofocus: widget.autoFocus ?? false,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: theme.textStyle.body.standard(
          color: theme.textColorScheme.tertiary,
        ),
        isDense: true,
        constraints: BoxConstraints(),
        contentPadding: contentPadding,
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
    );

    child = SizedBox(height: widget.height, child: child);

    if (hasError && errorText.isNotEmpty) {
      child = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          child,
          SizedBox(height: theme.spacing.xs),
          Text(
            errorText,
            style: theme.textStyle.caption.standard(
              color: theme.textColorScheme.error,
            ),
          ),
        ],
      );
    }

    return child;
  }

  void _validate() {
    final validator = widget.validator;
    if (validator != null) {
      final result = validator(effectiveController);
      setState(() {
        hasError = result.$1;
        errorText = result.$2;
      });
    }
  }

  @override
  void syncError({
    required String errorText,
  }) {
    setState(() {
      hasError = true;
      this.errorText = errorText;
    });
  }

  @override
  void clearError() {
    setState(() {
      hasError = false;
      errorText = '';
    });
  }
}

enum AFTextFieldSize {
  m,
  l;

  EdgeInsetsGeometry contentPadding(AppFlowyThemeData theme) {
    return EdgeInsets.symmetric(
      vertical: switch (this) {
        AFTextFieldSize.m => theme.spacing.s,
        AFTextFieldSize.l => 10.0,
      },
      horizontal: theme.spacing.m,
    );
  }

  BorderRadius borderRadius(AppFlowyThemeData theme) {
    return BorderRadius.circular(
      switch (this) {
        AFTextFieldSize.m => theme.borderRadius.m,
        AFTextFieldSize.l => 10.0,
      },
    );
  }
}
