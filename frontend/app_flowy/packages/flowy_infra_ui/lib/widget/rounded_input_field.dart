import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flowy_infra_ui/widget/text_field_container.dart';
import 'package:flutter/material.dart';
import 'package:flowy_infra/time/duration.dart';

// ignore: must_be_immutable
class RoundedInputField extends StatefulWidget {
  final String? hintText;
  final IconData? icon;
  final bool obscureText;
  final Widget? obscureIcon;
  final Widget? obscureHideIcon;
  final Color normalBorderColor;
  final Color highlightBorderColor;
  final Color cursorColor;
  final String errorText;
  final TextStyle style;
  final ValueChanged<String>? onChanged;
  final String? initialValue;
  late bool enableObscure;
  var _text = "";

  RoundedInputField({
    Key? key,
    this.hintText,
    this.errorText = "",
    this.initialValue,
    this.icon,
    this.obscureText = false,
    this.obscureIcon,
    this.obscureHideIcon,
    this.onChanged,
    this.normalBorderColor = Colors.transparent,
    this.highlightBorderColor = Colors.transparent,
    this.cursorColor = Colors.black,
    this.style = const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
  }) : super(key: key) {
    enableObscure = obscureText;
  }

  @override
  State<RoundedInputField> createState() => _RoundedInputFieldState();
}

class _RoundedInputFieldState extends State<RoundedInputField> {
  @override
  Widget build(BuildContext context) {
    final Icon? newIcon = widget.icon == null
        ? null
        : Icon(
            widget.icon!,
            color: const Color(0xFF6F35A5),
          );

    var borderColor = widget.normalBorderColor;
    if (widget.errorText.isNotEmpty) {
      borderColor = widget.highlightBorderColor;
    }

    List<Widget> children = [
      TextFieldContainer(
        height: 48,
        borderRadius: Corners.s10Border,
        borderColor: borderColor,
        child: TextFormField(
          initialValue: widget.initialValue,
          onChanged: (value) {
            widget._text = value;
            if (widget.onChanged != null) {
              widget.onChanged!(value);
            }
            setState(() {});
          },
          cursorColor: widget.cursorColor,
          obscureText: widget.enableObscure,
          decoration: InputDecoration(
            icon: newIcon,
            hintText: widget.hintText,
            hintStyle: TextStyle(color: widget.normalBorderColor),
            border: InputBorder.none,
            suffixIcon: suffixIcon(),
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
      child: Column(
        children: children,
      ),
    );
  }

  Widget? suffixIcon() {
    if (widget.obscureText == false) {
      return null;
    }

    if (widget._text.isEmpty) {
      return SizedBox.fromSize(size: const Size.square(16));
    }

    Widget? icon;
    if (widget.obscureText == true) {
      assert(widget.obscureIcon != null && widget.obscureHideIcon != null);
      if (widget.enableObscure) {
        icon = widget.obscureIcon!;
      } else {
        icon = widget.obscureHideIcon!;
      }
    }

    if (icon == null) {
      return null;
    }

    return RoundedImageButton(
      size: 16,
      press: () {
        widget.enableObscure = !widget.enableObscure;
        setState(() {});
      },
      child: icon,
    );
  }
}
