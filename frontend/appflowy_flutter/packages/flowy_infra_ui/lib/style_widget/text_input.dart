import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flowy_infra/size.dart';

class FlowyFormTextInput extends StatelessWidget {
  static EdgeInsets kDefaultTextInputPadding =
      EdgeInsets.only(bottom: Insets.sm, top: 4);

  final String? label;
  final bool? autoFocus;
  final String? initialValue;
  final String? hintText;
  final EdgeInsets? contentPadding;
  final TextStyle? textStyle;
  final TextAlign textAlign;
  final int? maxLines;
  final int? maxLength;
  final bool showCounter;
  final TextEditingController? controller;
  final TextCapitalization? capitalization;
  final Function(String)? onChanged;
  final Function()? onEditingComplete;
  final Function(bool)? onFocusChanged;
  final Function(FocusNode)? onFocusCreated;

  const FlowyFormTextInput({
    super.key,
    this.label,
    this.autoFocus,
    this.initialValue,
    this.onChanged,
    this.onEditingComplete,
    this.hintText,
    this.onFocusChanged,
    this.onFocusCreated,
    this.controller,
    this.contentPadding,
    this.capitalization,
    this.textStyle,
    this.textAlign = TextAlign.center,
    this.maxLines,
    this.maxLength,
    this.showCounter = true,
  });

  @override
  Widget build(BuildContext context) {
    return StyledSearchTextInput(
      capitalization: capitalization,
      label: label,
      autoFocus: autoFocus,
      initialValue: initialValue,
      onChanged: onChanged,
      onFocusCreated: onFocusCreated,
      style: textStyle ?? Theme.of(context).textTheme.bodyMedium,
      textAlign: textAlign,
      onEditingComplete: onEditingComplete,
      onFocusChanged: onFocusChanged,
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      showCounter: showCounter,
      contentPadding: contentPadding ?? kDefaultTextInputPadding,
      hintText: hintText,
      hintStyle: Theme.of(context)
          .textTheme
          .bodyMedium!
          .copyWith(color: Theme.of(context).hintColor.withOpacity(0.7)),
      isDense: true,
      inputBorder: const ThinUnderlineBorder(
        borderSide: BorderSide(width: 5, color: Colors.red),
      ),
    );
  }
}

class StyledSearchTextInput extends StatefulWidget {
  final String? label;
  final TextStyle? style;
  final TextAlign textAlign;
  final EdgeInsets? contentPadding;
  final bool? autoFocus;
  final bool? obscureText;
  final IconData? icon;
  final String? initialValue;
  final int? maxLines;
  final int? maxLength;
  final bool showCounter;
  final TextEditingController? controller;
  final TextCapitalization? capitalization;
  final TextInputType? type;
  final bool? enabled;
  final bool? autoValidate;
  final bool? enableSuggestions;
  final bool? autoCorrect;
  final bool isDense;
  final String? errorText;
  final String? hintText;
  final TextStyle? hintStyle;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final InputDecoration? inputDecoration;
  final InputBorder? inputBorder;

  final Function(String)? onChanged;
  final Function()? onEditingComplete;
  final Function()? onEditingCancel;
  final Function(bool)? onFocusChanged;
  final Function(FocusNode)? onFocusCreated;
  final Function(String)? onFieldSubmitted;
  final Function(String?)? onSaved;
  final VoidCallback? onTap;

  const StyledSearchTextInput({
    super.key,
    this.label,
    this.autoFocus = false,
    this.obscureText = false,
    this.type = TextInputType.text,
    this.textAlign = TextAlign.center,
    this.icon,
    this.initialValue = '',
    this.controller,
    this.enabled,
    this.autoValidate = false,
    this.enableSuggestions = true,
    this.autoCorrect = true,
    this.isDense = false,
    this.errorText,
    this.style,
    this.contentPadding,
    this.prefixIcon,
    this.suffixIcon,
    this.inputDecoration,
    this.onChanged,
    this.onEditingComplete,
    this.onEditingCancel,
    this.onFocusChanged,
    this.onFocusCreated,
    this.onFieldSubmitted,
    this.onSaved,
    this.onTap,
    this.hintText,
    this.hintStyle,
    this.capitalization,
    this.maxLines,
    this.maxLength,
    this.showCounter = false,
    this.inputBorder,
  });

  @override
  StyledSearchTextInputState createState() => StyledSearchTextInputState();
}

