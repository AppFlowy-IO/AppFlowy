import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/time/duration.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';

class RoundedInputField extends StatefulWidget {
  final String? hintText;
  final bool obscureText;
  final Widget? obscureIcon;
  final Widget? obscureHideIcon;
  final Color? normalBorderColor;
  final Color? errorBorderColor;
  final Color? cursorColor;
  final Color? focusBorderColor;
  final String errorText;
  final TextStyle? style;
  final ValueChanged<String>? onChanged;
  final Function(String)? onEditingComplete;
  final String? initialValue;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final EdgeInsets contentPadding;
  final double height;
  final FocusNode? focusNode;
  final TextEditingController? controller;
  final bool autoFocus;
  final int? maxLength;
  final Function(String)? onFieldSubmitted;

  const RoundedInputField({
    super.key,
    this.hintText,
    this.errorText = "",
    this.initialValue,
    this.obscureText = false,
    this.obscureIcon,
    this.obscureHideIcon,
    this.onChanged,
    this.onEditingComplete,
    this.normalBorderColor,
    this.errorBorderColor,
    this.focusBorderColor,
    this.cursorColor,
    this.style,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 10),
    this.height = 48,
    this.focusNode,
    this.controller,
    this.autoFocus = false,
    this.maxLength,
    this.onFieldSubmitted,
  });

  @override
  State<RoundedInputField> createState() => _RoundedInputFieldState();
}

class _RoundedInputFieldState extends State<RoundedInputField> {
  String inputText = "";
  bool obscureText = false;

  @override
  void initState() {
    super.initState();
    obscureText = widget.obscureText;
    inputText = widget.controller != null
        ? widget.controller!.text
        : widget.initialValue ?? "";
  }

  String? _suffixText() => widget.maxLength != null
      ? ' ${widget.controller!.text.length}/${widget.maxLength}'
      : null;

  @override
  Widget build(BuildContext context) {
    Color borderColor =
        widget.normalBorderColor ?? Theme.of(context).colorScheme.outline;
    Color focusBorderColor =
        widget.focusBorderColor ?? Theme.of(context).colorScheme.primary;

    if (widget.errorText.isNotEmpty) {
      borderColor = Theme.of(context).colorScheme.error;
      focusBorderColor = borderColor;
    }

    List<Widget> children = [
      Container(
        margin: widget.margin,
        padding: widget.padding,
        height: widget.height,
        child: TextFormField(
          controller: widget.controller,
          initialValue: widget.initialValue,
          focusNode: widget.focusNode,
          autofocus: widget.autoFocus,
          maxLength: widget.maxLength,
          maxLengthEnforcement:
              MaxLengthEnforcement.truncateAfterCompositionEnds,
          onFieldSubmitted: widget.onFieldSubmitted,
          onChanged: (value) {
            inputText = value;
            if (widget.onChanged != null) {
              widget.onChanged!(value);
            }
            setState(() {});
          },
          onEditingComplete: () {
            if (widget.onEditingComplete != null) {
              widget.onEditingComplete!(inputText);
            }
          },
          cursorColor:
              widget.cursorColor ?? Theme.of(context).colorScheme.primary,
          obscureText: obscureText,
          style: widget.style ?? Theme.of(context).textTheme.bodyMedium,
          decoration: InputDecoration(
            contentPadding: widget.contentPadding,
            hintText: widget.hintText,
            hintStyle: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(color: Theme.of(context).hintColor),
            suffixText: _suffixText(),
            counterText: "",
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: borderColor, width: 1.0),
              borderRadius: Corners.s10Border,
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: focusBorderColor, width: 1.0),
              borderRadius: Corners.s10Border,
            ),
            suffixIcon: obscureIcon(),
          ),
        ),
      ),
    ];

    if (widget.errorText.isNotEmpty) {
      children.add(
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              widget.errorText,
              style: widget.style,
            ),
          ),
        ),
      );
    }

    return AnimatedSize(
      duration: .4.seconds,
      curve: Curves.easeInOut,
      child: Column(children: children),
    );
  }

  Widget? obscureIcon() {
    if (widget.obscureText == false) {
      return null;
    }

    const double iconWidth = 16;
    if (inputText.isEmpty) {
      return SizedBox.fromSize(size: const Size.square(iconWidth));
    }

    assert(widget.obscureIcon != null && widget.obscureHideIcon != null);
    final icon = obscureText ? widget.obscureIcon! : widget.obscureHideIcon!;

    return RoundedImageButton(
      size: iconWidth,
      press: () => setState(() => obscureText = !obscureText),
      child: icon,
    );
  }
}
