import 'package:flowy_style/size.dart';
import 'package:flowy_style/text_style.dart';
import 'package:flowy_style/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

class BaseStyledButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Function(bool)? onFocusChanged;
  final Function(bool)? onHighlightChanged;
  final Color? bgColor;
  final Color? focusColor;
  final Color? hoverColor;
  final Color? downColor;
  final EdgeInsets? contentPadding;
  final double? minWidth;
  final double? minHeight;
  final double? borderRadius;
  final bool useBtnText;
  final bool autoFocus;

  final ShapeBorder? shape;

  final Color outlineColor;

  const BaseStyledButton({
    Key? key,
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
    this.downColor,
    this.shape,
    this.useBtnText = true,
    this.autoFocus = false,
    this.outlineColor = Colors.transparent,
  }) : super(key: key);

  @override
  _BaseStyledBtnState createState() => _BaseStyledBtnState();
}

class _BaseStyledBtnState extends State<BaseStyledButton> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: '', canRequestFocus: true);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus != _isFocused) {
        setState(() => _isFocused = _focusNode.hasFocus);
        widget.onFocusChanged?.call(_isFocused);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return Container(
      decoration: BoxDecoration(
        color: widget.bgColor ?? theme.surface,
        borderRadius: BorderRadius.circular(widget.borderRadius ?? Corners.s5),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                    color: theme.focus.withOpacity(0.25),
                    offset: Offset.zero,
                    blurRadius: 8.0,
                    spreadRadius: 0.0),
                BoxShadow(
                    color: widget.bgColor ?? theme.surface,
                    offset: Offset.zero,
                    blurRadius: 8.0,
                    spreadRadius: -4.0),
              ]
            : [],
      ),
      foregroundDecoration: _isFocused
          ? ShapeDecoration(
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1.8,
                  color: theme.focus,
                ),
                borderRadius:
                    BorderRadius.circular(widget.borderRadius ?? Corners.s5),
              ),
            )
          : null,
      child: RawMaterialButton(
        focusNode: _focusNode,
        autofocus: widget.autoFocus,
        textStyle: widget.useBtnText ? TextStyles.Btn : null,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        splashColor: Colors.transparent,
        mouseCursor: SystemMouseCursors.click,
        elevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        focusElevation: 0,
        fillColor: Colors.transparent,
        hoverColor: widget.hoverColor ?? theme.surface,
        highlightColor: widget.downColor ?? theme.accent1.withOpacity(.1),
        focusColor: widget.focusColor ?? Colors.grey.withOpacity(0.35),
        child: Opacity(
          child: Padding(
            padding: widget.contentPadding ?? EdgeInsets.all(Insets.m),
            child: widget.child,
          ),
          opacity: widget.onPressed != null ? 1 : .7,
        ),
        constraints: BoxConstraints(
            minHeight: widget.minHeight ?? 0, minWidth: widget.minWidth ?? 0),
        onPressed: widget.onPressed,
        shape: widget.shape ??
            RoundedRectangleBorder(
                side: BorderSide(color: widget.outlineColor, width: 1.5),
                borderRadius:
                    BorderRadius.circular(widget.borderRadius ?? Corners.s5)),
      ),
    );
  }
}
