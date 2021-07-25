import 'package:flowy_infra_ui/widget/text_field_container.dart';
import 'package:flutter/material.dart';
import 'package:flowy_infra/time/duration.dart';

class RoundedInputField extends StatelessWidget {
  final String? hintText;
  final IconData? icon;
  final bool obscureText;
  final Color normalBorderColor;
  final Color highlightBorderColor;
  final String errorText;
  final ValueChanged<String>? onChanged;

  const RoundedInputField({
    Key? key,
    this.hintText,
    this.icon,
    this.obscureText = false,
    this.onChanged,
    this.normalBorderColor = Colors.transparent,
    this.highlightBorderColor = Colors.transparent,
    this.errorText = "",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Icon? newIcon = icon == null
        ? null
        : Icon(
            icon!,
            color: const Color(0xFF6F35A5),
          );

    var borderColor = normalBorderColor;
    if (errorText.isNotEmpty) {
      borderColor = highlightBorderColor;
    }

    List<Widget> children = [
      TextFieldContainer(
        borderRadius: BorderRadius.circular(10),
        borderColor: borderColor,
        child: TextFormField(
          onChanged: onChanged,
          cursorColor: const Color(0xFF6F35A5),
          obscureText: obscureText,
          decoration: InputDecoration(
            icon: newIcon,
            hintText: hintText,
            border: InputBorder.none,
          ),
        ),
      ),
    ];

    if (errorText.isNotEmpty) {
      children
          .add(Text(errorText, style: TextStyle(color: highlightBorderColor)));
    }

    return AnimatedContainer(
      duration: .3.seconds,
      child: Column(
        children: children,
      ),
    );
  }
}
