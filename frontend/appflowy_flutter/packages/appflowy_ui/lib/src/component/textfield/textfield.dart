import 'package:appflowy_ui/src/theme/theme.dart';
import 'package:flutter/material.dart';

typedef AFTextFieldValidator = (bool result, String errorText) Function(
  TextEditingController controller,
);

abstract class AFTextFieldState extends State<AFTextField> {
  // Error handler
  void syncError({required String errorText}) {}
  void clearError() {}

  /// Obscure the text.
  void syncObscured(bool isObscured) {}
}

class AFTextField extends StatefulWidget {
  const AFTextField({
    super.key,
    this.hintText,
    this.initialText,
    this.keyboardType,
    this.validator,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.autoFocus,
    this.obscureText = false,
    this.suffixIconBuilder,
    this.suffixIconConstraints,
    this.size = AFTextFieldSize.l,
    this.groupId = EditableText,
  });

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

  /// Obscure the text.
  final bool obscureText;

  /// The trailing widget to display.
  final Widget Function(BuildContext context, bool isObscured)?
      suffixIconBuilder;

  /// The size of the suffix icon.
  final BoxConstraints? suffixIconConstraints;

  /// The group ID for the text field.
  final Object groupId;

  @override
  State<AFTextField> createState() => _AFTextFieldState();
}

class _AFTextFieldState extends AFTextFieldState {
  late final TextEditingController effectiveController;

  bool hasError = false;
  String errorText = '';

  bool isObscured = false;

  @override
  void initState() {
    super.initState();

    effectiveController = widget.controller ?? TextEditingController();

    final initialText = widget.initialText;
    if (initialText != null) {
      effectiveController.text = initialText;
    }

    effectiveController.addListener(_validate);

    isObscured = widget.obscureText;
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
      groupId: widget.groupId,
      controller: effectiveController,
      keyboardType: widget.keyboardType,
      style: theme.textStyle.body.standard(
        color: theme.textColorScheme.primary,
      ),
      obscureText: isObscured,
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
        suffixIcon: widget.suffixIconBuilder?.call(context, isObscured),
        suffixIconConstraints: widget.suffixIconConstraints,
      ),
    );

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

  @override
  void syncObscured(bool isObscured) {
    setState(() {
      this.isObscured = isObscured;
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
