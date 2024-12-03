import 'package:flowy_infra/size.dart';
import 'package:flutter/material.dart';

class BaseStyledButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Function(bool)? onFocusChanged;
  final Function(bool)? onHighlightChanged;
  final Color? bgColor;
  final Color? focusColor;
  final Color? hoverColor;
  final Color? highlightColor;
  final EdgeInsets? contentPadding;
  final double? minWidth;
  final double? minHeight;
  final BorderRadius? borderRadius;
  final bool useBtnText;
  final bool autoFocus;

  final ShapeBorder? shape;

  final Color outlineColor;

  const BaseStyledButton({
    super.key,
    required this.child,
    this.onPressed,
    this.onFocusChanged,
    this.onHighlightChanged,
    this.bgColor,
    this.focusColor,
    this.contentPadding,
    this.minWidth,
    this.minHeight,
    this.borderRadius,
    this.hoverColor,
    this.highlightColor,
    this.shape,
    this.useBtnText = true,
    this.autoFocus = false,
    this.outlineColor = Colors.transparent,
  });

  @override
  State<BaseStyledButton> createState() => BaseStyledBtnState();
}

class BaseStyledBtnState extends State<BaseStyledButton> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: '', canRequestFocus: true);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus != _isFocused) {
      setState(() => _isFocused = _focusNode.hasFocus);
      widget.onFocusChanged?.call(_isFocused);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.bgColor ?? Theme.of(context).colorScheme.surface,
        borderRadius: widget.borderRadius ?? Corners.s10Border,
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow,
                  offset: Offset.zero,
                  blurRadius: 8.0,
                  spreadRadius: 0.0,
                ),
                BoxShadow(
                  color:
                      widget.bgColor ?? Theme.of(context).colorScheme.surface,
                  offset: Offset.zero,
                  blurRadius: 8.0,
                  spreadRadius: -4.0,
                ),
              ]
            : [],
      ),
      foregroundDecoration: _isFocused
          ? ShapeDecoration(
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1.8,
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: widget.borderRadius ?? Corners.s10Border,
              ),
            )
          : null,
      child: RawMaterialButton(
        focusNode: _focusNode,
        autofocus: widget.autoFocus,
        textStyle:
            widget.useBtnText ? Theme.of(context).textTheme.bodyMedium : null,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        // visualDensity: VisualDensity.compact,
        splashColor: Colors.transparent,
        mouseCursor: SystemMouseCursors.click,
        elevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        focusElevation: 0,
        fillColor: Colors.transparent,
        hoverColor: widget.hoverColor ?? Colors.transparent,
        highlightColor: widget.highlightColor ?? Colors.transparent,
        focusColor: widget.focusColor ?? Colors.grey.withOpacity(0.35),
        constraints: BoxConstraints(
            minHeight: widget.minHeight ?? 0, minWidth: widget.minWidth ?? 0),
        onPressed: widget.onPressed,
        shape: widget.shape ??
            RoundedRectangleBorder(
              side: BorderSide(color: widget.outlineColor, width: 1.5),
              borderRadius: widget.borderRadius ?? Corners.s10Border,
            ),
        child: Opacity(
          opacity: widget.onPressed != null ? 1 : .7,
          child: Padding(
            padding: widget.contentPadding ?? EdgeInsets.all(Insets.m),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
