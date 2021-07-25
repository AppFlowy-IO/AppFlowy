import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flowy_infra_ui/widget/text_field_container.dart';
import 'package:flutter/material.dart';
import 'package:flowy_infra/time/duration.dart';

// ignore: must_be_immutable
class RoundedInputField extends StatefulWidget {
  final String? hintText;
  final IconData? icon;
  final bool obscureText;
  final Color normalBorderColor;
  final Color highlightBorderColor;
  final String errorText;
  final ValueChanged<String>? onChanged;
  late bool enableObscure;

  RoundedInputField({
    Key? key,
    this.hintText,
    this.icon,
    this.obscureText = false,
    this.onChanged,
    this.normalBorderColor = Colors.transparent,
    this.highlightBorderColor = Colors.transparent,
    this.errorText = "",
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
        borderRadius: BorderRadius.circular(10),
        borderColor: borderColor,
        child: TextFormField(
          onChanged: widget.onChanged,
          cursorColor: const Color(0xFF6F35A5),
          obscureText: widget.enableObscure,
          decoration: InputDecoration(
            icon: newIcon,
            hintText: widget.hintText,
            border: InputBorder.none,
            suffixIcon: suffixIcon(),
          ),
        ),
      ),
    ];

    if (widget.errorText.isNotEmpty) {
      children.add(Text(
        widget.errorText,
        style: TextStyle(color: widget.highlightBorderColor),
      ));
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
    return RoundedImageButton(
      size: 20,
      press: () {
        widget.enableObscure = !widget.enableObscure;
        setState(() {});
      },
      child: const Icon(Icons.password, size: 15),
    );
  }
}
