import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flutter/material.dart';
import 'package:flowy_infra/time/duration.dart';

class RoundedInputField extends StatefulWidget {
  final String? hintText;
  final bool obscureText;
  final Widget? obscureIcon;
  final Widget? obscureHideIcon;
  final Color normalBorderColor;
  final Color errorBorderColor;
  final Color cursorColor;
  final Color? focusBorderColor;
  final String errorText;
  final TextStyle style;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final String? initialValue;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final EdgeInsets contentPadding;
  final double height;
  final FocusNode? focusNode;
  final TextEditingController? controller;
  final bool autoFocus;

  const RoundedInputField({
    Key? key,
    this.hintText,
    this.errorText = "",
    this.initialValue,
    this.obscureText = false,
    this.obscureIcon,
    this.obscureHideIcon,
    this.onChanged,
    this.onEditingComplete,
    this.normalBorderColor = Colors.transparent,
    this.errorBorderColor = Colors.transparent,
    this.focusBorderColor,
    this.cursorColor = Colors.black,
    this.style = const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 10),
    this.height = 48,
    this.focusNode,
    this.controller,
    this.autoFocus = false,
  }) : super(key: key);

  @override
  State<RoundedInputField> createState() => _RoundedInputFieldState();
}

class _RoundedInputFieldState extends State<RoundedInputField> {
  String inputText = "";
  bool obscuteText = false;

  @override
  void initState() {
    obscuteText = widget.obscureText;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var borderColor = widget.normalBorderColor;
    var focusBorderColor = widget.focusBorderColor ?? borderColor;

    if (widget.errorText.isNotEmpty) {
      borderColor = widget.errorBorderColor;
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
          onChanged: (value) {
            inputText = value;
            if (widget.onChanged != null) {
              widget.onChanged!(value);
            }
            setState(() {});
          },
          onEditingComplete: widget.onEditingComplete,
          cursorColor: widget.cursorColor,
          obscureText: obscuteText,
          style: widget.style,
          decoration: InputDecoration(
            contentPadding: widget.contentPadding,
            hintText: widget.hintText,
            hintStyle: TextStyle(color: widget.normalBorderColor),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: borderColor,
                width: 1.0,
              ),
              borderRadius: Corners.s10Border,
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: focusBorderColor,
                width: 1.0,
              ),
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
          child: Text(
            widget.errorText,
            style: widget.style,
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
    Widget? icon;
    if (obscuteText) {
      icon = widget.obscureIcon!;
    } else {
      icon = widget.obscureHideIcon!;
    }

    return RoundedImageButton(
      size: iconWidth,
      press: () {
        obscuteText = !obscuteText;
        setState(() {});
      },
      child: icon,
    );
  }
}
