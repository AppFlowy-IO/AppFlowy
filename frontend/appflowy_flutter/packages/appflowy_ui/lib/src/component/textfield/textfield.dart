import 'package:appflowy_ui/src/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    this.expands = false,
    this.suffixIconBuilder,
    this.suffixIconConstraints,
    this.size = AFTextFieldSize.l,
    this.groupId = EditableText,
    this.focusNode,
    this.textAlignVertical,
    this.maxLines = 1,
    this.readOnly = false,
    this.maxLength,
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
  final Widget? Function(BuildContext context, bool isObscured)?
      suffixIconBuilder;

  /// The size of the suffix icon.
  final BoxConstraints? suffixIconConstraints;

  /// The group ID for the text field.
  final Object groupId;

  /// The focus node for the text field.
  final FocusNode? focusNode;

  /// Readonly.
  final bool readOnly;

  /// Whether the text field expands to fill the available space.
  final bool expands;

  /// The maximum number of lines for the text field.
  final int? maxLines;

  /// The vertical alignment of the text within the text field.
  final TextAlignVertical? textAlignVertical;

  /// The maximum length of the text field.
  final int? maxLength;

  @override
  State<AFTextField> createState() => _AFTextFieldState();
}

class _AFTextFieldState extends AFTextFieldState {
  late final TextEditingController effectiveController;

  bool hasError = false;
  String errorText = '';

  bool isObscured = false;
  final key = GlobalKey();

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
    final defaultBorderColor = theme.borderColorScheme.primary;

    final border = OutlineInputBorder(
      borderSide: BorderSide(
        color: hasError ? errorBorderColor : defaultBorderColor,
      ),
      borderRadius: borderRadius,
    );

    final enabledBorder = OutlineInputBorder(
      borderSide: BorderSide(
        color: hasError ? errorBorderColor : defaultBorderColor,
      ),
      borderRadius: borderRadius,
    );

    final focusedBorder = OutlineInputBorder(
      borderSide: BorderSide(
        color: widget.readOnly
            ? defaultBorderColor
            : hasError
                ? errorBorderColor
                : theme.borderColorScheme.themeThick,
      ),
      borderRadius: borderRadius,
    );

    final errorBorder = OutlineInputBorder(
      borderSide: BorderSide(
        color: errorBorderColor,
      ),
      borderRadius: borderRadius,
    );

    final focusedErrorBorder = OutlineInputBorder(
      borderSide: BorderSide(
        color: errorBorderColor,
      ),
      borderRadius: borderRadius,
    );

    Widget child = TextField(
      key: key,
      groupId: widget.groupId,
      expands: widget.expands,
      maxLines: widget.maxLines,
      focusNode: widget.focusNode,
      controller: effectiveController,
      keyboardType: widget.keyboardType,
      readOnly: widget.readOnly,
      style: theme.textStyle.body.standard(
        color: theme.textColorScheme.primary,
      ),
      textAlignVertical: widget.textAlignVertical,
      obscureText: isObscured,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      autofocus: widget.autoFocus ?? false,
      maxLength: widget.maxLength,
      maxLengthEnforcement: MaxLengthEnforcement.truncateAfterCompositionEnds,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: theme.textStyle.body.standard(
          color: theme.textColorScheme.tertiary,
        ),
        counterText: '',
        isDense: true,
        constraints: BoxConstraints(),
        contentPadding: contentPadding,
        border: border,
        enabledBorder: enabledBorder,
        focusedBorder: focusedBorder,
        errorBorder: errorBorder,
        focusedErrorBorder: focusedErrorBorder,
        hoverColor: theme.borderColorScheme.primaryHover,
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