class StyledSearchTextInputState extends State<StyledSearchTextInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode(
      debugLabel: widget.label,
      canRequestFocus: true,
      onKeyEvent: (node, event) {
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onEditingCancel?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    );
    // Listen for focus out events
    _focusNode.addListener(_onFocusChanged);
    widget.onFocusCreated?.call(_focusNode);
    if (widget.autoFocus ?? false) {
      scheduleMicrotask(() => _focusNode.requestFocus());
    }
  }

  void _onFocusChanged() => widget.onFocusChanged?.call(_focusNode.hasFocus);

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void clear() => _controller.clear();

  String get text => _controller.text;

  set text(String value) => _controller.text = value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: Insets.sm),
      child: TextFormField(
        onChanged: widget.onChanged,
        onEditingComplete: widget.onEditingComplete,
        onFieldSubmitted: widget.onFieldSubmitted,
        onSaved: widget.onSaved,
        onTap: widget.onTap,
        autofocus: widget.autoFocus ?? false,
        focusNode: _focusNode,
        keyboardType: widget.type,
        obscureText: widget.obscureText ?? false,
        autocorrect: widget.autoCorrect ?? false,
        enableSuggestions: widget.enableSuggestions ?? false,
        style: widget.style ?? Theme.of(context).textTheme.bodyMedium,
        cursorColor: Theme.of(context).colorScheme.primary,
        controller: _controller,
        showCursor: true,
        enabled: widget.enabled,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        textCapitalization: widget.capitalization ?? TextCapitalization.none,
        textAlign: widget.textAlign,
        decoration: widget.inputDecoration ??
            InputDecoration(
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              counterText: "",
              suffixText: widget.showCounter ? _suffixText() : "",
              contentPadding: widget.contentPadding ?? EdgeInsets.all(Insets.m),
              border: widget.inputBorder ??
                  const OutlineInputBorder(borderSide: BorderSide.none),
              isDense: widget.isDense,
              icon: widget.icon == null ? null : Icon(widget.icon),
              errorText: widget.errorText,
              errorMaxLines: 2,
              hintText: widget.hintText,
              hintStyle: widget.hintStyle ??
                  Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(color: Theme.of(context).hintColor),
              labelText: widget.label,
            ),
      ),
    );
  }

  String? _suffixText() {
    if (widget.controller != null && widget.maxLength != null) {
      return ' ${widget.controller!.text.length}/${widget.maxLength}';
    }
    return null;
  }
}

class ThinUnderlineBorder extends InputBorder {
  /// Creates an underline border for an [InputDecorator].
  ///
  /// The [borderSide] parameter defaults to [BorderSide.none] (it must not be
  /// null). Applications typically do not specify a [borderSide] parameter
  /// because the input decorator substitutes its own, using [copyWith], based
  /// on the current theme and [InputDecorator.isFocused].
  ///
  /// The [borderRadius] parameter defaults to a value where the top left
  /// and right corners have a circular radius of 4.0. The [borderRadius]
  /// parameter must not be null.
  const ThinUnderlineBorder({
    super.borderSide = const BorderSide(),
    this.borderRadius = const BorderRadius.only(
      topLeft: Radius.circular(4.0),
      topRight: Radius.circular(4.0),
    ),
  });

  /// The radii of the border's rounded rectangle corners.
  ///
  /// When this border is used with a filled input decorator, see
  /// [InputDecoration.filled], the border radius defines the shape
  /// of the background fill as well as the bottom left and right
  /// edges of the underline itself.
  ///
  /// By default the top right and top left corners have a circular radius
  /// of 4.0.
  final BorderRadius borderRadius;

  @override
  bool get isOutline => false;

  @override
  UnderlineInputBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
  }) {
    return UnderlineInputBorder(
      borderSide: borderSide ?? this.borderSide,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  @override
  EdgeInsetsGeometry get dimensions =>
      EdgeInsets.only(bottom: borderSide.width);

  @override
  UnderlineInputBorder scale(double t) =>
      UnderlineInputBorder(borderSide: borderSide.scale(t));

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRect(Rect.fromLTWH(rect.left, rect.top, rect.width,
          math.max(0.0, rect.height - borderSide.width)));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRRect(borderRadius.resolve(textDirection).toRRect(rect));
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is UnderlineInputBorder) {
      final newBorderRadius =
          BorderRadius.lerp(a.borderRadius, borderRadius, t);

      if (newBorderRadius != null) {
        return UnderlineInputBorder(
          borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
          borderRadius: newBorderRadius,
        );
      }
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is UnderlineInputBorder) {
      final newBorderRadius =
          BorderRadius.lerp(b.borderRadius, borderRadius, t);
      if (newBorderRadius != null) {
        return UnderlineInputBorder(
          borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
          borderRadius: newBorderRadius,
        );
      }
    }
    return super.lerpTo(b, t);
  }

  /// Draw a horizontal line at the bottom of [rect].
  ///
  /// The [borderSide] defines the line's color and weight. The `textDirection`
  /// `gap` and `textDirection` parameters are ignored.
  /// @override

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    if (borderRadius.bottomLeft != Radius.zero ||
        borderRadius.bottomRight != Radius.zero) {
      canvas.clipPath(getOuterPath(rect, textDirection: textDirection));
    }
    canvas.drawLine(rect.bottomLeft, rect.bottomRight, borderSide.toPaint());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is InputBorder && other.borderSide == borderSide;
  }

  @override
  int get hashCode => borderSide.hashCode;
}
